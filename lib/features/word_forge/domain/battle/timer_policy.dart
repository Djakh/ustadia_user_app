import 'dart:math';

import '../language/challenge_type.dart';
import '../language/language_challenge.dart';
import '../progression/word_mastery.dart';
import 'combat_config.dart';

/// Decides how long a timed move lasts. Timers train fast recognition, so the
/// time grows with what the player must actually read: word length, number
/// of options, difficulty and familiarity — never only the region number.
class TimerPolicy {
  final TimerConfigSet config;
  final MasteryCalculator mastery;

  const TimerPolicy(this.config, {this.mastery = const MasteryCalculator()});

  /// Seconds for all [tasks] of a move together; 0 means untimed.
  double secondsFor({
    required TimerUse use,
    required List<LanguageChallenge> tasks,
    required WordStats? Function(String wordId) statsOf,
    double scale = 1,
    int playerLevel = 1,
  }) {
    if (use == TimerUse.none || tasks.isEmpty) return 0;
    var total = 0.0;
    for (final task in tasks) {
      total += _taskSeconds(use, task, statsOf);
    }
    if (use == TimerUse.playerCritical && tasks.length > 1) {
      total = tasks.length * config.rapidPerTask + _readingAllowance(tasks.first);
    }
    // Experienced players read a little faster; never below the floor.
    final experience = playerLevel >= 8 ? 0.95 : 1.0;
    final floor = use == TimerUse.normal ? config.minimumNormalSeconds : config.minimumChoiceSeconds;
    return max(floor, total * scale * experience);
  }

  double _taskSeconds(TimerUse use, LanguageChallenge task, WordStats? Function(String) statsOf) {
    switch (task.inputMode) {
      case ChallengeInputMode.arrange:
        final tokens = task.options.length.toDouble();
        return use == TimerUse.playerCritical
            ? config.playerCriticalSentenceBase + tokens * config.playerCriticalPerToken
            : config.enemySpecialSentenceBase + tokens * config.enemySpecialPerToken;
      case ChallengeInputMode.match:
        return config.playerCriticalMatchBase + task.pairs.length * config.playerCriticalPerPair;
      case ChallengeInputMode.choice:
        if (task.type == ChallengeType.missingRune) {
          return config.runeSeconds + _readingAllowance(task);
        }
        final band = task.degree <= 2 ? 0 : (task.degree == 3 ? 1 : 2);
        final base = switch (use) {
          TimerUse.normal => config.normal[band],
          TimerUse.enemyCritical => config.enemyCritical[band],
          TimerUse.playerCritical => config.rapidPerTask,
          _ => config.enemySpecialPerChoice,
        };
        return base + _readingAllowance(task) + _familiarity(task, statsOf);
    }
  }

  /// Extra time for long words / many letters on screen.
  double _readingAllowance(LanguageChallenge task) {
    final characters = task.prompt.length + task.options.fold<int>(0, (sum, option) => sum + option.text.length);
    final extra = max(0, characters - config.comfortableChars);
    return extra * config.readingPerExtraChar + (task.degree >= 4 ? config.hardWordBonus : 0);
  }

  double _familiarity(LanguageChallenge task, WordStats? Function(String) statsOf) {
    final focus = task.focusWordId;
    if (focus == null) return 0;
    final level = mastery.level(statsOf(focus));
    if (level <= 1) return config.unfamiliarBonus;
    if (level >= 4) return -config.familiarDiscount;
    return 0;
  }
}
