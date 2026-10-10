/// Cosmetic identity of the player's apprentice. Gameplay never reads this:
/// both apprentices share hitbox, timing, damage, abilities and progression.
/// Future cosmetics (robes, accessories) extend this definition.
class PlayerCharacterDefinition {
  final String id;

  /// English label key, localised in the UI.
  final String name;

  /// Renderer skin id (see `game/entities/apprentice_skin.dart`).
  final String skin;
  final bool feminine;
  final int robeColor;
  final int trimColor;
  final int hairColor;
  final int skinColor;

  const PlayerCharacterDefinition({
    required this.id,
    required this.name,
    required this.skin,
    required this.feminine,
    required this.robeColor,
    required this.trimColor,
    required this.hairColor,
    required this.skinColor,
  });

  static const maleApprentice = PlayerCharacterDefinition(
    id: 'male_apprentice',
    name: 'Male Apprentice',
    skin: 'apprentice',
    feminine: false,
    robeColor: 0xFF2F7D5B,
    trimColor: 0xFFF2C86B,
    hairColor: 0xFF3B2416,
    skinColor: 0xFFF1C9A5,
  );

  static const femaleApprentice = PlayerCharacterDefinition(
    id: 'female_apprentice',
    name: 'Female Apprentice',
    skin: 'apprentice',
    feminine: true,
    robeColor: 0xFF2E7A6E,
    trimColor: 0xFFFFB86B,
    hairColor: 0xFF8A4A2A,
    skinColor: 0xFFE8B993,
  );

  static const all = [maleApprentice, femaleApprentice];

  static PlayerCharacterDefinition byId(String? id) =>
      all.firstWhere((character) => character.id == id, orElse: () => maleApprentice);

  /// Visual growth stage (0 beginner … 3 adept) from the player's level.
  /// Changes only small details: robe trim, book, rune glow, circlet.
  static int tierForLevel(int level) {
    if (level >= 13) return 3;
    if (level >= 8) return 2;
    if (level >= 4) return 1;
    return 0;
  }
}
