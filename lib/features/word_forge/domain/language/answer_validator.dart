import 'language_challenge.dart';
import 'text_normalizer.dart';

/// Decides whether an answer is correct. Pure and deterministic.
class AnswerValidator {
  const AnswerValidator();

  bool isCorrectChoice(LanguageChallenge challenge, String optionId) {
    final option = challenge.option(optionId);
    if (option == null) return false;
    return TextNormalizer.normalize(option.text) ==
        TextNormalizer.normalize(challenge.correctAnswer);
  }

  bool isCorrectPair(LanguageChallenge challenge, String first, String second) =>
      challenge.pairs[first] == second || challenge.pairs[second] == first;

  String? correctOptionId(LanguageChallenge challenge) {
    final answer = TextNormalizer.normalize(challenge.correctAnswer);
    for (final option in challenge.options) {
      if (TextNormalizer.normalize(option.text) == answer) return option.id;
    }
    return null;
  }

  List<String> _tokens(LanguageChallenge challenge, List<String> optionIds) => [
        for (final id in optionIds) TextNormalizer.normalize(challenge.option(id)?.text ?? ''),
      ];

  bool isCorrectArrangement(LanguageChallenge challenge, List<String> optionIds) {
    if (optionIds.length != challenge.options.length) return false;
    final attempt = _tokens(challenge, optionIds).join(' ');
    return challenge.acceptedAnswers.contains(attempt);
  }

  /// How many of the placed tokens are correct from the start, measured
  /// against the accepted order that matches the longest prefix.
  int correctPrefixLength(LanguageChallenge challenge, List<String> optionIds) {
    final attempt = _tokens(challenge, optionIds);
    var best = 0;
    for (final accepted in challenge.acceptedAnswers) {
      final target = accepted.split(' ');
      var length = 0;
      while (length < attempt.length && length < target.length && attempt[length] == target[length]) {
        length++;
      }
      if (length > best) best = length;
    }
    return best;
  }

  /// The id of an unplaced token that correctly continues [placedIds], or
  /// null when the placed prefix is already wrong or complete.
  String? nextCorrectOptionId(LanguageChallenge challenge, List<String> placedIds) {
    final placed = _tokens(challenge, placedIds);
    for (final accepted in challenge.acceptedAnswers) {
      final target = accepted.split(' ');
      if (placed.length >= target.length) continue;
      var matches = true;
      for (var i = 0; i < placed.length; i++) {
        if (placed[i] != target[i]) {
          matches = false;
          break;
        }
      }
      if (!matches) continue;
      final needed = target[placed.length];
      for (final option in challenge.options) {
        if (placedIds.contains(option.id)) continue;
        if (TextNormalizer.normalize(option.text) == needed) return option.id;
      }
    }
    return null;
  }
}
