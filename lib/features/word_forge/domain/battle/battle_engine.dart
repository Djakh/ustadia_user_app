import 'dart:async';
import 'dart:math';

import '../content/battle_definition.dart';
import '../content/difficulty.dart';
import '../content/enemy_definition.dart';
import '../language/answer_validator.dart';
import '../language/challenge_factory.dart';
import '../language/challenge_type.dart';
import '../language/distractor_style.dart';
import '../language/language_challenge.dart';
import '../progression/buffs.dart';
import 'battle_events.dart';
import 'battle_models.dart';
import 'combat_config.dart';
import 'encounter_director.dart';
import 'timer_policy.dart';

class _Enemy {
  final EnemyDefinition definition;
  final EnemyBehaviour behaviour;
  final int maxHp;
  int hp;
  int shieldStrength = 0;
  int shieldRemaining = 0;
  bool staggered = false;
  int poisonTicks = 0;
  int poisonAmount = 0;
  EnemyMove? intent;

  _Enemy(this.definition, this.behaviour, this.maxHp) : hp = maxHp;

  bool get alive => hp > 0;
  bool get shielded => shieldRemaining > 0;
  bool get poisoned => poisonTicks > 0;
}

class _Action {
  final BattleTurn turn;
  final MoveKind kind;
  final MoveDefinition? move;
  final int actor;
  final List<LanguageChallenge> tasks;
  final bool shieldBreak;
  final double timer;
  final int? shieldTarget;
  final List<bool> results = [];
  int index = 0;

  _Action({
    required this.turn,
    required this.kind,
    this.move,
    this.actor = -1,
    required this.tasks,
    this.shieldBreak = false,
    this.timer = 0,
    this.shieldTarget,
  });

  LanguageChallenge? get task => index < tasks.length ? tasks[index] : null;
  bool get hasMoreTasks => index < tasks.length - 1;
  int get successes => results.where((result) => result).length;
  MoveEffect get effect => move?.effect ?? MoveEffect.damage;
}

/// Pure-Dart, turn-based battle state machine shared by every game mode.
///
/// A round is: PLAYER TURN (Normal attack = similar meaning; sometimes a
/// Critical Opportunity follows; the earned Special can replace it) then
/// ENEMY TURN (Normal attack = defend with the opposite; occasionally a
/// telegraphed Critical or Special). Pacing decisions live in
/// [EncounterDirector]; English is checked by [AnswerValidator]; visuals
/// listen to [events]. Driven by [tick] in real seconds.
class BattleEngine {
  final BattleSetup setup;
  final AnswerValidator validator;
  final ChallengeFactory _factory;
  final GenerationContext _generation;
  late final EncounterDirector director =
      EncounterDirector(config: setup.config, random: _generation.random, access: setup.access);
  late final TimerPolicy _timers = TimerPolicy(setup.config.timers);

  final _events = StreamController<BattleEvent>.broadcast(sync: true);
  final _snapshots = StreamController<BattleSnapshot>.broadcast(sync: true);

  BattleEngine({
    required this.setup,
    required ChallengeFactory factory,
    required GenerationContext generation,
    this.validator = const AnswerValidator(),
  })  : _factory = factory,
        _generation = generation,
        _playerHp = setup.playerMaxHp,
        _inventory = Map.of(setup.inventory),
        _freeCharges = {if (setup.assist.freeHints > 0) BuffType.hint: setup.assist.freeHints},
        _wardCharges = setup.startWithWard || setup.assist.freeWard ? 1 : 0,
        _known = {...setup.knownTutorials},
        _special = setup.access.special ? setup.config.meter.start.clamp(0, setup.config.meter.max) : 0,
        _spells = [
          for (final id in setup.spells)
            if (setup.config.move(id)?.kind == MoveKind.special) id,
        ] {
    for (var i = 0; i < setup.enemies.length; i++) {
      _enemies.add(_Enemy(setup.enemies[i], setup.behaviourOf(i), setup.enemyHp[i]));
    }
    _wasAffordable = _anyAffordable;
    _snapshot = _buildSnapshot();
  }

  Stream<BattleEvent> get events => _events.stream;
  Stream<BattleSnapshot> get snapshots => _snapshots.stream;
  BattleSnapshot get snapshot => _snapshot;
  late BattleSnapshot _snapshot;

  CombatConfig get config => setup.config;
  BalanceConfig get _balance => config.balance;
  PacingHolds get _holds => config.holds;

  // --- state ---
  BattlePhase _phase = BattlePhase.intro;
  bool _started = false;
  bool _paused = false;
  bool _disposed = false;
  double _hold = 0;
  double _elapsed = 0;

  int _playerHp;
  final List<_Enemy> _enemies = [];
  int _target = 0;
  int _stageIndex = 0;
  BattleTurn _lastTurn = BattleTurn.enemy;
  _Action? _action;
  bool _midAction = false;
  MoveDefinition? _pendingCritical;
  int _lockedTurns = 0;

  final Set<String> _dimmed = {};
  final Set<String> _hidden = {};
  String? _revealedLetter;
  List<String> _placed = [];
  String? _hintedOption;
  String? _eatenOption;
  bool _eaterUsed = false;
  final Set<String> _matched = {};
  String? _selected;
  String? _missed;
  int _matchMistakes = 0;
  int _attempts = 0;
  double _challengeElapsed = 0;

  double _timerTotal = 0;
  double _timerRemaining = 0;
  double _freezeRemaining = 0;

  int _combo = 0;
  int _maxCombo = 0;
  double _flowRemaining = 0;

  /// Mana (historically the Special meter).
  int _special;
  bool _wasAffordable = false;
  int _manaSpent = 0;
  int _manaGained = 0;

  /// Attack turn on which each spell is ready again.
  final Map<String, int> _readyAt = {};
  int _wardReflect = 0;
  int _playerPoisonTicks = 0;
  int _playerPoisonAmount = 0;
  bool _poisonTicked = false;
  int _damageTaken = 0;
  int _score = 0;

  final Map<BuffType, int> _inventory;
  final Map<BuffType, int> _freeCharges;
  final Map<BuffType, int> _consumed = {};
  final Set<BuffType> _usedThisChallenge = {};
  bool _secondChanceArmed = false;
  int _wardCharges;
  int _runeSenseCharges = 0;
  final List<String> _spells;

  final Set<String> _usedWordIds = {};
  final Set<String> _usedContentKeys = {};
  final List<ChallengeRecord> _records = [];
  final Set<String> _known;
  final Set<String> _seenTutorials = {};
  String? _coachKey;
  ActionOutcome? _lastOutcome;
  bool? _lastTaskSuccess;
  String? _lastPicked;
  BattleResult? _result;
  int _specialsUsed = 0;
  int _criticalsLanded = 0;
  int _attackTurns = 0;
  final List<String> _spellsUsed = [];
  final List<String> _spellsFizzled = [];

  // --- read-only helpers ---
  BattlePhase get phase => _phase;
  bool get isPaused => _paused;
  bool get isOver => _phase.isOver;
  BattleResult? get result => _result;
  List<ChallengeRecord> get records => List.unmodifiable(_records);
  double get timerRemaining => _timerRemaining;
  double get timerFraction => _timerTotal <= 0 ? 0 : (_timerRemaining / _timerTotal).clamp(0.0, 1.0);
  int get specialCharge => _special;
  int get mana => _special;
  int get manaMax => _maxSpecial;
  int get attackTurns => _attackTurns;

  /// Player Specials available in this battle (starter first).
  List<String> get knownSpells => List.unmodifiable(_spells);

  /// Attack turns until [spellId] is ready again (0 = ready).
  int cooldownLeft(String spellId) => max(0, (_readyAt[spellId] ?? 0) - _attackTurns);

  /// Enough mana and off cooldown, regardless of whose turn it is.
  bool _affordable(String spellId) {
    final move = config.move(spellId);
    return move != null && _special >= move.manaCost && cooldownLeft(spellId) == 0;
  }

  bool get _anyAffordable => setup.access.special && _spells.any(_affordable);

  /// Why [spellId] cannot be cast right now ([SpellBlock.none] = castable).
  SpellBlock spellBlock(String spellId) {
    final move = config.move(spellId);
    if (move == null || !_spells.contains(spellId) || !setup.access.special) return SpellBlock.turn;
    if (_phase != BattlePhase.awaitingInput || _action?.turn != BattleTurn.player || _action?.kind != MoveKind.normal) {
      return SpellBlock.turn;
    }
    if (cooldownLeft(spellId) > 0) return SpellBlock.cooldown;
    if (_special < move.manaCost) return SpellBlock.mana;
    if (move.effect == MoveEffect.poison && _enemies[_target].behaviour.poisonImmune) return SpellBlock.immune;
    return SpellBlock.none;
  }

  bool canCast(String spellId) => spellBlock(spellId) == SpellBlock.none;
  bool get _flowActive => _flowRemaining > 0;
  BattleStage get _stage => setup.battle.stages[_stageIndex];
  bool get _isLastStage => _stageIndex == setup.battle.stages.length - 1;
  bool get _allEnemiesDown => _enemies.every((enemy) => !enemy.alive);
  int get _maxSpecial => config.meter.max;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  void start() {
    if (_started) return;
    _started = true;
    _phase = BattlePhase.intro;
    _hold = _holds.intro;
    _planIntent();
    _emitState();
    _events.add(BattleStarted(_snapshot));
  }

  void pause() => _paused = true;

  void resume() => _paused = false;

  /// Advances time. [dt] is clamped so a long frame (or returning from the
  /// background) never skips a challenge.
  void tick(double dt) {
    if (!_started || _paused || _disposed || isOver) return;
    final step = dt.clamp(0.0, 0.1);
    _elapsed += step;

    if (_flowActive) {
      _flowRemaining -= step;
      if (!_flowActive) {
        _events.add(const WordFlowChanged(active: false));
        _emitState();
      }
    }

    if (_phase == BattlePhase.awaitingInput) {
      _challengeElapsed += step;
      if (_timerTotal > 0) {
        if (_freezeRemaining > 0) {
          _freezeRemaining -= step;
          if (_freezeRemaining <= 0) _emitState();
        } else {
          _timerRemaining -= step;
          if (_timerRemaining <= 0) _onTimerExpired();
        }
      }
      return;
    }

    _hold -= step;
    if (_hold <= 0) _advance();
  }

  /// Ends the battle early (player retreated). Answers so far still count
  /// towards word mastery.
  BattleResult abandon() {
    if (_result != null) return _result!;
    _finish(victory: false, abandoned: true);
    return _result!;
  }

  void dispose() {
    _disposed = true;
    _events.close();
    _snapshots.close();
  }

  // ---------------------------------------------------------------------------
  // Turn flow
  // ---------------------------------------------------------------------------

  void _advance() {
    switch (_phase) {
      case BattlePhase.intro:
        _beginPlayerTurn();
      case BattlePhase.turnStart:
        final action = _action;
        if (action != null && action.tasks.isNotEmpty) {
          _presentTask();
        } else {
          _resolveAction();
        }
      case BattlePhase.resolving:
        if (_midAction) {
          _midAction = false;
          _action!.index++;
          _presentTask();
        } else {
          _afterAction();
        }
      case BattlePhase.stageTransition:
        _applyStageEntry();
        _continueTurns();
      case BattlePhase.awaitingInput:
      case BattlePhase.victory:
      case BattlePhase.defeat:
        break;
    }
  }

  void _afterAction() {
    if (_playerHp <= 0) {
      _finish(victory: false);
    } else if (_allEnemiesDown) {
      _finish(victory: true);
    } else if (_tickPoison()) {
      // Poison ticked; its own short beat before the next turn.
    } else if (_shouldChangeStage()) {
      _stageIndex++;
      _phase = BattlePhase.stageTransition;
      _hold = _holds.stageTransition;
      _action = null;
      for (final enemy in _enemies) {
        enemy.staggered = false;
      }
      _events.add(StageChanged(stageIndex: _stageIndex, name: _stage.name, enraged: _stage.enraged));
      _emitState();
    } else {
      _continueTurns();
    }
  }

  /// Poison ticks at the start of its victim's turn: enemies after the
  /// player's attack, the player after the enemy's move. Returns true when a
  /// tick happened and the flow should pause on it.
  bool _tickPoison() {
    if (_poisonTicked) {
      _poisonTicked = false;
      return false;
    }
    var ticked = false;
    if (_lastTurn == BattleTurn.player && _pendingCritical == null) {
      for (var i = 0; i < _enemies.length; i++) {
        final enemy = _enemies[i];
        if (!enemy.alive || !enemy.poisoned) continue;
        final dealt = _damageEnemy(i, enemy.poisonAmount, pierce: true);
        enemy.poisonTicks--;
        if (!enemy.alive || enemy.poisonTicks <= 0) enemy.poisonTicks = 0;
        _events.add(PoisonTick(target: i, damage: dealt, ticksLeft: enemy.poisonTicks));
        if (!enemy.alive) _events.add(EnemyDefeated(i));
        ticked = true;
      }
    } else if (_lastTurn == BattleTurn.enemy && _playerPoisonTicks > 0) {
      final dealt = min(_playerHp, _playerPoisonAmount);
      _playerHp -= dealt;
      _damageTaken += dealt;
      _playerPoisonTicks--;
      _events.add(PoisonTick(target: -1, damage: dealt, ticksLeft: _playerPoisonTicks));
      ticked = true;
    }
    if (!ticked) return false;
    _poisonTicked = true;
    _action = null;
    _phase = BattlePhase.resolving;
    _hold = _holds.poisonTick;
    _emitState();
    return true;
  }

  void _continueTurns() {
    final critical = _pendingCritical;
    if (critical != null) {
      _pendingCritical = null;
      _beginPlayerCritical(critical);
    } else if (_lastTurn == BattleTurn.player) {
      _beginEnemyTurn();
    } else {
      _beginPlayerTurn();
    }
  }

  bool _shouldChangeStage() {
    final threshold = _stage.untilHpFraction;
    if (_isLastStage || threshold == null) return false;
    final primary = _enemies.first;
    return primary.hp / primary.maxHp <= threshold;
  }

  void _applyStageEntry() {
    final stage = _stage;
    if (stage.opensWith != null) {
      for (final enemy in _enemies) {
        enemy.intent = null;
      }
      director.force(stage.opensWith!);
      _planIntent();
    }
    if (stage.grantSpecial && setup.access.special) _setSpecial(_maxSpecial);
  }

  // --- player ----------------------------------------------------------------

  void _beginPlayerTurn() {
    _lastTurn = BattleTurn.player;
    director.notePlayerTurn();
    _ensureTarget();
    if (_lockedTurns > 0) {
      _lockedTurns--;
      _action = null;
      _phase = BattlePhase.resolving;
      _hold = _holds.skippedTurn;
      _events.add(const TurnSkipped(turn: BattleTurn.player, reason: 'locked'));
      _emitState();
      return;
    }
    _attackTurns++;
    _checkSpellReady();
    _startAction(_normalAttackAction(), _holds.playerTurnBanner);
  }

  /// Normal attacks are gently timed: too slow (or wrong) still lands a
  /// Weak Cast, so progress never stops completely.
  _Action _normalAttackAction() {
    final tasks = _tasks(const [TaskSpec([ChallengeType.synonym])]);
    return _Action(
      turn: BattleTurn.player,
      kind: MoveKind.normal,
      tasks: tasks,
      timer: _timerFor(TimerUse.normal, tasks, 1),
      shieldBreak: _enemies[_target].shielded,
    );
  }

  void _beginPlayerCritical(MoveDefinition move) {
    final tasks = _tasks(move.tasks);
    final action = _Action(
      turn: BattleTurn.player,
      kind: MoveKind.critical,
      move: move,
      tasks: tasks,
      timer: _timerFor(move.timer, tasks, move.timerScale),
      shieldBreak: _enemies[_target].shielded,
    );
    _events.add(CriticalOpportunity(move));
    _startAction(action, _holds.criticalOpportunity);
  }

  /// At least one known spell can be cast right now.
  bool get canActivateSpecial => _spells.any(canCast);

  /// Replaces the current Normal Attack with a Special. [spellId] must be one
  /// of [knownSpells]; by default the first castable spell. Mana is spent
  /// when the cast begins; the cooldown starts only if a stage succeeds.
  bool activateSpecial([String? spellId]) {
    final id = spellId ?? _spells.firstWhere(canCast, orElse: () => '');
    if (!canCast(id)) return false;
    final move = config.move(id)!;
    final tasks = _tasks(move.tasks);
    if (tasks.isEmpty) return false;
    _setSpecial(max(0, _special - move.manaCost));
    _manaSpent += move.manaCost;
    _specialsUsed++;
    _spellsUsed.add(id);
    _events.add(SpecialActivated(move));
    _startAction(
      _Action(
        turn: BattleTurn.player,
        kind: MoveKind.special,
        move: move,
        tasks: tasks,
        timer: _timerFor(move.timer, tasks, move.timerScale),
      ),
      _holds.criticalOpportunity,
    );
    return true;
  }

  /// Taps on another enemy switch the Normal Attack target.
  bool selectTarget(int index) {
    final action = _action;
    if (index < 0 || index >= _enemies.length || !_enemies[index].alive || index == _target) return false;
    if (_phase != BattlePhase.awaitingInput || action == null) return false;
    if (action.turn != BattleTurn.player || action.kind != MoveKind.normal) return false;
    _target = index;
    _events.add(TargetChanged(index));
    _action = _normalAttackAction();
    _presentTask();
    return true;
  }

  void _ensureTarget() {
    if (_enemies[_target].alive) return;
    for (var i = 0; i < _enemies.length; i++) {
      if (_enemies[i].alive) {
        _target = i;
        _events.add(TargetChanged(i));
        return;
      }
    }
  }

  // --- enemy -----------------------------------------------------------------

  List<EnemyView> get _views => [
        for (var i = 0; i < _enemies.length; i++)
          EnemyView(
            index: i,
            alive: _enemies[i].alive,
            shielded: _enemies[i].shielded,
            hpFraction: _enemies[i].hp / _enemies[i].maxHp,
            behaviour: _enemies[i].behaviour,
          ),
      ];

  void _planIntent() {
    final next = director.nextActor(_views);
    if (next == null) return;
    _enemies[next].intent ??= director.plan(next, _views, _stage);
  }

  void _beginEnemyTurn() {
    _lastTurn = BattleTurn.enemy;
    final actor = director.nextActor(_views);
    if (actor == null) {
      _finish(victory: true);
      return;
    }
    final enemy = _enemies[actor];
    if (enemy.staggered) {
      enemy.staggered = false;
      director.skipEnemyTurn();
      director.commit(actor, EnemyMove.normal);
      _action = null;
      _phase = BattlePhase.resolving;
      _hold = _holds.skippedTurn;
      _events.add(TurnSkipped(turn: BattleTurn.enemy, reason: 'staggered', actor: actor));
      _planIntent();
      _emitState();
      return;
    }
    final planned = enemy.intent ?? director.plan(actor, _views, _stage);
    enemy.intent = null;
    final move = director.validate(planned, _views);
    director.commit(actor, move);

    final style = enemy.definition.distractorStyle;
    // Quick enemies give less time, slow ones more: part of their identity.
    final pace = enemy.behaviour.timerScale;
    final _Action action;
    switch (move.kind) {
      case MoveKind.normal:
        final tasks = _tasks([TaskSpec(const [ChallengeType.antonym], style: style)]);
        action = _Action(
          turn: BattleTurn.enemy,
          kind: MoveKind.normal,
          actor: actor,
          tasks: tasks,
          timer: _timerFor(TimerUse.normal, tasks, pace),
        );
      case MoveKind.critical:
        final tasks = _tasks([TaskSpec(const [ChallengeType.antonym], style: style, preferFamiliar: true)]);
        action = _Action(
          turn: BattleTurn.enemy,
          kind: MoveKind.critical,
          actor: actor,
          tasks: tasks,
          timer: _timerFor(TimerUse.enemyCritical, tasks, pace),
        );
      case MoveKind.special:
        final definition = move.move!;
        final tasks = _tasks(definition.tasks, defaultStyle: style);
        action = _Action(
          turn: BattleTurn.enemy,
          kind: MoveKind.special,
          move: definition,
          actor: actor,
          tasks: tasks,
          timer: _timerFor(definition.timer, tasks, definition.timerScale * pace),
          shieldTarget: move.shieldTarget,
        );
    }
    final banner = move.kind == MoveKind.normal ? _holds.enemyTurnBanner : _holds.telegraph;
    _planIntent();
    _startAction(action, banner);
  }

  // --- actions & tasks -------------------------------------------------------

  void _startAction(_Action action, double banner) {
    _action = action;
    _midAction = false;
    _clearTask();
    _timerTotal = 0;
    _timerRemaining = 0;
    _freezeRemaining = 0;
    _lastTaskSuccess = null;
    _lastPicked = null;
    _phase = BattlePhase.turnStart;
    _hold = banner;
    _coachKey = _tutorialFor(action);
    _events.add(TurnStarted(
      turn: action.turn,
      kind: action.kind,
      move: action.move,
      actor: action.actor,
      target: action.shieldTarget ?? _target,
    ));
    _emitState();
  }

  String? _tutorialFor(_Action action) {
    final key = switch ((action.turn, action.kind)) {
      (BattleTurn.player, MoveKind.normal) => _enemies.length > 1 && !_known.contains('twoEnemies')
          ? 'twoEnemies'
          : (action.shieldBreak ? 'shield' : 'attack'),
      (BattleTurn.player, MoveKind.critical) => 'criticalAttack',
      (BattleTurn.player, MoveKind.special) => action.move?.tutorial ?? 'special',
      (BattleTurn.enemy, MoveKind.normal) => 'defence',
      (BattleTurn.enemy, MoveKind.critical) => 'criticalDefence',
      (BattleTurn.enemy, MoveKind.special) => action.move?.tutorial ?? 'enemySpecial',
    };
    if (_known.contains(key)) return null;
    _known.add(key);
    _seenTutorials.add(key);
    return key;
  }

  List<LanguageChallenge> _tasks(List<TaskSpec> specs, {DistractorStyle? defaultStyle}) {
    final result = <LanguageChallenge>[];
    for (var i = 0; i < specs.length; i++) {
      final spec = specs[i];
      final type = spec.types[_generation.random.nextInt(spec.types.length)];
      final needsBoth = i + 1 < specs.length && specs[i + 1].samePrompt;
      final previous = result.isEmpty ? null : result.last;
      final challenge = _generate(
        type,
        degrees: _shift(setup.degrees, spec.degreeOffset),
        style: spec.style ?? defaultStyle ?? DistractorStyle.standard,
        promptWordId: spec.samePrompt ? previous?.focusWordId : null,
        preferFamiliar: spec.preferFamiliar,
        requireBoth: needsBoth,
      );
      if (challenge != null) result.add(challenge);
    }
    return result;
  }

  LanguageChallenge? _generate(
    ChallengeType type, {
    required DegreeRange degrees,
    required DistractorStyle style,
    String? promptWordId,
    bool preferFamiliar = false,
    bool requireBoth = false,
  }) {
    final optionCount = _balance.optionCount - (setup.assist.reducedOptions ? 1 : 0);
    LanguageChallenge? attempt(ChallengeType kind) => _factory.create(
          GenerationRequest(
            type: kind,
            degrees: degrees,
            style: style,
            optionCount: optionCount,
            excludedWordIds: _usedWordIds,
            excludedContentKeys: _usedContentKeys,
            promptWordId: promptWordId,
            preferFamiliar: preferFamiliar,
            requireBothRelations: requireBoth,
          ),
          _generation,
        );
    final challenge = attempt(type) ?? (type == ChallengeType.antonym ? null : attempt(ChallengeType.antonym));
    if (challenge != null) {
      _usedWordIds.addAll(challenge.wordIds);
      _usedContentKeys.add(challenge.contentKey);
    }
    return challenge;
  }

  DegreeRange _shift(DegreeRange range, int offset) {
    if (offset == 0) return range;
    final low = max(1, range.min + offset);
    final high = max(low, range.max + offset);
    return DegreeRange(low, high);
  }

  double _timerFor(TimerUse use, List<LanguageChallenge> tasks, double scale) {
    final seconds = _timers.secondsFor(
      use: use,
      tasks: tasks,
      statsOf: _generation.stats.statsFor,
      scale: scale,
      playerLevel: setup.playerLevel,
    );
    if (seconds <= 0) return 0;
    return seconds * setup.assist.timeMultiplier + setup.upgrades.focusSeconds;
  }

  void _presentTask() {
    final action = _action!;
    final challenge = action.task;
    if (challenge == null) {
      _resolveAction();
      return;
    }
    _clearTask();
    if (action.index == 0 && action.timer > 0) {
      _timerTotal = action.timer;
      _timerRemaining = action.timer;
    }
    if (_runeSenseCharges > 0 && _hideOneWrongOption()) _runeSenseCharges--;
    _phase = BattlePhase.awaitingInput;
    _events.add(TaskPresented(
      turn: action.turn,
      kind: action.kind,
      challenge: challenge,
      index: action.index,
      count: action.tasks.length,
    ));
    _emitState();
  }

  void _clearTask() {
    _dimmed.clear();
    _hidden.clear();
    _revealedLetter = null;
    _placed = [];
    _hintedOption = null;
    _eatenOption = null;
    _eaterUsed = false;
    _matched.clear();
    _selected = null;
    _missed = null;
    _matchMistakes = 0;
    _attempts = 0;
    _challengeElapsed = 0;
    _usedThisChallenge.clear();
  }

  // ---------------------------------------------------------------------------
  // Input
  // ---------------------------------------------------------------------------

  LanguageChallenge? get _openTask => _phase == BattlePhase.awaitingInput ? _action?.task : null;

  void submitChoice(String optionId) {
    final challenge = _openTask;
    if (challenge == null || challenge.inputMode != ChallengeInputMode.choice) return;
    if (_dimmed.contains(optionId) || _hidden.contains(optionId) || challenge.option(optionId) == null) return;
    if (validator.isCorrectChoice(challenge, optionId)) {
      _completeTask(success: true, picked: optionId);
      return;
    }
    _attempts++;
    if (_consumeSecondChance()) {
      _dimmed.add(optionId);
      _events.add(AnswerForgiven(optionId));
      _emitState();
      return;
    }
    _completeTask(success: false, picked: optionId);
  }

  void placeToken(String optionId) {
    final challenge = _openTask;
    if (challenge == null || challenge.inputMode != ChallengeInputMode.arrange) return;
    if (_placed.contains(optionId) || challenge.option(optionId) == null) return;
    _placed = [..._placed, optionId];
    _eatenOption = null;
    if (_hintedOption == optionId) _hintedOption = null;

    final total = challenge.options.length;
    final eater = _enemies.any((enemy) => enemy.alive && enemy.definition.has(EnemyTrait.wordEater));
    if (eater && !_eaterUsed && _placed.length >= max(2, (total / 2).ceil()) && _placed.length < total) {
      _eaterUsed = true;
      _eatenOption = _placed.last;
      _placed = _placed.sublist(0, _placed.length - 1);
      _events.add(WordEaten(_eatenOption!));
      _emitState();
      return;
    }
    if (_placed.length == total) {
      _evaluateArrangement(challenge);
    } else {
      _emitState();
    }
  }

  void removeToken(String optionId) {
    if (_openTask == null || !_placed.contains(optionId)) return;
    _placed = [..._placed]..remove(optionId);
    _emitState();
  }

  void clearTokens() {
    if (_openTask == null || _placed.isEmpty) return;
    _placed = [];
    _emitState();
  }

  void _evaluateArrangement(LanguageChallenge challenge) {
    if (validator.isCorrectArrangement(challenge, _placed)) {
      _completeTask(success: true);
      return;
    }
    _attempts++;
    final canRetry = _attempts < _balance.incantationAttempts || _consumeSecondChance();
    if (canRetry) {
      final keep = validator.correctPrefixLength(challenge, _placed);
      _placed = _placed.sublist(0, keep);
      _events.add(IncantationUnstable(keep));
      _emitState();
      return;
    }
    _completeTask(success: false);
  }

  /// Word Match: tap one word, then its partner.
  void selectMatch(String optionId) {
    final challenge = _openTask;
    if (challenge == null || challenge.inputMode != ChallengeInputMode.match) return;
    if (_matched.contains(optionId) || challenge.option(optionId) == null) return;
    _missed = null;
    final selected = _selected;
    if (selected == null || selected == optionId || challenge.isLeft(selected) == challenge.isLeft(optionId)) {
      _selected = selected == optionId ? null : optionId;
      _emitState();
      return;
    }
    _selected = null;
    if (validator.isCorrectPair(challenge, selected, optionId)) {
      _matched.addAll([selected, optionId]);
      if (_hintedOption == selected || _hintedOption == optionId) _hintedOption = null;
      _events.add(MatchMade(selected, optionId));
      if (_matched.length == challenge.options.length) {
        _completeTask(success: true);
      } else {
        _emitState();
      }
      return;
    }
    _missed = optionId;
    _events.add(const MatchMissed());
    if (_consumeSecondChance()) {
      _events.add(AnswerForgiven(optionId));
      _emitState();
      return;
    }
    _attempts++;
    _matchMistakes++;
    if (_matchMistakes > _balance.matchMistakesAllowed) {
      _completeTask(success: false);
    } else {
      _emitState();
    }
  }

  void _onTimerExpired() {
    _timerRemaining = 0;
    _events.add(const TimerRanOut());
    _completeTask(success: false, timedOut: true);
  }

  // ---------------------------------------------------------------------------
  // Resolution
  // ---------------------------------------------------------------------------

  double _targetSeconds(LanguageChallenge challenge, _Action action) {
    if (action.timer > 0) return action.timer / action.tasks.length;
    return switch (challenge.type) {
      ChallengeType.antonym || ChallengeType.synonym => 6,
      ChallengeType.missingRune => 9,
      ChallengeType.incantation => 18,
      ChallengeType.wordMatch => 12,
    };
  }

  void _completeTask({required bool success, String? picked, bool timedOut = false}) {
    final action = _action!;
    final challenge = action.task!;
    _records.add(_record(challenge, action, success: success, timedOut: timedOut));
    action.results.add(success);
    _lastTaskSuccess = success;
    _lastPicked = picked;
    _updateMomentum(success: success, fast: success && _challengeElapsed <= _targetSeconds(challenge, action) * 0.5);
    if (success) _gainForTask(action);

    if (timedOut) {
      // Time is shared by the whole move: remaining tasks fail too.
      while (action.hasMoreTasks) {
        action.index++;
        _records.add(_record(action.task!, action, success: false, timedOut: true));
        action.results.add(false);
      }
    }
    if (action.hasMoreTasks) {
      _midAction = true;
      _phase = BattlePhase.resolving;
      _hold = _holds.taskStep;
      _events.add(TaskResolved(
        challenge: challenge,
        success: success,
        record: _records.last,
        index: action.index,
        count: action.tasks.length,
      ));
      _emitState();
      return;
    }
    _resolveAction(picked: picked, timedOut: timedOut);
  }

  ChallengeRecord _record(LanguageChallenge challenge, _Action action,
          {required bool success, required bool timedOut}) =>
      ChallengeRecord(
        type: challenge.type,
        turn: action.turn,
        kind: action.kind,
        moveId: action.move?.id,
        wordIds: challenge.wordIds,
        focusWordId: challenge.focusWordId,
        contentKey: challenge.contentKey,
        success: success,
        firstTry: success && _attempts == 0,
        attempts: _attempts + 1,
        responseSeconds: timedOut ? _targetSeconds(challenge, action) : _challengeElapsed,
        targetSeconds: _targetSeconds(challenge, action),
        timedOut: timedOut,
      );

  void _gainForTask(_Action action) {
    if (action.turn == BattleTurn.player && action.kind == MoveKind.special) return;
    final meter = config.meter;
    final gain = switch ((action.turn, action.kind)) {
      (BattleTurn.player, MoveKind.normal) => meter.normalHit,
      (BattleTurn.player, MoveKind.critical) => (meter.criticalAttack / max(1, action.tasks.length)).round(),
      (BattleTurn.player, MoveKind.special) => 0,
      (BattleTurn.enemy, MoveKind.normal) => meter.defence,
      (BattleTurn.enemy, MoveKind.critical) => meter.criticalDefence,
      (BattleTurn.enemy, MoveKind.special) => meter.defence,
    };
    _addSpecial(gain + (_flowActive ? meter.flowBonus : 0));
  }

  void _addSpecial(int amount) {
    if (!setup.access.special || amount <= 0) return;
    final next = min(_maxSpecial, _special + amount);
    _manaGained += next - _special;
    _setSpecial(next);
  }

  void _setSpecial(int value) {
    _special = value.clamp(0, _maxSpecial);
    _checkSpellReady();
  }

  /// "Special ready" fires when a spell becomes castable (mana reached or a
  /// cooldown ended) after none was.
  void _checkSpellReady() {
    final now = _anyAffordable;
    if (now && !_wasAffordable) _events.add(const SpecialReady());
    _wasAffordable = now;
  }

  void _resolveAction({String? picked, bool timedOut = false}) {
    final action = _action!;
    final damage = <int, int>{};
    var damageToPlayer = 0;
    var blocked = false;
    var cracked = false;
    var shattered = false;
    var raised = false;
    var locked = false;
    var weakCast = false;
    var staggered = false;
    var wardGained = 0;
    var reflected = 0;
    var poisonApplied = 0;
    var fizzled = false;
    final enraged = _stage.enraged ? _balance.enragedMultiplier : 1.0;
    final multiplier = _attackMultiplier();
    final failures = action.tasks.length - action.successes;

    // The ward eats one enemy hit; a Guardian Ward also throws some back.
    bool absorb(int attacker) {
      if (_wardCharges <= 0) return false;
      _wardCharges--;
      blocked = true;
      _events.add(const WardTriggered());
      if (_wardReflect > 0 && attacker >= 0 && _enemies[attacker].alive) {
        reflected = _damageEnemy(attacker, _wardReflect, pierce: true);
        damage[attacker] = (damage[attacker] ?? 0) + reflected;
      }
      if (_wardCharges == 0) _wardReflect = 0;
      return true;
    }

    void hurtPlayer(int amount) {
      final dealt = min(_playerHp, amount);
      _playerHp -= dealt;
      _damageTaken += dealt;
    }

    // Normal hits respect stone skin; Criticals and Specials pierce it.
    void hitTarget(int amount, {bool pierce = false}) {
      final enemy = _enemies[_target];
      if (enemy.shielded) {
        enemy.shieldRemaining--;
        cracked = true;
        if (enemy.shieldRemaining <= 0) shattered = _shatter(_target);
        return;
      }
      damage[_target] = (damage[_target] ?? 0) + _damageEnemy(_target, amount, pierce: pierce);
    }

    // Specials break through a barrier at reduced power instead of bouncing.
    int throughShield(int amount) {
      final target = _enemies[_target];
      if (!target.shielded) return amount;
      cracked = true;
      shattered = _shatter(_target);
      return (amount * 0.7).round();
    }

    switch ((action.turn, action.kind)) {
      case (BattleTurn.player, MoveKind.normal):
        if (action.successes > 0) {
          hitTarget((_balance.normalDamage * multiplier).round());
          if (!_allEnemiesDown && director.rollPlayerCritical(combo: _combo, stage: _stage)) {
            _pendingCritical = director.pickPlayerCritical();
          }
        } else {
          // Weak Cast: the spell still leaves the wand, just without power.
          // A wrong word (not a slow one) also leaves the player open to a
          // small counter, so random tapping is never a strategy.
          weakCast = true;
          hitTarget(_balance.weakCastDamage);
          _addSpecial(config.meter.weakCast);
          if (!timedOut) {
            final actor = _enemies.indexWhere((enemy) => enemy.alive);
            if (actor >= 0) {
              damageToPlayer = (_enemies[actor].definition.attack * enraged * _balance.weakCastCounterShare).round();
              if (damageToPlayer > 0 && absorb(actor)) damageToPlayer = 0;
              hurtPlayer(damageToPlayer);
            }
          }
        }
      case (BattleTurn.player, MoveKind.critical):
        if (action.tasks.isNotEmpty && action.successes == action.tasks.length) {
          _criticalsLanded++;
          hitTarget((_balance.criticalAttackDamage * multiplier).round(), pierce: true);
        }
      case (BattleTurn.player, MoveKind.special):
        final move = action.move!;
        final full = action.tasks.isNotEmpty && action.successes == action.tasks.length;
        final any = action.successes > 0;
        if (!any) {
          // Fizzle: the mana is gone and the turn is spent, nothing else.
          // No cooldown, no counter: one consequence per mistake.
          fizzled = true;
          _spellsFizzled.add(move.id);
        } else {
          _readyAt[move.id] = _attackTurns + move.cooldown + 1;
          switch (move.effect) {
            case MoveEffect.ward:
              wardGained = full ? move.charges : 1;
              _wardCharges += wardGained;
              _wardReflect = max(_wardReflect, move.reflect);
              _events.add(WardRaised(_wardCharges));
            case MoveEffect.bind:
              final amount = move.amount > 0 ? move.amount : _balance.specialDamage ~/ 2;
              damage[_target] = _damageEnemy(_target, throughShield((amount * multiplier).round()), pierce: true);
              if (full && _enemies[_target].alive) {
                _enemies[_target].staggered = true;
                staggered = true;
              }
            case MoveEffect.poison:
              final enemy = _enemies[_target];
              final ticks = full ? move.duration : max(1, move.duration - 1);
              if (!enemy.behaviour.poisonImmune && enemy.alive) {
                enemy
                  ..poisonTicks = max(enemy.poisonTicks, ticks)
                  ..poisonAmount = max(1, (move.amount * multiplier).round());
                poisonApplied = ticks;
                _events.add(PoisonApplied(target: _target, ticks: ticks));
              }
            case MoveEffect.multiHit:
              final perHit = move.amount > 0 ? move.amount : _balance.normalDamage;
              var total = 0;
              for (var i = 0; i < action.successes; i++) {
                total += _damageEnemy(_target, throughShield((perHit * multiplier).round()), pierce: true);
              }
              damage[_target] = total;
            case MoveEffect.damage:
            case MoveEffect.shield:
            case MoveEffect.lock:
              final share = _balance.specialShare(action.successes, action.tasks.length);
              final baseAmount = move.amount > 0 ? move.amount : _balance.specialDamage;
              final base = baseAmount * share * multiplier;
              damage[_target] = _damageEnemy(_target, throughShield(base.round()), pierce: true);
              for (var i = 0; i < _enemies.length; i++) {
                if (i != _target && _enemies[i].alive) {
                  damage[i] = _damageEnemy(i, (base * _balance.specialSplash).round(), pierce: true);
                }
              }
          }
        }
      case (BattleTurn.enemy, _):
        final attack = _enemies[action.actor].definition.attack * enraged;
        if (action.effect == MoveEffect.shield) {
          final target = action.shieldTarget ?? action.actor;
          final strength = action.move!.shieldStrength > 0
              ? action.move!.shieldStrength
              : _enemies[action.actor].behaviour.shieldStrength;
          _enemies[target]
            ..shieldStrength = strength
            ..shieldRemaining = strength;
          raised = true;
        } else if (failures == 0) {
          final counter = action.kind == MoveKind.normal ? _balance.counterDamage : _balance.criticalCounterDamage;
          damage[action.actor] = _damageEnemy(action.actor, (counter * _balance.comboMultiplier(_combo)).round());
        } else {
          final perFailure = switch (action.kind) {
            MoveKind.normal => 1.0,
            MoveKind.critical => _balance.enemyCriticalMultiplier,
            MoveKind.special => action.move!.damagePerFailure,
          };
          damageToPlayer = max(1, (attack * perFailure * failures).round());
          if (absorb(action.actor)) {
            damageToPlayer = 0;
          } else {
            if (action.effect == MoveEffect.lock) {
              _lockedTurns = 1;
              locked = true;
            }
            if (action.effect == MoveEffect.poison) {
              final move = action.move!;
              _playerPoisonTicks = max(_playerPoisonTicks, move.duration);
              _playerPoisonAmount = max(1, (move.amount * enraged).round());
              poisonApplied = move.duration;
              _events.add(PoisonApplied(target: -1, ticks: move.duration));
            }
          }
          hurtPlayer(damageToPlayer);
        }
    }

    final challenge = action.tasks.isEmpty ? null : action.tasks[min(action.index, action.tasks.length - 1)];
    final outcome = ActionOutcome(
      turn: action.turn,
      kind: action.kind,
      moveId: action.move?.id,
      effect: action.effect,
      actor: action.actor,
      target: action.shieldTarget ?? _target,
      successes: action.successes,
      total: action.tasks.length,
      damageToEnemies: damage,
      damageToPlayer: damageToPlayer,
      blockedByWard: blocked,
      shieldCracked: cracked,
      shieldShattered: shattered,
      shieldRaised: raised,
      lockApplied: locked,
      timedOut: timedOut,
      weakCast: weakCast,
      staggerApplied: staggered,
      wardCharges: wardGained,
      reflected: reflected,
      poisonApplied: poisonApplied,
      spellFizzled: fizzled,
      pickedOptionId: picked,
      correctOptionId: challenge != null && challenge.inputMode == ChallengeInputMode.choice
          ? validator.correctOptionId(challenge)
          : null,
      intensity: (_combo / _balance.comboCap + (_flowActive ? 0.3 : 0) + (action.kind == MoveKind.special ? 0.4 : 0))
          .clamp(0.0, 1.0),
    );
    _lastOutcome = outcome;
    _phase = BattlePhase.resolving;
    _hold = _holdFor(action, outcome);
    _events.add(ActionResolved(outcome, challenge));
    for (final entry in damage.entries) {
      if (!_enemies[entry.key].alive && entry.value > 0) _events.add(EnemyDefeated(entry.key));
    }
    if (shattered) _addSpecial(config.meter.shieldBreak);
    _emitState();
  }

  double _holdFor(_Action action, ActionOutcome outcome) {
    final base = switch ((action.turn, action.kind)) {
      (BattleTurn.player, MoveKind.normal) => _holds.normalAttack,
      (BattleTurn.player, MoveKind.critical) => _holds.criticalAttack,
      (BattleTurn.player, MoveKind.special) => _holds.special,
      (BattleTurn.enemy, MoveKind.normal) => _holds.defence,
      (BattleTurn.enemy, MoveKind.critical) => _holds.criticalDefence,
      (BattleTurn.enemy, MoveKind.special) => outcome.shieldRaised ? _holds.shieldRaise : _holds.criticalDefence,
    };
    return base + (_allEnemiesDown || outcome.shieldShattered ? 0.4 : 0);
  }

  bool _shatter(int index) {
    _enemies[index]
      ..shieldRemaining = 0
      ..shieldStrength = 0
      ..staggered = true;
    return true;
  }

  double _attackMultiplier() {
    var multiplier = _balance.comboMultiplier(_combo);
    if (_flowActive) multiplier *= 1 + _balance.flowDamageBonus;
    if (_combo >= 4) multiplier *= 1 + setup.upgrades.momentumBonus;
    return multiplier;
  }

  int _damageEnemy(int index, int amount, {bool pierce = false}) {
    final enemy = _enemies[index];
    if (!enemy.alive || amount <= 0) return 0;
    final armor = pierce ? 0.0 : enemy.behaviour.armor;
    final taken = max(1, (amount * (1 - armor)).round());
    var next = enemy.hp - taken;
    // The main enemy of a multi-phase fight cannot fall before its last phase.
    if (index == 0 && !_isLastStage) next = max(1, next);
    next = max(0, next);
    final dealt = enemy.hp - next;
    enemy.hp = next;
    if (!enemy.alive) {
      enemy
        ..shieldRemaining = 0
        ..intent = null;
    }
    return dealt;
  }

  void _updateMomentum({required bool success, required bool fast}) {
    if (success) {
      _score += (100 * _balance.comboMultiplier(_combo) * (_flowActive ? 1.5 : 1) * (fast ? 1.2 : 1)).round();
      _combo++;
      _maxCombo = max(_maxCombo, _combo);
      final every = config.meter.comboMilestoneEvery;
      if (every > 0 && _combo % every == 0) _addSpecial(config.meter.comboMilestone);
      if (_combo >= _balance.flowThreshold && !_flowActive) {
        _flowRemaining = _balance.flowSeconds;
        _events.add(const WordFlowChanged(active: true));
      }
    } else {
      _combo = 0;
      if (_flowActive) {
        _flowRemaining = 0;
        _events.add(const WordFlowChanged(active: false));
      }
    }
  }

  void _finish({required bool victory, bool abandoned = false}) {
    if (_result != null) return;
    _phase = victory ? BattlePhase.victory : BattlePhase.defeat;
    _result = BattleResult(
      victory: victory,
      abandoned: abandoned,
      records: List.unmodifiable(_records),
      maxCombo: _maxCombo,
      score: _score,
      playerHpFraction: _playerHp / setup.playerMaxHp,
      buffsConsumed: Map.unmodifiable(_consumed),
      durationSeconds: _elapsed,
      tutorialsSeen: Set.unmodifiable(_seenTutorials),
      specialsUsed: _specialsUsed,
      criticalsLanded: _criticalsLanded,
      attackTurns: _attackTurns,
      spellsUsed: List.unmodifiable(_spellsUsed),
      spellsFizzled: List.unmodifiable(_spellsFizzled),
      manaSpent: _manaSpent,
      manaGained: _manaGained,
      damageTaken: _damageTaken,
    );
    _emitState();
    _events.add(BattleEnded(_result!));
  }

  // ---------------------------------------------------------------------------
  // Buffs
  // ---------------------------------------------------------------------------

  int buffCount(BuffType buff) => (_inventory[buff] ?? 0) + (_freeCharges[buff] ?? 0);

  bool canUseBuff(BuffType buff) {
    final challenge = _openTask;
    if (challenge == null) return false;
    if (buffCount(buff) <= 0 || _usedThisChallenge.contains(buff)) return false;
    final mode = challenge.inputMode;
    final hasTimer = _timerTotal > 0;
    return switch (buff) {
      BuffType.hint => switch (mode) {
          ChallengeInputMode.choice => _wrongSelectable().isNotEmpty && _selectable().length > 2,
          ChallengeInputMode.arrange => _unplaced().isNotEmpty,
          ChallengeInputMode.match => _hintedOption == null && _matched.length < challenge.options.length,
        },
      BuffType.reveal => switch (mode) {
          ChallengeInputMode.choice => _revealedLetter == null,
          ChallengeInputMode.arrange => _unplaced().isNotEmpty,
          ChallengeInputMode.match => _matched.length < challenge.options.length - 2,
        },
      BuffType.timeFreeze => hasTimer && _freezeRemaining <= 0,
      BuffType.extraTime => hasTimer,
      BuffType.secondChance => !_secondChanceArmed,
      BuffType.runeSense => mode == ChallengeInputMode.choice && _selectable().length > 2,
      BuffType.shield => _wardCharges == 0,
    };
  }

  bool useBuff(BuffType buff) {
    if (!canUseBuff(buff)) return false;
    final challenge = _openTask!;
    switch (buff) {
      case BuffType.hint:
        switch (challenge.inputMode) {
          case ChallengeInputMode.choice:
            for (var i = 0; i < setup.upgrades.hintEliminates; i++) {
              final wrong = _wrongSelectable();
              if (wrong.isEmpty || _selectable().length <= 2) break;
              _dimmed.add(wrong[_generation.random.nextInt(wrong.length)]);
            }
            if (setup.upgrades.hintRevealsLetter) _revealedLetter ??= _firstLetter(challenge);
          case ChallengeInputMode.arrange:
            _trimToCorrectPrefix(challenge);
            _hintedOption = validator.nextCorrectOptionId(challenge, _placed);
          case ChallengeInputMode.match:
            _hintedOption = challenge.pairs.keys.firstWhere((left) => !_matched.contains(left));
        }
      case BuffType.reveal:
        switch (challenge.inputMode) {
          case ChallengeInputMode.choice:
            _revealedLetter = _firstLetter(challenge);
          case ChallengeInputMode.arrange:
            _trimToCorrectPrefix(challenge);
            final next = validator.nextCorrectOptionId(challenge, _placed);
            if (next != null) {
              _consume(buff);
              _events.add(BuffUsed(buff));
              placeToken(next);
              return true;
            }
          case ChallengeInputMode.match:
            final left = challenge.pairs.keys.firstWhere((id) => !_matched.contains(id));
            _consume(buff);
            _events.add(BuffUsed(buff));
            _selected = null;
            selectMatch(left);
            selectMatch(challenge.pairs[left]!);
            return true;
        }
      case BuffType.timeFreeze:
        _freezeRemaining = _balance.timeFreezeSeconds;
      case BuffType.extraTime:
        _timerRemaining += _balance.extraTimeSeconds;
        _timerTotal = max(_timerTotal, _timerRemaining);
      case BuffType.secondChance:
        _secondChanceArmed = true;
      case BuffType.runeSense:
        _hideOneWrongOption();
        _runeSenseCharges = _balance.runeSenseChallenges - 1;
      case BuffType.shield:
        _wardCharges = max(_wardCharges, 1);
        _events.add(WardRaised(_wardCharges));
    }
    if (buff == BuffType.shield) _wardReflect = 0;
    _consume(buff);
    _events.add(BuffUsed(buff));
    _emitState();
    return true;
  }

  void _consume(BuffType buff) {
    _usedThisChallenge.add(buff);
    final free = _freeCharges[buff] ?? 0;
    if (free > 0) {
      _freeCharges[buff] = free - 1;
      return;
    }
    _inventory[buff] = max(0, (_inventory[buff] ?? 0) - 1);
    _consumed[buff] = (_consumed[buff] ?? 0) + 1;
  }

  bool _consumeSecondChance() {
    if (!_secondChanceArmed) return false;
    _secondChanceArmed = false;
    return true;
  }

  List<String> _selectable() => [
        for (final option in _action!.task!.options)
          if (!_dimmed.contains(option.id) && !_hidden.contains(option.id)) option.id,
      ];

  List<String> _wrongSelectable() {
    final correct = validator.correctOptionId(_action!.task!);
    return _selectable().where((id) => id != correct).toList();
  }

  List<String> _unplaced() => [for (final option in _action!.task!.options) if (!_placed.contains(option.id)) option.id];

  bool _hideOneWrongOption() {
    final challenge = _action?.task;
    if (challenge == null || challenge.inputMode != ChallengeInputMode.choice) return false;
    final wrong = _wrongSelectable();
    if (wrong.isEmpty || _selectable().length <= 2) return false;
    _hidden.add(wrong[_generation.random.nextInt(wrong.length)]);
    return true;
  }

  void _trimToCorrectPrefix(LanguageChallenge challenge) {
    final keep = validator.correctPrefixLength(challenge, _placed);
    if (keep < _placed.length) _placed = _placed.sublist(0, keep);
  }

  String _firstLetter(LanguageChallenge challenge) {
    final answer = challenge.correctAnswer.trim();
    return answer.isEmpty ? '' : answer[0].toUpperCase();
  }

  // ---------------------------------------------------------------------------
  // Snapshot
  // ---------------------------------------------------------------------------

  void _emitState() {
    _snapshot = _buildSnapshot();
    if (!_disposed) _snapshots.add(_snapshot);
  }

  BattleSnapshot _buildSnapshot() {
    final action = _action;
    return BattleSnapshot(
      phase: _phase,
      turn: action?.turn ?? _lastTurn,
      moveKind: action?.kind,
      moveId: action?.move?.id,
      moveLabel: action?.move?.label,
      actor: action?.actor ?? -1,
      criticalOpportunity: action?.turn == BattleTurn.player && action?.kind == MoveKind.critical,
      playerHp: _playerHp,
      playerMaxHp: setup.playerMaxHp,
      enemies: [
        for (var i = 0; i < _enemies.length; i++)
          EnemySnapshot(
            index: i,
            id: _enemies[i].definition.id,
            name: _enemies[i].definition.name,
            hp: _enemies[i].hp,
            maxHp: _enemies[i].maxHp,
            shield: _enemies[i].shielded
                ? ShieldSnapshot(strength: _enemies[i].shieldStrength, remaining: _enemies[i].shieldRemaining)
                : null,
            staggered: _enemies[i].staggered,
            intent: _enemies[i].intent?.kind,
            intentMoveId: _enemies[i].intent?.move?.id,
            poisonTicks: _enemies[i].poisonTicks,
          ),
      ],
      targetIndex: _target,
      challenge: action?.task ?? (action != null && action.tasks.isNotEmpty ? action.tasks.last : null),
      taskIndex: action == null ? 0 : min(action.index, max(0, action.tasks.length - 1)),
      taskCount: action?.tasks.length ?? 0,
      taskResults: List.unmodifiable(action?.results ?? const <bool>[]),
      dimmedOptionIds: Set.unmodifiable(_dimmed),
      hiddenOptionIds: Set.unmodifiable(_hidden),
      revealedLetter: _revealedLetter,
      placedOptionIds: List.unmodifiable(_placed),
      hintedOptionId: _hintedOption,
      eatenOptionId: _eatenOption,
      matchedOptionIds: Set.unmodifiable(_matched),
      selectedOptionId: _selected,
      missedOptionId: _missed,
      timerTotal: _timerTotal,
      timerFrozen: _freezeRemaining > 0,
      combo: _combo,
      maxCombo: _maxCombo,
      wordFlow: _flowActive,
      specialCharge: _maxSpecial == 0 ? 0 : _special / _maxSpecial,
      specialReady: canActivateSpecial,
      specialUnlocked: setup.access.special,
      playerLocked: _lockedTurns > 0,
      stageIndex: _stageIndex,
      stageCount: setup.battle.stages.length,
      stageName: _stage.name,
      enraged: _stage.enraged,
      buffs: {for (final buff in BuffType.values) buff: buffCount(buff)},
      usedThisChallenge: Set.unmodifiable(_usedThisChallenge),
      secondChanceArmed: _secondChanceArmed,
      wardCharges: _wardCharges,
      knownSpells: knownSpells,
      mana: _special,
      manaMax: _maxSpecial,
      spells: [
        for (final id in _spells)
          if (config.move(id) case final move?)
            SpellState(
              id: id,
              manaCost: move.manaCost,
              cooldownLeft: cooldownLeft(id),
              castable: canCast(id),
              block: spellBlock(id),
              manaMissing: max(0, move.manaCost - _special),
            ),
      ],
      playerPoisonTicks: _playerPoisonTicks,
      score: _score,
      lastOutcome: _lastOutcome,
      lastTaskSuccess: _lastTaskSuccess,
      pickedOptionId: _lastPicked,
      coachKey: _coachKey,
    );
  }
}
