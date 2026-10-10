import 'package:equatable/equatable.dart';

import 'challenge_type.dart';

class ChallengeOption extends Equatable {
  final String id;
  final String text;

  const ChallengeOption({required this.id, required this.text});

  @override
  List<Object?> get props => [id, text];
}

/// A self-contained language task. Mechanics receive only this object and
/// never look up vocabulary themselves, so any content can drive any mechanic.
///
/// * choice challenges: [options] contains the shuffled answer and distractors.
/// * arrange challenges: [options] are the shuffled sentence tokens and
///   [acceptedAnswers] holds every valid order (normalised, space-joined).
class LanguageChallenge extends Equatable {
  final String id;
  final ChallengeType type;

  /// The word on the enemy spell / shield, or the sentence with a blank.
  final String prompt;
  final String correctAnswer;
  final List<ChallengeOption> options;
  final List<String> acceptedAnswers;
  final int degree;

  /// Every vocabulary entry involved (mastery is recorded for each).
  final List<String> wordIds;

  /// The main word being practised (shown in discovery / Spellbook).
  final String? focusWordId;

  /// Extra display data: `definition`, `terminator`, `topic`, `templateId`.
  final Map<String, String> metadata;

  /// Match challenges: left option id -> right option id.
  final Map<String, String> pairs;

  const LanguageChallenge({
    required this.id,
    required this.type,
    required this.prompt,
    required this.correctAnswer,
    required this.options,
    this.acceptedAnswers = const [],
    required this.degree,
    this.wordIds = const [],
    this.focusWordId,
    this.metadata = const {},
    this.pairs = const {},
  });

  LanguageChallenge withId(String id) => LanguageChallenge(
        id: id,
        type: type,
        prompt: prompt,
        correctAnswer: correctAnswer,
        options: options,
        acceptedAnswers: acceptedAnswers,
        degree: degree,
        wordIds: wordIds,
        focusWordId: focusWordId,
        metadata: metadata,
        pairs: pairs,
      );

  bool isLeft(String optionId) => pairs.containsKey(optionId);

  ChallengeInputMode get inputMode => type.inputMode;

  ChallengeOption? option(String id) {
    for (final option in options) {
      if (option.id == id) return option;
    }
    return null;
  }

  /// Stable key used to avoid repeating the same template across battles.
  String get contentKey => metadata['templateId'] ?? '${type.name}:$prompt';

  @override
  List<Object?> get props => [id, type, prompt, correctAnswer, options, acceptedAnswers, pairs];
}
