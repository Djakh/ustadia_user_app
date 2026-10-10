import 'dart:math';

import '../battle/battle_models.dart';
import '../battle/combat_config.dart';
import '../content/battle_definition.dart';
import '../content/enemy_definition.dart';

/// Three visible objectives, one star each, so the player always knows why
/// a star was missed:
/// * ★ Victory;
/// * ★ Accuracy: first-try correct answers at or above [accuracyForStar];
/// * ★ Efficiency: attack turns within the encounter's turn budget.
///
/// The budget comes from the enemies themselves (HP, stone skin, shields,
/// phases), so a durable golem naturally allows a longer fight than a goblin.
class StarRating {
  final double accuracyForStar;

  /// Expected Normal-attack damage per attack turn for a competent player
  /// (Normal hits plus the Criticals and Specials they earn).
  final double damagePerTurn;

  const StarRating({this.accuracyForStar = 0.8, this.damagePerTurn = 30});

  bool accuracyStar(BattleResult result) => result.accuracy >= accuracyForStar;

  bool efficiencyStar(BattleResult result, int turnBudget) => result.attackTurns <= turnBudget;

  int starsFor(BattleResult result, {required int turnBudget}) {
    if (!result.victory) return 0;
    return 1 + (accuracyStar(result) ? 1 : 0) + (efficiencyStar(result, turnBudget) ? 1 : 0);
  }

  /// Attack turns a good player should need for [battle].
  int turnBudget({
    required BattleDefinition battle,
    required List<EnemyDefinition> enemies,
    required List<int> enemyHp,
    required CombatConfig config,
  }) {
    var effectiveHp = 0.0;
    var shields = false;
    for (var i = 0; i < enemies.length; i++) {
      final behaviour = config.behaviourFor(enemies[i].archetype.name).merge(enemies[i].behaviour);
      final hp = i < enemyHp.length ? enemyHp[i] : enemies[i].maxHp;
      effectiveHp += hp * (1 + behaviour.armor);
      shields |= behaviour.specials.any((id) => config.move(id)?.effect == MoveEffect.shield) ||
          battle.stages.any((stage) => config.move(stage.opensWith ?? '')?.effect == MoveEffect.shield);
    }
    final base = (effectiveHp / damagePerTurn).ceil();
    return max(2, base + 1 + (battle.stages.length - 1) + (shields ? 1 : 0) + (enemies.length > 1 ? 1 : 0));
  }
}
