/// A deliberately tiny set of optional upgrades, bought with skill points
/// earned by levelling up. Each is capped at a few levels.
enum UpgradeType {
  /// +1 second per level on timed challenges.
  focus(maxLevel: 3),

  /// Level 1: hints also reveal the first letter. Level 2: hints dim two options.
  insight(maxLevel: 2),

  /// A free protective ward every (4 - level) battles.
  protection(maxLevel: 3),

  /// +5% attack per level while the combo is 4 or higher.
  momentum(maxLevel: 3);

  final int maxLevel;

  const UpgradeType({required this.maxLevel});

  static UpgradeType? tryParse(String raw) {
    for (final type in UpgradeType.values) {
      if (type.name == raw) return type;
    }
    return null;
  }
}

class UpgradeLevels {
  final Map<UpgradeType, int> levels;

  const UpgradeLevels([this.levels = const {}]);

  int operator [](UpgradeType type) => (levels[type] ?? 0).clamp(0, type.maxLevel);

  double get focusSeconds => this[UpgradeType.focus].toDouble();
  bool get hintRevealsLetter => this[UpgradeType.insight] >= 1;
  int get hintEliminates => this[UpgradeType.insight] >= 2 ? 2 : 1;
  double get momentumBonus => this[UpgradeType.momentum] * 0.05;

  /// Battles between free wards; null when the upgrade is not owned.
  int? get protectionInterval {
    final level = this[UpgradeType.protection];
    return level == 0 ? null : 4 - level;
  }

  int get spentPoints => UpgradeType.values.fold(0, (sum, type) => sum + this[type]);

  UpgradeLevels increment(UpgradeType type) =>
      UpgradeLevels({...levels, type: (this[type] + 1).clamp(0, type.maxLevel)});

  Map<String, int> toJson() => {
        for (final type in UpgradeType.values)
          if (this[type] > 0) type.name: this[type],
      };

  factory UpgradeLevels.fromJson(Map<String, int> json) => UpgradeLevels({
        for (final entry in json.entries)
          if (UpgradeType.tryParse(entry.key) case final type?) type: entry.value,
      });
}
