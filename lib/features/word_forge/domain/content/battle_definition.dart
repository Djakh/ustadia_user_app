import 'package:equatable/equatable.dart';

import '../progression/buffs.dart';
import 'difficulty.dart';
import 'json_utils.dart';

/// One enemy slot in an encounter (two at most).
class BattleEnemy extends Equatable {
  final String enemyId;

  /// Optional HP override (two-enemy fights use lighter enemies).
  final int? hp;

  const BattleEnemy(this.enemyId, {this.hp});

  factory BattleEnemy.fromJson(Object? json) {
    if (json is String) return BattleEnemy(json);
    if (json is Map) {
      final map = Map<String, dynamic>.from(json);
      return BattleEnemy(JsonRead.string(map, 'id'), hp: (map['hp'] as num?)?.toInt());
    }
    throw FormatException('Invalid enemy slot: $json');
  }

  @override
  List<Object?> get props => [enemyId, hp];
}

/// A boss phase. Phases change behaviour, never the rules: they reuse the
/// same Normal / Critical / Special moves with different frequency.
class BattleStage extends Equatable {
  final String? name;

  /// Move to the next stage once the main enemy's HP fraction is at or below this.
  final double? untilHpFraction;
  final bool enraged;
  final double criticalMultiplier;
  final double specialMultiplier;

  /// Move the enemy performs as soon as the phase starts (signature Special).
  final String? opensWith;

  /// Fills the player's Special meter when the phase starts (finishing phase).
  final bool grantSpecial;

  const BattleStage({
    this.name,
    this.untilHpFraction,
    this.enraged = false,
    this.criticalMultiplier = 1,
    this.specialMultiplier = 1,
    this.opensWith,
    this.grantSpecial = false,
  });

  factory BattleStage.fromJson(Map<String, dynamic> json) => BattleStage(
        name: JsonRead.optString(json, 'name'),
        untilHpFraction: (json['untilHp'] as num?)?.toDouble(),
        enraged: JsonRead.boolean(json, 'enraged'),
        criticalMultiplier: JsonRead.number(json, 'critical', fallback: 1),
        specialMultiplier: JsonRead.number(json, 'special', fallback: 1),
        opensWith: JsonRead.optString(json, 'opensWith'),
        grantSpecial: JsonRead.boolean(json, 'grantSpecial') || json['finisher'] != null,
      );

  @override
  List<Object?> get props =>
      [name, untilHpFraction, enraged, criticalMultiplier, specialMultiplier, opensWith, grantSpecial];
}

class BattleRewards extends Equatable {
  final int xp;
  final Map<BuffType, int> buffs;

  const BattleRewards({required this.xp, this.buffs = const {}});

  factory BattleRewards.fromJson(Map<String, dynamic> json) => BattleRewards(
      xp: JsonRead.integer(json, 'xp', fallback: 20), buffs: BuffType.parseMap(json['buffs']));

  @override
  List<Object?> get props => [xp, buffs];
}

/// Data-driven description of an encounter. Shared by Sandbox and (later)
/// Story Mode. Turn order and move choice are decided at run time by the
/// `EncounterDirector`, so battles only describe who fights and how phases
/// escalate.
class BattleDefinition extends Equatable {
  static const int maxEnemies = 2;

  final String id;
  final List<BattleEnemy> enemies;
  final DegreeRange degrees;
  final List<BattleStage> stages;
  final BattleRewards rewards;

  const BattleDefinition({
    required this.id,
    required this.enemies,
    required this.degrees,
    this.stages = const [BattleStage()],
    required this.rewards,
  });

  String get enemyId => enemies.first.enemyId;
  bool get isMultiStage => stages.length > 1;
  bool get isMultiEnemy => enemies.length > 1;

  factory BattleDefinition.fromJson(Map<String, dynamic> json) {
    final rawEnemies = json['enemies'];
    final enemies = rawEnemies is List
        ? rawEnemies.map(BattleEnemy.fromJson).toList()
        : [BattleEnemy(JsonRead.string(json, 'enemyId'), hp: (json['enemyHp'] as num?)?.toInt())];
    if (enemies.isEmpty || enemies.length > maxEnemies) {
      throw const FormatException('Battles need 1-2 enemies');
    }
    final stages = JsonRead.objects(json, 'stages').map(BattleStage.fromJson).toList();
    return BattleDefinition(
      id: JsonRead.string(json, 'id'),
      enemies: enemies,
      degrees: DegreeRange.fromJson(json['degree'] ?? 1),
      stages: stages.isEmpty ? const [BattleStage()] : stages,
      rewards: BattleRewards.fromJson(JsonRead.object(json, 'rewards')),
    );
  }

  @override
  List<Object?> get props => [id];
}
