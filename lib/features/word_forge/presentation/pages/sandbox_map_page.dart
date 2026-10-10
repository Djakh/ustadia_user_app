import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/content/region_definition.dart';
import '../../domain/content/word_forge_content.dart';
import '../../domain/progression/buffs.dart';
import '../../domain/progression/map_rules.dart';
import '../../domain/sandbox/sandbox_progression.dart';
import '../../domain/save/word_forge_save.dart';
import '../../domain/services/word_forge_audio.dart';
import '../art/map_painters.dart';
import '../cubit/word_forge_cubit.dart';
import '../l10n/wf_strings.dart';
import '../theme/wf_theme.dart';
import '../widgets/buff_chips.dart';
import '../widgets/wf_components.dart';
import '../widgets/wf_glyph.dart';
import '../word_forge_scope.dart';
import 'battle_page.dart';

class SandboxMapPage extends StatefulWidget {
  const SandboxMapPage({super.key});

  @override
  State<SandboxMapPage> createState() => _SandboxMapPageState();
}

class _SandboxMapPageState extends State<SandboxMapPage> {
  late String _regionId;
  Set<String> _highlighted = const {};
  final Map<String, ScrollController> _scrollControllers = {};

  WordForgeCubit get _cubit => context.read<WordForgeCubit>();

  @override
  void initState() {
    super.initState();
    final state = _cubit.state;
    _regionId = _cubit.mapRules.currentRegion(state.content!, state.save!).id;
  }

  @override
  void dispose() {
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _switchRegion(WordForgeContent content, int delta) {
    final regions = content.regions;
    final index = regions.indexWhere((region) => region.id == _regionId);
    final next = (index + delta).clamp(0, regions.length - 1);
    if (next == index) return;
    WordForgeScope.of(context).audio.play(WordForgeSfx.tap);
    setState(() {
      _regionId = regions[next].id;
      _highlighted = const {};
    });
    if (_cubit.mapRules.isRegionUnlocked(content, _cubit.state.save!, regions[next])) {
      _cubit.selectRegion(regions[next]);
    }
  }

  Future<void> _openNode(RegionDefinition region, MapNodeDefinition node, NodeState state) async {
    WordForgeScope.of(context).audio.play(WordForgeSfx.tap);
    final action = await showWfSheet<_NodeAction>(
      context,
      builder: (_) => BlocProvider.value(
        value: _cubit,
        child: _NodeSheet(region: region, node: node, state: state),
      ),
    );
    if (!mounted || action == null) return;
    switch (action) {
      case _NodeAction.battle:
        await _startBattle(region, node);
      case _NodeAction.claim:
        await _claim(node);
      case _NodeAction.mystery:
        await _openMystery(region, node);
    }
  }

  Future<void> _startBattle(RegionDefinition region, MapNodeDefinition node) async {
    final setup = _cubit.setupFor(node);
    if (setup == null) return;
    _cubit.logNodeStarted(node);
    final summary = await WordForgeNavigator.push<BattleOutcomeSummary>(
      context,
      BattlePage(node: node, region: region),
      fade: true,
    );
    if (!mounted || summary == null) return;
    setState(() => _highlighted = summary.unlockedNodeIds.toSet());
    final unlockedRegion = summary.unlockedRegionId;
    if (unlockedRegion != null) {
      final content = _cubit.state.content!;
      final next = content.region(unlockedRegion);
      if (next != null) {
        await _showRegionUnlocked(next);
        if (mounted) setState(() => _regionId = next.id);
      }
    }
  }

  Future<void> _claim(MapNodeDefinition node) async {
    final summary = await _cubit.claimNode(node);
    if (!mounted || summary == null || summary.alreadyClaimed) return;
    WordForgeScope.of(context).audio.play(WordForgeSfx.reward);
    setState(() => _highlighted = summary.unlockedNodeIds.toSet());
    await showRewardDialog(context, title: WfStrings.treasureFound, buffs: summary.buffsGained);
  }

  Future<void> _openMystery(RegionDefinition region, MapNodeDefinition node) async {
    await _cubit.revealMystery(node);
    if (!mounted) return;
    final save = _cubit.state.save!;
    final outcome = _cubit.dependencies.progression.mysteryOutcomeFor(save, node);
    if (outcome.kind == MysteryOutcomeKind.treasure) {
      await _claim(node);
    } else {
      WordForgeScope.of(context).audio.play(WordForgeSfx.bossPhase, volume: 0.7);
      await showRewardDialog(context, title: WfStrings.ambush, buffs: const {}, glyph: WfGlyphType.mystery);
      if (mounted) await _startBattle(region, node);
    }
  }

  Future<void> _showRegionUnlocked(RegionDefinition region) => showRewardDialog(
        context,
        title: WfStrings.newRegion,
        subtitle: region.name,
        buffs: const {},
        glyph: WfGlyphType.boss,
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: WfColors.night,
        body: BlocBuilder<WordForgeCubit, WordForgeState>(
          builder: (context, state) {
            final content = state.content!;
            final save = state.save!;
            final regions = content.regions;
            final region = content.region(_regionId) ?? regions.first;
            final index = regions.indexOf(region);
            final unlocked = _cubit.mapRules.isRegionUnlocked(content, save, region);
            final controller = _scrollControllers.putIfAbsent(region.id, ScrollController.new);
            return Stack(
              children: [
                Positioned.fill(
                  child: _RegionMap(
                    key: ValueKey(region.id),
                    region: region,
                    content: content,
                    save: save,
                    highlighted: _highlighted,
                    controller: controller,
                    onNodeTap: (node, nodeState) => _openNode(region, node, nodeState),
                  ),
                ),
                if (!unlocked) Positioned.fill(child: _LockedOverlay(region: region)),
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  child: _MapHeader(
                    region: region,
                    index: index,
                    total: regions.length,
                    save: save,
                    cleared: _cubit.mapRules.isRegionCompleted(save, region),
                    onPrevious: index > 0 ? () => _switchRegion(content, -1) : null,
                    onNext: index < regions.length - 1 ? () => _switchRegion(content, 1) : null,
                  ),
                ),
              ],
            );
          },
        ),
      );
}

class _MapHeader extends StatelessWidget {
  final RegionDefinition region;
  final int index;
  final int total;
  final WordForgeSave save;
  final bool cleared;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  const _MapHeader({
    required this.region,
    required this.index,
    required this.total,
    required this.save,
    required this.cleared,
    this.onPrevious,
    this.onNext,
  });

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [WfColors.night, Color(0xF20A0D1E), Color(0x000A0D1E)],
            stops: [0, 0.78, 1],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 12, 26),
            child: Column(
              children: [
                Row(
                  children: [
                    WfRoundButton(
                      glyph: WfGlyphType.back,
                      semanticsLabel: MaterialLocalizations.of(context).backButtonTooltip,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                    const SizedBox(width: 8),
                    WfRoundButton(
                      glyph: WfGlyphType.back,
                      size: 36,
                      semanticsLabel: MaterialLocalizations.of(context).previousPageTooltip,
                      color: onPrevious == null ? WfColors.textMute.withValues(alpha: 0.3) : WfColors.gold,
                      onTap: onPrevious,
                    ),
                    Expanded(
                      child: Column(
                        children: [
                          Text('${index + 1} / $total', style: WfText.label(11, color: WfColors.gold)),
                          const SizedBox(height: 2),
                          Text(region.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: WfText.title(19)),
                          Text(cleared ? WfStrings.regionCleared : region.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: WfText.body(12, color: cleared ? WfColors.life : WfColors.textDim)),
                        ],
                      ),
                    ),
                    WfRoundButton(
                      glyph: WfGlyphType.forward,
                      size: 36,
                      semanticsLabel: MaterialLocalizations.of(context).nextPageTooltip,
                      color: onNext == null ? WfColors.textMute.withValues(alpha: 0.3) : WfColors.gold,
                      onTap: onNext,
                    ),
                    const SizedBox(width: 8),
                    const SizedBox(width: 44),
                  ],
                ),
                const SizedBox(height: 10),
                BuffInventoryStrip(buffs: save.buffs),
              ],
            ),
          ),
        ),
      );
}

class _RegionMap extends StatefulWidget {
  final RegionDefinition region;
  final WordForgeContent content;
  final WordForgeSave save;
  final Set<String> highlighted;
  final ScrollController controller;
  final void Function(MapNodeDefinition node, NodeState state) onNodeTap;

  const _RegionMap({
    super.key,
    required this.region,
    required this.content,
    required this.save,
    required this.highlighted,
    required this.controller,
    required this.onNodeTap,
  });

  @override
  State<_RegionMap> createState() => _RegionMapState();
}

class _RegionMapState extends State<_RegionMap> with SingleTickerProviderStateMixin {
  static const double rowSpacing = 116;
  static const double topPadding = 190;
  static const double bottomPadding = 120;

  late final AnimationController _shimmer =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  bool _scrolled = false;

  @override
  void dispose() {
    _shimmer.dispose();
    super.dispose();
  }

  double get _maxRow => widget.region.nodes.fold(0.0, (value, node) => math.max(value, node.row));

  Offset _position(MapNodeDefinition node, double width, double height) => Offset(
        width / 2 + node.lane * math.min(width * 0.33, 170),
        height - bottomPadding - node.row * rowSpacing,
      );

  void _scrollToFocus(double height, double viewport) {
    if (_scrolled) return;
    _scrolled = true;
    final cubit = context.read<WordForgeCubit>();
    final focus = cubit.mapRules.focusNode(widget.content, widget.save, widget.region);
    final fromBottom = bottomPadding + focus.row * rowSpacing;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!widget.controller.hasClients) return;
      final target = (fromBottom - viewport * 0.42).clamp(0.0, widget.controller.position.maxScrollExtent);
      widget.controller.jumpTo(target);
    });
  }

  @override
  Widget build(BuildContext context) {
    final rules = context.read<WordForgeCubit>().mapRules;
    final palette = RegionPalette.of(widget.region.theme);
    return LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final height = math.max(constraints.maxHeight, topPadding + bottomPadding + _maxRow * rowSpacing);
      _scrollToFocus(height, constraints.maxHeight);

      final states = {
        for (final node in widget.region.nodes)
          node.id: rules.nodeState(widget.content, widget.save, widget.region, node),
      };
      final edges = [
        for (final node in widget.region.nodes)
          for (final target in node.next)
            if (widget.region.node(target) case final targetNode?)
              MapEdge(
                from: _position(node, width, height),
                to: _position(targetNode, width, height),
                fromState: states[node.id]!,
                toState: states[target]!,
              ),
      ];

      return SingleChildScrollView(
        controller: widget.controller,
        reverse: true,
        physics: const BouncingScrollPhysics(),
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: RepaintBoundary(child: CustomPaint(painter: MapTerrainPainter(widget.region.theme))),
              ),
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: MapPathPainter(edges: edges, shimmer: _shimmer, accent: palette.accent),
                  ),
                ),
              ),
              for (final node in widget.region.nodes)
                _positionedNode(node, states[node.id]!, _position(node, width, height)),
            ],
          ),
        ),
      );
    });
  }

  Widget _positionedNode(MapNodeDefinition node, NodeState state, Offset center) {
    final size = switch (node.type) {
      MapNodeType.boss => 86.0,
      MapNodeType.miniBoss => 72.0,
      _ => 60.0,
    };
    const labelWidth = 128.0;
    return Positioned(
      left: center.dx - labelWidth / 2,
      top: center.dy - size / 2,
      width: labelWidth,
      child: MapNodeMedallion(
        node: node,
        state: state,
        size: size,
        stars: widget.save.progressOf(node.id).bestStars,
        highlighted: widget.highlighted.contains(node.id),
        onTap: () => widget.onNodeTap(node, state),
      ),
    );
  }
}

class MapNodeMedallion extends StatefulWidget {
  final MapNodeDefinition node;
  final NodeState state;
  final double size;
  final int stars;
  final bool highlighted;
  final VoidCallback onTap;

  const MapNodeMedallion({
    super.key,
    required this.node,
    required this.state,
    required this.size,
    required this.stars,
    required this.highlighted,
    required this.onTap,
  });

  @override
  State<MapNodeMedallion> createState() => _MapNodeMedallionState();
}

class _MapNodeMedallionState extends State<MapNodeMedallion> with SingleTickerProviderStateMixin {
  AnimationController? _pulse;

  @override
  void initState() {
    super.initState();
    _syncPulse();
  }

  @override
  void didUpdateWidget(MapNodeMedallion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.state != widget.state) _syncPulse();
  }

  void _syncPulse() {
    if (widget.state == NodeState.available) {
      _pulse ??= AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
    } else {
      _pulse?.dispose();
      _pulse = null;
    }
  }

  @override
  void dispose() {
    _pulse?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final node = widget.node;
    final color = WfColors.forNode(node.type);
    final locked = widget.state == NodeState.locked;
    final completed = widget.state == NodeState.completed;
    final size = widget.size;
    final medallion = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: locked
              ? const [Color(0xFF2A2D45), Color(0xFF17192B)]
              : [Color.lerp(color, Colors.white, 0.15)!, Color.lerp(color, Colors.black, 0.55)!],
          center: const Alignment(-0.3, -0.4),
        ),
        border: Border.all(
          color: completed ? WfColors.gold : (locked ? Colors.white24 : Color.lerp(color, Colors.white, 0.5)!),
          width: completed ? 3 : 2,
        ),
        boxShadow: [
          ...WfFx.shadow(const Color(0x88000000), blurRadius: 10, offset: const Offset(0, 5)),
          if (!locked) ...WfFx.shadow(color.withValues(alpha: 0.45), blurRadius: 16),
        ],
      ),
      child: WfGlyph(WfGlyphType.forNode(node.type),
          size: size * 0.46, color: locked ? Colors.white38 : Colors.white),
    );

    return WfPressable(
      onTap: widget.onTap,
      semanticsLabel: '${WfStrings.nodeType(node.type)}: ${node.title}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size + 24,
            height: size + 24,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                if (_pulse != null)
                  AnimatedBuilder(
                    animation: _pulse!,
                    builder: (context, _) {
                      final t = _pulse!.value;
                      return Container(
                        width: size + 6 + t * 18,
                        height: size + 6 + t * 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: color.withValues(alpha: (1 - t) * 0.8), width: 2.5),
                        ),
                      );
                    },
                  ),
                if (widget.highlighted)
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 1.6, end: 1),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.elasticOut,
                    builder: (context, scale, child) => Transform.scale(scale: scale, child: child),
                    child: medallion,
                  )
                else
                  medallion,
                if (locked)
                  const Positioned(
                    right: 6,
                    bottom: 6,
                    child: _Badge(color: Color(0xFF3A3D57), child: WfGlyph(WfGlyphType.lock, size: 12, color: Colors.white70)),
                  ),
                if (completed)
                  const Positioned(
                    right: 6,
                    bottom: 6,
                    child: _Badge(color: WfColors.gold, child: WfGlyph(WfGlyphType.check, size: 12, color: WfColors.night)),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              node.title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: WfText.body(11.5, color: locked ? WfColors.textMute : WfColors.text, weight: FontWeight.w500),
            ),
          ),
          if (completed && node.type.isCombat) ...[
            const SizedBox(height: 3),
            WfStarRow(stars: widget.stars, size: 12),
          ],
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final Color color;
  final Widget child;

  const _Badge({required this.color, required this.child});

  @override
  Widget build(BuildContext context) => Container(
        width: 22,
        height: 22,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          border: Border.all(color: WfColors.night, width: 2),
        ),
        child: child,
      );
}

class _LockedOverlay extends StatelessWidget {
  final RegionDefinition region;

  const _LockedOverlay({required this.region});

  @override
  Widget build(BuildContext context) => Container(
        color: Colors.black.withValues(alpha: 0.55),
        alignment: Alignment.center,
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const WfGlyph(WfGlyphType.lock, size: 46, color: WfColors.textDim),
            const SizedBox(height: 16),
            Text(region.name, textAlign: TextAlign.center, style: WfText.title(20)),
            const SizedBox(height: 8),
            Text(WfStrings.regionLocked, textAlign: TextAlign.center, style: WfText.body(14)),
          ],
        ),
      );
}

enum _NodeAction { battle, claim, mystery }

class _NodeSheet extends StatelessWidget {
  final RegionDefinition region;
  final MapNodeDefinition node;
  final NodeState state;

  const _NodeSheet({required this.region, required this.node, required this.state});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<WordForgeCubit>();
    final content = cubit.state.content!;
    final save = cubit.state.save!;
    final progress = save.progressOf(node.id);
    final color = WfColors.forNode(node.type);
    final battleId = cubit.dependencies.progression.battleIdFor(save, node);
    final isMysteryUnrevealed = node.type == MapNodeType.mystery && progress.mysteryOutcome == null;
    final battle = battleId == null || isMysteryUnrevealed ? null : content.battles[battleId];
    final enemy = battle == null ? null : content.enemies[battle.enemyId];
    final locked = state == NodeState.locked;
    final completed = state == NodeState.completed;

    final Widget action;
    if (locked) {
      action = Text(WfStrings.nodeLocked, textAlign: TextAlign.center, style: WfText.body(14));
    } else if (node.type == MapNodeType.mystery && !completed) {
      action = WfButton(
          label: WfStrings.openMystery,
          glyph: WfGlyphType.mystery,
          onTap: () => Navigator.of(context).pop(_NodeAction.mystery));
    } else if (!node.type.isCombat && node.type != MapNodeType.mystery) {
      action = completed
          ? Text(WfStrings.claimed, textAlign: TextAlign.center, style: WfText.body(14))
          : WfButton(label: WfStrings.claim, glyph: WfGlyphType.bonus, onTap: () => Navigator.of(context).pop(_NodeAction.claim));
    } else if (battle != null) {
      action = WfButton(
        label: completed ? WfStrings.replayBattle : WfStrings.enterBattle,
        glyph: WfGlyphType.battle,
        style: completed ? WfButtonStyle.secondary : WfButtonStyle.primary,
        onTap: () => Navigator.of(context).pop(_NodeAction.battle),
      );
    } else {
      action = Text(WfStrings.claimed, textAlign: TextAlign.center, style: WfText.body(14));
    }

    final rewardBuffs = node.type.isCombat ? (battle?.rewards.buffs ?? const <BuffType, int>{}) : node.rewards;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.18),
                  border: Border.all(color: color),
                ),
                child: WfGlyph(WfGlyphType.forNode(node.type), size: 26, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      WfTag(WfStrings.nodeType(node.type), color: color),
                      if (node.optional) ...[const SizedBox(width: 6), WfTag(WfStrings.optionalPath, color: WfColors.textDim)],
                    ]),
                    const SizedBox(height: 6),
                    Text(node.title, style: WfText.title(20)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(WfStrings.nodeDescription(node.type), style: WfText.body(14)),
          if (enemy != null) ...[
            const SizedBox(height: 14),
            WfPanel(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(child: Text(enemy.name, style: WfText.title(15.5))),
                            if (content.combat.behaviourFor(enemy.archetype.name).merge(enemy.behaviour).armor > 0) ...[
                              const SizedBox(width: 8),
                              WfTag(WfStrings.stoneSkin, color: WfColors.textDim),
                            ],
                            if (content.combat.behaviourFor(enemy.archetype.name).merge(enemy.behaviour).poisonImmune) ...[
                              const SizedBox(width: 8),
                              WfTag(WfStrings.ethereal, color: WfColors.sky),
                            ],
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(WfStrings.enemyTrait(enemy.archetype), style: WfText.body(12.5)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(WfStrings.vocabularyLevel, style: WfText.label(10)),
                      const SizedBox(height: 3),
                      Text(WfStrings.cefrFor(battle!.degrees), style: WfText.title(14, color: WfColors.arcane)),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (completed && node.type.isCombat) ...[
            const SizedBox(height: 12),
            Row(children: [
              Text(WfStrings.bestResult, style: WfText.label(11)),
              const SizedBox(width: 10),
              WfStarRow(stars: progress.bestStars, size: 18),
            ]),
          ],
          if (!completed && rewardBuffs.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(node.type.isCombat ? WfStrings.firstClearReward : WfStrings.rewards, style: WfText.label(11)),
            const SizedBox(height: 8),
            BuffChips(buffs: rewardBuffs),
          ],
          const SizedBox(height: 20),
          action,
        ],
      ),
    );
  }
}

/// Small celebratory dialog for rewards and map events.
Future<void> showRewardDialog(
  BuildContext context, {
  required String title,
  String? subtitle,
  required Map<BuffType, int> buffs,
  WfGlyphType glyph = WfGlyphType.bonus,
}) =>
    showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: title,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 320),
      pageBuilder: (dialogContext, _, __) => Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Material(
            type: MaterialType.transparency,
            child: WfPanel(
              glow: WfColors.gold,
              padding: const EdgeInsets.fromLTRB(22, 26, 22, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  WfGlyph(glyph, size: 54, color: WfColors.gold),
                  const SizedBox(height: 14),
                  Text(title, textAlign: TextAlign.center, style: WfText.display(22, spacing: 1)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(subtitle, textAlign: TextAlign.center, style: WfText.title(16, color: WfColors.gold)),
                  ],
                  if (buffs.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    BuffChips(buffs: buffs, showPlus: true),
                  ],
                  const SizedBox(height: 22),
                  WfButton(label: WfStrings.continueLabel, onTap: () => Navigator.of(dialogContext).pop()),
                ],
              ),
            ),
          ),
        ),
      ),
      transitionBuilder: (context, animation, _, child) => ScaleTransition(
        scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
        child: FadeTransition(opacity: animation, child: child),
      ),
    );
