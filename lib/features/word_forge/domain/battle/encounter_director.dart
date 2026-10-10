import 'dart:math';

import '../content/battle_definition.dart';
import 'combat_config.dart';

/// What an enemy will do on its turn. Planned one turn ahead and shown as an
/// intent icon, so Criticals and Specials are always telegraphed.
class EnemyMove {
  final MoveKind kind;
  final MoveDefinition? move;

  /// Shield moves: index of the enemy that receives the barrier.
  final int? shieldTarget;

  const EnemyMove._(this.kind, this.move, this.shieldTarget);

  static const normal = EnemyMove._(MoveKind.normal, null, null);
  static const critical = EnemyMove._(MoveKind.critical, null, null);

  factory EnemyMove.special(MoveDefinition move, {int? shieldTarget}) =>
      EnemyMove._(MoveKind.special, move, shieldTarget);

  @override
  String toString() => move == null ? kind.name : '${kind.name}:${move!.id}';
}

/// Read-only view of an enemy, supplied by the engine.
class EnemyView {
  final int index;
  final bool alive;
  final bool shielded;
  final double hpFraction;
  final EnemyBehaviour behaviour;

  const EnemyView({
    required this.index,
    required this.alive,
    required this.shielded,
    required this.hpFraction,
    required this.behaviour,
  });
}

/// Battle pacing: decides who acts, when Criticals happen, which Specials are
/// used, and enforces fairness so the rhythm stays "mostly normal with
/// occasional highlights". Pure and seeded — fully deterministic in tests.
///
/// Rules:
/// * the first player and enemy turns are always Normal (teaching moment);
/// * after any Critical, [PacingConfig.criticalCooldownTurns] turns pass
///   before another random Critical;
/// * an enemy needs [PacingConfig.minNormalEnemyTurns] Normal enemy turns
///   between two non-Normal moves (no Critical-Special-Critical chains);
/// * each enemy waits [PacingConfig.enemySpecialCooldown] of its own turns
///   between Specials;
/// * in two-enemy fights only one enemy acts per enemy turn, alternating;
/// * boss phases may force a signature Special, bypassing cooldowns.
class EncounterDirector {
  final CombatConfig config;
  final Random random;
  final MechanicAccess access;

  int _turnsSinceCritical = 0;
  int _normalEnemyTurnsSinceEvent = 0;
  int _enemyTurns = 0;
  int _playerTurns = 0;
  final Map<int, int> _ownTurnsSinceSpecial = {};
  String? _forced;
  int _lastActor = -1;
  String? _lastPlayerCritical;

  EncounterDirector({required this.config, required this.random, required this.access}) {
    _turnsSinceCritical = config.pacing.criticalCooldownTurns;
  }

  PacingConfig get _pacing => config.pacing;

  // --- turns -----------------------------------------------------------------

  void notePlayerTurn() {
    _playerTurns++;
    _turnsSinceCritical++;
  }

  /// Whether a successful Normal Attack earns a Critical Opportunity.
  bool rollPlayerCritical({required int combo, required BattleStage stage}) {
    if (!access.critical || _playerTurns < 2) return false;
    if (_turnsSinceCritical < _pacing.criticalCooldownTurns) return false;
    final chance = min(_pacing.playerCriticalCap,
            _pacing.playerCriticalChance + combo * _pacing.comboCriticalBonus) *
        stage.criticalMultiplier;
    if (random.nextDouble() >= chance) return false;
    _turnsSinceCritical = 0;
    return true;
  }

  MoveDefinition pickPlayerCritical() {
    final pool = [
      for (final id in config.playerCriticals)
        if (config.move(id) case final move?) move,
    ];
    final candidates = pool.length > 1 ? pool.where((move) => move.id != _lastPlayerCritical).toList() : pool;
    final total = candidates.fold<double>(0, (sum, move) => sum + move.weight);
    var roll = random.nextDouble() * total;
    for (final move in candidates) {
      roll -= move.weight;
      if (roll <= 0) {
        _lastPlayerCritical = move.id;
        return move;
      }
    }
    _lastPlayerCritical = candidates.last.id;
    return candidates.last;
  }

  /// Next enemy to act: alternate between living enemies.
  int? nextActor(List<EnemyView> enemies) {
    final alive = [for (final enemy in enemies) if (enemy.alive) enemy.index];
    if (alive.isEmpty) return null;
    for (final index in alive) {
      if (index > _lastActor) return index;
    }
    return alive.first;
  }

  /// Forces the next planned enemy move (boss phase signature).
  void force(String moveId) => _forced = moveId;

  /// Plans [actor]'s next move. Called one turn ahead so it can be shown.
  EnemyMove plan(int actor, List<EnemyView> enemies, BattleStage stage) {
    final forced = _forced == null ? null : config.move(_forced!);
    if (forced != null) {
      _forced = null;
      return _validated(EnemyMove.special(forced, shieldTarget: _shieldTarget(actor, enemies)), enemies) ??
          EnemyMove.normal;
    }
    if (_enemyTurns == 0) return EnemyMove.normal;
    if (_normalEnemyTurnsSinceEvent < _pacing.minNormalEnemyTurns) return EnemyMove.normal;

    final behaviour = enemies[actor].behaviour;
    final specials = _availableSpecials(actor, enemies);
    final specialChance = specials.isEmpty ? 0.0 : behaviour.specialChance * stage.specialMultiplier;
    final criticalOk = access.critical && _turnsSinceCritical >= _pacing.criticalCooldownTurns;
    final criticalChance = criticalOk ? behaviour.criticalChance * stage.criticalMultiplier : 0.0;

    final roll = random.nextDouble();
    if (roll < specialChance) {
      final move = _weighted(specials);
      return EnemyMove.special(move, shieldTarget: move.effect == MoveEffect.shield ? _shieldTarget(actor, enemies) : null);
    }
    if (roll < specialChance + criticalChance) return EnemyMove.critical;
    return EnemyMove.normal;
  }

  /// Re-checks a planned move right before it executes (state may change).
  EnemyMove validate(EnemyMove move, List<EnemyView> enemies) => _validated(move, enemies) ?? EnemyMove.normal;

  EnemyMove? _validated(EnemyMove move, List<EnemyView> enemies) {
    final definition = move.move;
    if (definition == null || definition.effect != MoveEffect.shield) return move;
    final target = move.shieldTarget;
    if (target == null || !enemies[target].alive || enemies[target].shielded) return null;
    return move;
  }

  /// Records an executed move for cooldown bookkeeping.
  void commit(int actor, EnemyMove move) {
    _enemyTurns++;
    _lastActor = actor;
    _turnsSinceCritical++;
    _ownTurnsSinceSpecial[actor] = (_ownTurnsSinceSpecial[actor] ?? _pacing.enemySpecialCooldown) + 1;
    switch (move.kind) {
      case MoveKind.normal:
        _normalEnemyTurnsSinceEvent++;
      case MoveKind.critical:
        _normalEnemyTurnsSinceEvent = 0;
        _turnsSinceCritical = 0;
      case MoveKind.special:
        _normalEnemyTurnsSinceEvent = 0;
        _ownTurnsSinceSpecial[actor] = 0;
    }
  }

  /// Turn skipped (staggered / no actor): still counts towards cooldowns.
  void skipEnemyTurn() {
    _enemyTurns++;
    _turnsSinceCritical++;
    _normalEnemyTurnsSinceEvent++;
  }

  List<MoveDefinition> _availableSpecials(int actor, List<EnemyView> enemies) {
    final sinceSpecial = _ownTurnsSinceSpecial[actor] ?? _pacing.enemySpecialCooldown;
    if (sinceSpecial < _pacing.enemySpecialCooldown) return const [];
    final result = <MoveDefinition>[];
    for (final id in enemies[actor].behaviour.specials) {
      final move = config.move(id);
      if (move == null) continue;
      if (move.effect == MoveEffect.shield) {
        if (!access.protection || _shieldTarget(actor, enemies) == null) continue;
      } else if (!access.enemySpecials) {
        continue;
      }
      result.add(move);
    }
    return result;
  }

  /// Guardians protect a hurt ally first; everyone else protects themselves.
  int? _shieldTarget(int actor, List<EnemyView> enemies) {
    final self = enemies[actor];
    if (self.behaviour.role == EnemyRole.guardian) {
      final allies = [
        for (final enemy in enemies)
          if (enemy.index != actor && enemy.alive && !enemy.shielded) enemy,
      ]..sort((a, b) => a.hpFraction.compareTo(b.hpFraction));
      if (allies.isNotEmpty) return allies.first.index;
    }
    return self.alive && !self.shielded ? actor : null;
  }

  MoveDefinition _weighted(List<MoveDefinition> moves) {
    final total = moves.fold<double>(0, (sum, move) => sum + move.weight);
    var roll = random.nextDouble() * total;
    for (final move in moves) {
      roll -= move.weight;
      if (roll <= 0) return move;
    }
    return moves.last;
  }
}
