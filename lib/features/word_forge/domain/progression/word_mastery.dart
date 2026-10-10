import 'package:equatable/equatable.dart';

import '../content/json_utils.dart';
import '../language/challenge_type.dart';

/// Learning statistics for one word. Stored in the save file.
class WordStats extends Equatable {
  static const int recentWindow = 6;

  final int seen;
  final int correct;
  final int wrong;

  /// Most recent results, oldest first (true = correct).
  final List<bool> recent;
  final int firstSeenBattle;
  final int lastSeenBattle;

  /// Challenge types this word has been answered correctly in.
  final Set<ChallengeType> correctTypes;
  final int totalResponseMs;
  final int timedAnswers;

  const WordStats({
    this.seen = 0,
    this.correct = 0,
    this.wrong = 0,
    this.recent = const [],
    this.firstSeenBattle = 0,
    this.lastSeenBattle = 0,
    this.correctTypes = const {},
    this.totalResponseMs = 0,
    this.timedAnswers = 0,
  });

  bool get lastWasWrong => recent.isNotEmpty && !recent.last;

  double get recentAccuracy =>
      recent.isEmpty ? 0 : recent.where((result) => result).length / recent.length;

  double? get averageResponseSeconds =>
      timedAnswers == 0 ? null : totalResponseMs / timedAnswers / 1000;

  WordStats record({
    required bool isCorrect,
    required ChallengeType type,
    required int battleIndex,
    int? responseMs,
  }) {
    final nextRecent = [...recent, isCorrect];
    if (nextRecent.length > recentWindow) nextRecent.removeAt(0);
    return WordStats(
      seen: seen + 1,
      correct: correct + (isCorrect ? 1 : 0),
      wrong: wrong + (isCorrect ? 0 : 1),
      recent: nextRecent,
      firstSeenBattle: seen == 0 ? battleIndex : firstSeenBattle,
      lastSeenBattle: battleIndex,
      correctTypes: isCorrect ? {...correctTypes, type} : correctTypes,
      totalResponseMs: totalResponseMs + (responseMs ?? 0),
      timedAnswers: timedAnswers + (responseMs == null ? 0 : 1),
    );
  }

  Map<String, dynamic> toJson() => {
        's': seen,
        'c': correct,
        'w': wrong,
        'r': recent.map((result) => result ? 1 : 0).join(),
        'f': firstSeenBattle,
        'l': lastSeenBattle,
        't': correctTypes.map((type) => type.name).toList(),
        'ms': totalResponseMs,
        'n': timedAnswers,
      };

  factory WordStats.fromJson(Map<String, dynamic> json) => WordStats(
        seen: JsonRead.integer(json, 's', fallback: 0),
        correct: JsonRead.integer(json, 'c', fallback: 0),
        wrong: JsonRead.integer(json, 'w', fallback: 0),
        recent: (json['r'] is String ? json['r'] as String : '')
            .split('')
            .map((char) => char == '1')
            .toList(),
        firstSeenBattle: JsonRead.integer(json, 'f', fallback: 0),
        lastSeenBattle: JsonRead.integer(json, 'l', fallback: 0),
        correctTypes:
            JsonRead.strings(json, 't').map(ChallengeType.tryParse).whereType<ChallengeType>().toSet(),
        totalResponseMs: JsonRead.integer(json, 'ms', fallback: 0),
        timedAnswers: JsonRead.integer(json, 'n', fallback: 0),
      );

  @override
  List<Object?> get props => [seen, correct, wrong, recent, lastSeenBattle, correctTypes];
}

/// Five-star mastery, derived from stats (never stored, so tuning the rules
/// re-grades every word without a migration).
///
/// 0 undiscovered · 1 discovered · 2 recognised · 3 reliable · 4 strong · 5 mastered
class MasteryCalculator {
  const MasteryCalculator();

  static const int maxLevel = 5;

  int level(WordStats? stats) {
    if (stats == null || stats.seen == 0) return 0;
    final accuracy = stats.recentAccuracy;
    final variety = stats.correctTypes.length;
    var level = 1;
    if (stats.correct >= 2) level = 2;
    if (level == 2 && stats.correct >= 4 && accuracy >= 0.6) level = 3;
    if (level == 3 && stats.correct >= 7 && accuracy >= 0.75 && variety >= 2) level = 4;
    if (level == 4 && stats.correct >= 10 && accuracy >= 0.85 && !stats.lastWasWrong) level = 5;
    return level;
  }
}
