import 'package:equatable/equatable.dart';

import '../language/distractor_style.dart';
import 'json_utils.dart';

/// Broad behaviour family. Visual skins are chosen separately (see
/// [EnemyVisual.skin]) so a palette swap can create a new enemy without code.
enum EnemyArchetype {
  goblin,
  stoneGuardian,
  rogueMage,
  wordEater,
  mimic,
  wisp,
  eliteMage,
  brute,
  boss;

  static EnemyArchetype parse(Object? raw) => EnemyArchetype.values
      .firstWhere((value) => value.name == raw, orElse: () => EnemyArchetype.goblin);
}

/// Special behaviours that change how a battle plays.
enum EnemyTrait {
  /// Eats one placed word while the player builds an incantation.
  wordEater,

  /// Uses look-alike answer choices.
  mimic;

  static EnemyTrait? tryParse(Object? raw) {
    for (final value in EnemyTrait.values) {
      if (value.name == raw) return value;
    }
    return null;
  }
}

class EnemyVisual extends Equatable {
  /// Rendering skin id (goblin, golem, mage, blob, chest, wisp, knight, treant, lich).
  final String skin;
  final int primaryColor;
  final int secondaryColor;
  final int accentColor;
  final double scale;

  /// Optional sprite asset key; when present it replaces the procedural skin.
  final String? sprite;

  const EnemyVisual({
    required this.skin,
    required this.primaryColor,
    required this.secondaryColor,
    required this.accentColor,
    this.scale = 1,
    this.sprite,
  });

  static int parseColor(Object? raw, int fallback) {
    if (raw is! String) return fallback;
    final hex = raw.replaceAll('#', '');
    final value = int.tryParse(hex.length == 6 ? 'FF$hex' : hex, radix: 16);
    return value ?? fallback;
  }

  @override
  List<Object?> get props => [skin, primaryColor, secondaryColor, accentColor, scale, sprite];
}

class EnemyDefinition extends Equatable {
  final String id;
  final String name;
  final String? title;
  final EnemyArchetype archetype;
  final EnemyVisual visual;
  final int maxHp;
  final int attack;

  /// Animation speed multiplier; >1 feels quicker and more aggressive.
  final double tempo;
  final DistractorStyle distractorStyle;
  final Set<EnemyTrait> traits;

  /// Per-enemy overrides of the archetype behaviour (see combat.json).
  final Map<String, dynamic> behaviour;

  const EnemyDefinition({
    required this.id,
    required this.name,
    this.title,
    required this.archetype,
    required this.visual,
    required this.maxHp,
    required this.attack,
    this.tempo = 1,
    this.distractorStyle = DistractorStyle.standard,
    this.traits = const {},
    this.behaviour = const {},
  });

  bool get isBoss => archetype == EnemyArchetype.boss;
  bool has(EnemyTrait trait) => traits.contains(trait);

  factory EnemyDefinition.fromJson(Map<String, dynamic> json) {
    final palette = JsonRead.object(json, 'palette');
    return EnemyDefinition(
      id: JsonRead.string(json, 'id'),
      name: JsonRead.string(json, 'name'),
      title: JsonRead.optString(json, 'title'),
      archetype: EnemyArchetype.parse(json['archetype']),
      visual: EnemyVisual(
        skin: JsonRead.optString(json, 'skin') ?? 'goblin',
        primaryColor: EnemyVisual.parseColor(palette['primary'], 0xFF7CC05A),
        secondaryColor: EnemyVisual.parseColor(palette['secondary'], 0xFF3E6B2C),
        accentColor: EnemyVisual.parseColor(palette['accent'], 0xFFF2C94C),
        scale: JsonRead.number(json, 'scale', fallback: 1),
        sprite: JsonRead.optString(json, 'sprite'),
      ),
      maxHp: JsonRead.integer(json, 'maxHp'),
      attack: JsonRead.integer(json, 'attack'),
      tempo: JsonRead.number(json, 'tempo', fallback: 1),
      distractorStyle: DistractorStyle.parse(json['distractorStyle']),
      traits: JsonRead.strings(json, 'traits').map(EnemyTrait.tryParse).whereType<EnemyTrait>().toSet(),
      behaviour: JsonRead.object(json, 'behaviour'),
    );
  }

  @override
  List<Object?> get props => [id];
}
