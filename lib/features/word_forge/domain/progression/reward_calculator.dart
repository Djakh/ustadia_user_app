import '../battle/battle_models.dart';
import '../content/battle_definition.dart';
import '../content/region_definition.dart';
import 'buffs.dart';

class BattleRewardGrant {
  final int xp;
  final Map<BuffType, int> buffs;

  const BattleRewardGrant({required this.xp, this.buffs = const {}});
}

/// Keeps rewards simple and farm-resistant:
/// * first clear pays full XP plus the battle's buff rewards;
/// * reaching three stars for the first time pays a small bonus;
/// * replays pay reduced XP and no buffs;
/// * losing still pays a little XP — the player practised English.
class RewardCalculator {
  final double replayXpFactor;
  final int defeatXp;

  const RewardCalculator({this.replayXpFactor = 0.4, this.defeatXp = 5});

  static const Map<int, double> _starMultiplier = {1: 1.0, 2: 1.25, 3: 1.5};

  BattleRewardGrant forBattle({
    required BattleDefinition battle,
    required MapNodeType nodeType,
    required BattleResult result,
    required int stars,
    required bool firstClear,
    required int previousBestStars,
  }) {
    if (!result.victory) return BattleRewardGrant(xp: result.abandoned ? 0 : defeatXp);

    final base = battle.rewards.xp * (_starMultiplier[stars] ?? 1);
    final comboBonus = result.maxCombo >= 10 ? 10 : (result.maxCombo >= 5 ? 5 : 0);
    final xp = ((base + comboBonus) * (firstClear ? 1 : replayXpFactor)).round();

    var buffs = <BuffType, int>{};
    if (firstClear) buffs = addBuffs(buffs, battle.rewards.buffs);
    if (stars == 3 && previousBestStars < 3) {
      buffs = addBuffs(buffs, {_threeStarBonus(nodeType): 1});
    }
    return BattleRewardGrant(xp: xp, buffs: buffs);
  }

  BuffType _threeStarBonus(MapNodeType type) => switch (type) {
        MapNodeType.boss || MapNodeType.miniBoss => BuffType.timeFreeze,
        MapNodeType.elite => BuffType.secondChance,
        _ => BuffType.hint,
      };
}
