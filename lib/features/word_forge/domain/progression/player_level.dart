import 'package:equatable/equatable.dart';

/// Level is derived from total XP so the two can never disagree.
/// XP needed for the next level grows gently: 80, 120, 160, 200 ...
class PlayerLevel extends Equatable {
  static const int baseXp = 80;
  static const int stepXp = 40;
  static const int maxLevel = 60;

  final int level;
  final int xpIntoLevel;
  final int xpForNextLevel;

  const PlayerLevel({required this.level, required this.xpIntoLevel, required this.xpForNextLevel});

  static int xpToAdvanceFrom(int level) => baseXp + (level - 1) * stepXp;

  factory PlayerLevel.fromXp(int totalXp) {
    var level = 1;
    var remaining = totalXp < 0 ? 0 : totalXp;
    while (level < maxLevel && remaining >= xpToAdvanceFrom(level)) {
      remaining -= xpToAdvanceFrom(level);
      level++;
    }
    return PlayerLevel(level: level, xpIntoLevel: remaining, xpForNextLevel: xpToAdvanceFrom(level));
  }

  double get progress => xpForNextLevel == 0 ? 1 : (xpIntoLevel / xpForNextLevel).clamp(0.0, 1.0);

  @override
  List<Object?> get props => [level, xpIntoLevel, xpForNextLevel];
}
