import 'dart:async';
import 'dart:math';

import 'package:flame/game.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/battle/battle_engine.dart';
import '../../domain/battle/battle_events.dart';
import '../../domain/battle/battle_models.dart';
import '../../domain/battle/combat_config.dart';
import '../../domain/characters/player_character.dart';
import '../../domain/content/region_definition.dart';
import '../../domain/language/challenge_factory.dart';
import '../../domain/progression/player_level.dart';
import '../../domain/progression/word_mastery.dart';
import '../../domain/sandbox/sandbox_progression.dart';
import '../../game/vfx/vfx.dart';
import '../../game/word_forge_battle_game.dart';
import '../cubit/battle_controller.dart';
import '../cubit/word_forge_cubit.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import '../widgets/battle_hud.dart';
import '../widgets/challenge_panels.dart';
import '../widgets/spell_chooser.dart';
import '../widgets/wf_components.dart';
import '../widgets/wf_glyph.dart';
import '../word_forge_scope.dart';
import 'battle_results_view.dart';

/// A full battle: Flame scene on top, readable Flutter HUD and challenge
/// panel below (side by side in landscape). Pops with the
/// [BattleOutcomeSummary] of the last finished attempt.
class BattlePage extends StatefulWidget {
  final MapNodeDefinition node;
  final RegionDefinition region;

  /// Injected for tests; production battles use a time-based seed.
  final int? seed;

  /// Disables the Flame scene (widget tests).
  final bool renderScene;

  /// Debug QA arena: fight this setup instead of the node's, and never save
  /// the outcome.
  final BattleSetup? practiceSetup;

  const BattlePage({
    super.key,
    required this.node,
    required this.region,
    this.seed,
    this.renderScene = true,
    this.practiceSetup,
  });

  bool get practice => practiceSetup != null;

  @override
  State<BattlePage> createState() => _BattlePageState();
}

class _BattlePageState extends State<BattlePage> with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final Ticker _ticker = createTicker(_onTick);
  Duration _lastTick = Duration.zero;
  BattleController? _controller;
  WordForgeBattleGame? _game;
  StreamSubscription<BattleEvent>? _endSubscription;
  BattleOutcomeSummary? _summary;
  BattleOutcomeSummary? _lastSummary;
  bool _paused = false;
  bool _savingResult = false;
  int _attempt = 0;
  late final WordForgeCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<WordForgeCubit>();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _startBattle();
      _ticker.start();
    });
  }

  void _startBattle() {
    final state = _cubit.state;
    final content = state.content!;
    final save = state.save!;
    final setup = widget.practiceSetup ?? _cubit.setupFor(widget.node);
    if (setup == null) {
      Navigator.of(context).maybePop();
      return;
    }
    final scope = WordForgeScope.of(context);
    final seed = widget.seed ?? DateTime.now().microsecondsSinceEpoch + _attempt;
    final engine = BattleEngine(
      setup: setup,
      factory: ChallengeFactory(
        onInvalid: kDebugMode ? (challenge, issues) => debugPrint('[WordForge] rejected challenge: $issues') : null,
      ),
      generation: GenerationContext(content: content, stats: SaveStatsLookup(save), random: Random(seed)),
    );
    final controller = BattleController(
      engine: engine,
      content: content,
      audio: scope.audio,
      analytics: scope.dependencies.analytics,
      analyticsContext: {'node_id': widget.node.id, 'region_id': widget.region.id, 'node_type': widget.node.type.name},
      knownWordIds: {for (final entry in save.words.entries) if (entry.value.seen > 0) entry.key},
      describe: _describe,
    );
    const mastery = MasteryCalculator();
    final level = PlayerLevel.fromXp(save.xp).level;
    final game = widget.renderScene
        ? WordForgeBattleGame(
            events: controller.events,
            snapshots: engine.snapshots,
            enemies: setup.enemies,
            elements: [for (var i = 0; i < setup.enemies.length; i++) ElementStyle.parse(setup.behaviourOf(i).element)],
            character: PlayerCharacterDefinition.byId(save.characterId),
            characterTier: PlayerCharacterDefinition.tierForLevel(level),
            theme: widget.region.theme,
            vfx: save.settings.reducedEffects ? VfxConfig.reduced : VfxConfig.full,
            masteryOf: (wordId) => wordId == null ? 0 : mastery.level(save.words[wordId]),
            onEnemyTapped: controller.selectTarget,
          )
        : null;
    _endSubscription = controller.events.where((event) => event is BattleEnded).listen((event) {
      _onBattleEnded((event as BattleEnded).result);
    });
    setState(() {
      _controller = controller;
      _game = game;
      _summary = null;
      _paused = false;
    });
    controller.start();
  }

  String _describe(String key) => switch (key) {
        'newWord' => WfStrings.newWord,
        'secondChance' => WfStrings.secondChanceSaved,
        'unstable' => WfStrings.unstable,
        'wordEaten' => WfStrings.wordEaten,
        'timeUp' => WfStrings.timeUp,
        'ward' => WfStrings.wardBlocked,
        'flow' => WfStrings.wordFlow,
        'locked' => WfStrings.lockedTurn,
        'staggered' => WfStrings.staggered,
        'specialReady' => WfStrings.specialReady,
        'parried' => WfStrings.parried,
        'weakCast' => WfStrings.weakCast,
        'weakCastCounter' => WfStrings.weakCastCounter,
        'bound' => WfStrings.bound,
        'wardRaised' => WfStrings.wardRaised,
        'fizzled' => WfStrings.fizzled,
        'enemyPoisoned' => WfStrings.enemyPoisoned,
        'poisoned' => WfStrings.youArePoisoned,
        'reflected' => WfStrings.reflected,
        _ => key,
      };

  /// Opens the spell panel with the battle paused, so deciding never costs
  /// attack time. Every known spell is shown with its cost and state.
  Future<void> _castSpecial() async {
    final controller = _controller;
    if (controller == null) return;
    final snapshot = controller.state;
    if (!snapshot.acceptsInput || !snapshot.isPlayerTurn || snapshot.moveKind != MoveKind.normal) return;
    final config = controller.engine.config;
    final spells = [for (final id in snapshot.knownSpells) if (config.move(id) case final move?) move];
    if (spells.isEmpty) return;
    controller.pause();
    _game?.pauseEngine();
    final chosen = await showSpellChooser(
      context,
      spells: spells,
      states: {for (final state in snapshot.spells) state.id: state},
      mana: snapshot.mana,
      manaMax: snapshot.manaMax,
    );
    if (!mounted) return;
    controller.resume();
    _game?.resumeEngine();
    if (chosen != null) controller.activateSpecial(chosen);
  }

  void _onTick(Duration elapsed) {
    final dt = (elapsed - _lastTick).inMicroseconds / 1e6;
    _lastTick = elapsed;
    if (!_paused) _controller?.tick(dt);
  }

  Future<void> _onBattleEnded(BattleResult result) async {
    if (result.abandoned || _savingResult) return;
    _savingResult = true;
    // Let the final animation breathe before the results appear.
    await Future<void>.delayed(Duration(milliseconds: result.victory ? 1600 : 1300));
    final summary = widget.practice ? _cubit.previewBattle(widget.node, result) : await _cubit.completeBattle(widget.node, result);
    _savingResult = false;
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _lastSummary = summary ?? _lastSummary;
    });
  }

  Future<void> _retry() async {
    await _disposeBattle();
    _attempt++;
    if (mounted) _startBattle();
  }

  Future<void> _disposeBattle() async {
    await _endSubscription?.cancel();
    _endSubscription = null;
    final controller = _controller;
    _controller = null;
    _game = null;
    await controller?.close();
  }

  void _pause() {
    if (_controller == null || _summary != null || (_controller?.engine.isOver ?? true)) return;
    _controller!.pause();
    _game?.pauseEngine();
    setState(() => _paused = true);
  }

  void _resume() {
    _controller?.resume();
    _game?.resumeEngine();
    setState(() => _paused = false);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) {
      // Timers never run while the app is in the background; the player
      // returns to a pause screen instead of an expired Critical.
      _pause();
    }
  }

  Future<void> _requestExit() async {
    final controller = _controller;
    if (_summary != null || controller == null || controller.engine.isOver) {
      Navigator.of(context).pop(_lastSummary);
      return;
    }
    _pause();
    final leave = await showWfConfirm(
      context,
      title: WfStrings.retreat,
      message: WfStrings.retreatQuestion,
      confirmLabel: WfStrings.retreat,
      cancelLabel: WfStrings.stay,
      glyph: WfGlyphType.back,
    );
    if (!mounted) return;
    if (!leave) {
      _resume();
      return;
    }
    final result = controller.abandon();
    if (!widget.practice) await _cubit.completeBattle(widget.node, result);
    if (mounted) Navigator.of(context).pop(_lastSummary);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    final controller = _controller;
    if (controller != null && !controller.engine.isOver && controller.engine.records.isNotEmpty && !widget.practice) {
      // Route removed mid-battle: keep the practised words.
      _cubit.completeBattle(widget.node, controller.abandon());
    }
    _endSubscription?.cancel();
    controller?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _requestExit();
      },
      child: Scaffold(
        backgroundColor: WfColors.night,
        body: controller == null
            ? const Center(child: CircularProgressIndicator(color: WfColors.brand))
            : BlocProvider.value(
                value: controller,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: _BattleLayout(controller: controller, game: _game, onPause: _pause, onSpecial: _castSpecial),
                    ),
                    Positioned.fill(child: _MomentOverlay(controller: controller, node: widget.node)),
                    if (_paused) Positioned.fill(child: _PauseOverlay(onResume: _resume, onRetreat: _requestExit)),
                    if (_summary != null)
                      Positioned.fill(
                        child: BattleResultsView(
                          summary: _summary!,
                          content: _cubit.state.content!,
                          onContinue: () => Navigator.of(context).pop(_lastSummary),
                          onRetry: _retry,
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }
}

class _BattleLayout extends StatelessWidget {
  final BattleController controller;
  final WordForgeBattleGame? game;
  final VoidCallback onPause;
  final VoidCallback onSpecial;

  const _BattleLayout({required this.controller, required this.game, required this.onPause, required this.onSpecial});

  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, constraints) {
        final landscape = constraints.maxWidth > constraints.maxHeight && constraints.maxWidth >= 640;
        final scene = _Scene(controller: controller, game: game, onPause: onPause);
        final panel = _ChallengeArea(controller: controller, onSpecial: onSpecial);
        if (landscape) {
          return Row(
            children: [
              Expanded(child: scene),
              SizedBox(width: min(460, constraints.maxWidth * 0.46), child: panel),
            ],
          );
        }
        final height = constraints.maxHeight;
        return Column(
          children: [
            Expanded(child: scene),
            ConstrainedBox(
              constraints: BoxConstraints(minHeight: height * 0.38, maxHeight: height * 0.57),
              child: panel,
            ),
          ],
        );
      });
}

class _Scene extends StatelessWidget {
  final BattleController controller;
  final WordForgeBattleGame? game;
  final VoidCallback onPause;

  const _Scene({required this.controller, required this.game, required this.onPause});

  @override
  Widget build(BuildContext context) => ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (game != null) GameWidget(key: ObjectKey(game), game: game!) else const ColoredBox(color: WfColors.deep),
            BlocBuilder<BattleController, BattleSnapshot>(
              builder: (context, snapshot) => Stack(
                fit: StackFit.expand,
                children: [
                  if (snapshot.wordFlow) const IgnorePointer(child: _FlowFrame()),
                  if (!snapshot.isPlayerTurn && snapshot.moveKind == MoveKind.critical &&
                      (snapshot.phase == BattlePhase.turnStart || snapshot.phase == BattlePhase.awaitingInput))
                    const IgnorePointer(child: _WarningVignette()),
                  SafeArea(
                    bottom: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 6, 12, 0),
                      child: Column(
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              WfRoundButton(glyph: WfGlyphType.pause, size: 40, semanticsLabel: WfStrings.paused, onTap: onPause),
                              const SizedBox(width: 10),
                              Expanded(
                                child: HpBar(
                                  name: WfStrings.you,
                                  hp: snapshot.playerHp,
                                  maxHp: snapshot.playerMaxHp,
                                  color: WfColors.life,
                                  badge: Row(mainAxisSize: MainAxisSize.min, children: [
                                    if (snapshot.wardArmed) ...[
                                      const WfGlyph(WfGlyphType.ward, size: 14, color: Color(0xFFFFB86B)),
                                      if (snapshot.wardCharges > 1)
                                        Text('×${snapshot.wardCharges}',
                                            style: WfText.label(10, color: const Color(0xFFFFB86B))),
                                    ],
                                    if (snapshot.playerLocked) const WfGlyph(WfGlyphType.lock, size: 14, color: WfColors.danger),
                                    if (snapshot.playerPoisoned) ...[
                                      const SizedBox(width: 4),
                                      PoisonPips(ticks: snapshot.playerPoisonTicks),
                                    ],
                                  ]),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(child: EnemyBars(snapshot: snapshot, onTarget: controller.selectTarget)),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              TurnIndicator(snapshot: snapshot),
                              const Spacer(),
                              if (snapshot.stageCount > 1) ...[
                                if (snapshot.enraged) ...[WfTag(WfStrings.enraged, color: WfColors.danger), const SizedBox(width: 8)],
                                StagePips(index: snapshot.stageIndex, count: snapshot.stageCount, enraged: snapshot.enraged),
                              ],
                            ],
                          ),
                          const SizedBox(height: 6),
                          NoticeBanner(notice: controller.notice),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 14,
                    child: Center(
                      child: snapshot.acceptsInput || snapshot.phase == BattlePhase.resolving
                          ? PromptPlate(snapshot: snapshot)
                          : const SizedBox.shrink(),
                    ),
                  ),
                  Positioned(left: 12, bottom: 112, child: ComboBadge(combo: snapshot.combo, flow: snapshot.wordFlow)),
                  if (snapshot.hasTimer && snapshot.acceptsInput)
                    Positioned(
                      right: 12,
                      bottom: 108,
                      child: TimerRing(fraction: controller.timerFraction, frozen: snapshot.timerFrozen),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _FlowFrame extends StatefulWidget {
  const _FlowFrame();

  @override
  State<_FlowFrame> createState() => _FlowFrameState();
}

class _FlowFrameState extends State<_FlowFrame> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(color: WfColors.gold.withValues(alpha: 0.35 + _controller.value * 0.35), width: 3),
            gradient: RadialGradient(
              radius: 1.1,
              colors: [Colors.transparent, WfColors.gold.withValues(alpha: 0.08 + _controller.value * 0.08)],
            ),
          ),
        ),
      );
}

/// Red pulsing edge while an enemy Critical is being cast or answered.
class _WarningVignette extends StatefulWidget {
  const _WarningVignette();

  @override
  State<_WarningVignette> createState() => _WarningVignetteState();
}

class _WarningVignetteState extends State<_WarningVignette> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 520))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              radius: 0.95,
              colors: [Colors.transparent, WfColors.danger.withValues(alpha: 0.18 + _controller.value * 0.22)],
              stops: const [0.55, 1],
            ),
          ),
        ),
      );
}

class _ChallengeArea extends StatelessWidget {
  final BattleController controller;
  final VoidCallback onSpecial;

  const _ChallengeArea({required this.controller, required this.onSpecial});

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WfColors.deep, WfColors.night],
          ),
          border: Border(top: BorderSide(color: WfColors.stroke)),
        ),
        child: SafeArea(
          top: false,
          child: BlocBuilder<BattleController, BattleSnapshot>(
            builder: (context, snapshot) {
              final challenge = snapshot.challenge;
              final kind = snapshot.moveKind;
              final showInstruction = challenge != null &&
                  kind != null &&
                  (snapshot.acceptsInput || snapshot.phase == BattlePhase.resolving);
              final coach = WfStrings.coach(snapshot.coachKey);
              return Column(
                mainAxisSize: MainAxisSize.min,
                // The meter/buff row stays anchored while the challenge above changes.
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                      child: Column(
                        children: [
                          if (showInstruction) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                      shape: BoxShape.circle, color: WfColors.forMove(snapshot.turn, kind)),
                                ),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    WfStrings.instruction(
                                      turn: snapshot.turn,
                                      kind: kind,
                                      type: challenge.type,
                                      shield: snapshot.targetShielded,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: WfText.title(15, color: WfColors.text),
                                  ),
                                ),
                              ],
                            ),
                            if (coach != null) ...[
                              const SizedBox(height: 4),
                              Text(coach, textAlign: TextAlign.center, style: WfText.body(12.5, color: WfColors.textDim)),
                            ],
                            const SizedBox(height: 14),
                          ],
                          ChallengePanel(snapshot: snapshot, controller: controller),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: LayoutBuilder(builder: (context, constraints) {
                      final meter = SpecialMeter(snapshot: snapshot, onActivate: onSpecial);
                      final buffs = BuffBar(snapshot: snapshot, controller: controller);
                      final buffCount = snapshot.buffs.values.where((count) => count > 0).length;
                      final needed = (snapshot.specialUnlocked ? 176 : 0) + buffCount * BuffBar.slotWidth;
                      // Keep everything visible: buffs move under the meter when one row is too narrow.
                      if (needed > constraints.maxWidth) {
                        return Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Align(alignment: Alignment.centerLeft, child: meter),
                            const SizedBox(height: 8),
                            Align(alignment: Alignment.centerRight, child: buffs),
                          ],
                        );
                      }
                      return Row(
                        children: [
                          meter,
                          const SizedBox(width: 8),
                          Expanded(child: Align(alignment: Alignment.centerRight, child: buffs)),
                        ],
                      );
                    }),
                  ),
                ],
              );
            },
          ),
        ),
      );
}

/// Banners for the big moments: intro, enemy Critical / Special telegraphs,
/// Critical Opportunity, Special activation and boss phase changes.
class _MomentOverlay extends StatelessWidget {
  final BattleController controller;
  final MapNodeDefinition node;

  const _MomentOverlay({required this.controller, required this.node});

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: BlocBuilder<BattleController, BattleSnapshot>(
          buildWhen: (previous, current) =>
              previous.phase != current.phase ||
              previous.stageIndex != current.stageIndex ||
              previous.moveKind != current.moveKind ||
              previous.turn != current.turn,
          builder: (context, snapshot) {
            final setup = controller.engine.setup;
            final enemy = setup.enemy;
            Widget? banner;
            switch (snapshot.phase) {
              case BattlePhase.intro:
                banner = _Banner(
                  eyebrow: enemy.title ?? WfStrings.nodeType(node.type),
                  title: setup.enemies.map((e) => e.name).join(' & '),
                  subtitle: '${WfStrings.vocabularyLevel}: ${WfStrings.cefrFor(setup.degrees)}',
                  color: enemy.isBoss ? WfColors.danger : WfColors.gold,
                  large: enemy.isBoss,
                );
              case BattlePhase.turnStart:
                final kind = snapshot.moveKind;
                if (kind == null || kind == MoveKind.normal) break;
                final player = snapshot.isPlayerTurn;
                banner = _Banner(
                  eyebrow: player
                      ? WfStrings.yourTurn
                      : (snapshot.actor >= 0 ? snapshot.enemies[snapshot.actor].name : WfStrings.enemyTurn),
                  title: switch ((player, kind)) {
                    (true, MoveKind.critical) => WfStrings.criticalOpportunity,
                    (false, MoveKind.critical) => WfStrings.criticalAttack,
                    _ => WfStrings.moveLabel(snapshot.moveLabel ?? WfStrings.special),
                  },
                  subtitle: !player && kind == MoveKind.special ? WfStrings.enemySpecial : null,
                  color: WfColors.forMove(snapshot.turn, kind),
                  large: true,
                );
              case BattlePhase.stageTransition:
                banner = _Banner(
                  eyebrow: '${WfStrings.phase} ${snapshot.stageIndex + 1}',
                  title: snapshot.stageName ?? enemy.name,
                  color: snapshot.enraged ? WfColors.danger : WfColors.gold,
                  large: true,
                );
              default:
                banner = null;
            }
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: banner == null
                  ? const SizedBox.expand(key: ValueKey('none'))
                  : Align(
                      key: ValueKey('${snapshot.phase}-${snapshot.stageIndex}-${snapshot.moveKind}-${snapshot.turn}'),
                      alignment: const Alignment(0, -0.32),
                      child: banner,
                    ),
            );
          },
        ),
      );
}

class _Banner extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final Color color;
  final bool large;

  const _Banner({required this.eyebrow, required this.title, this.subtitle, required this.color, this.large = false});

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutBack,
        builder: (context, value, child) =>
            Transform.scale(scale: 0.8 + value * 0.2, child: Opacity(opacity: value.clamp(0, 1), child: child)),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.78),
              Colors.black.withValues(alpha: 0.78),
              Colors.transparent,
            ], stops: const [0, 0.2, 0.8, 1]),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(eyebrow.toUpperCase(), style: WfText.label(12, color: color, spacing: 3)),
              const SizedBox(height: 4),
              Text(title,
                  textAlign: TextAlign.center,
                  style: WfText.display(large ? 28 : 24, spacing: 1.5)
                      .copyWith(shadows: WfFx.textGlow(color.withValues(alpha: 0.85), 20))),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(subtitle!, style: WfText.body(13, color: WfColors.textDim)),
              ],
            ],
          ),
        ),
      );
}

class _PauseOverlay extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onRetreat;

  const _PauseOverlay({required this.onResume, required this.onRetreat});

  @override
  Widget build(BuildContext context) => ColoredBox(
        color: Colors.black.withValues(alpha: 0.72),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const WfGlyph(WfGlyphType.pause, size: 40, color: WfColors.gold),
                    const SizedBox(height: 14),
                    Text(WfStrings.paused, style: WfText.display(26, spacing: 2)),
                    const SizedBox(height: 26),
                    WfButton(label: WfStrings.resume, glyph: WfGlyphType.forward, onTap: onResume),
                    const SizedBox(height: 12),
                    WfButton(label: WfStrings.retreat, style: WfButtonStyle.secondary, onTap: onRetreat),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
}
