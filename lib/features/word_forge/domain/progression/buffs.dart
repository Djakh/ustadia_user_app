/// Language-focused assists. Each works in every challenge type where it makes
/// sense (see `BattleEngine.canUseBuff`).
enum BuffType {
  /// Dims one incorrect option (or highlights the next word in a sentence).
  hint,

  /// Shows the first letter of the answer (or places the next word).
  reveal,

  /// Stops the challenge timer for a few seconds.
  timeFreeze,

  /// Adds seconds to the challenge timer.
  extraTime,

  /// The next wrong answer is forgiven.
  secondChance,

  /// Removes one wrong option now and in the next two challenges.
  runeSense,

  /// Blocks the damage of the next wrong answer.
  shield;

  static BuffType? tryParse(String raw) {
    for (final type in BuffType.values) {
      if (type.name == raw) return type;
    }
    return null;
  }

  static Map<BuffType, int> parseMap(Object? json) {
    if (json is! Map) return const {};
    final result = <BuffType, int>{};
    for (final entry in json.entries) {
      final type = tryParse(entry.key.toString());
      final value = entry.value;
      if (type != null && value is num && value > 0) result[type] = value.toInt();
    }
    return result;
  }

  static Map<String, int> encodeMap(Map<BuffType, int> map) => {
        for (final entry in map.entries)
          if (entry.value > 0) entry.key.name: entry.value,
      };
}

/// Starting inventory for a brand new save.
const Map<BuffType, int> starterBuffs = {BuffType.hint: 2, BuffType.shield: 1, BuffType.extraTime: 1};

/// Upper bound per buff so inventories never balloon.
const int maxBuffStack = 9;

Map<BuffType, int> addBuffs(Map<BuffType, int> base, Map<BuffType, int> delta, {int sign = 1}) {
  final result = Map<BuffType, int>.of(base);
  for (final entry in delta.entries) {
    final next = (result[entry.key] ?? 0) + entry.value * sign;
    result[entry.key] = next.clamp(0, maxBuffStack);
  }
  result.removeWhere((_, value) => value <= 0);
  return result;
}
