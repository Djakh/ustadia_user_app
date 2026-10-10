import 'challenge_type.dart';
import 'language_challenge.dart';
import 'text_normalizer.dart';

/// Guards the battle against impossible or ambiguous challenges. Generators
/// run every challenge through this before it reaches the player.
class ChallengeValidator {
  const ChallengeValidator();

  static const int minChoiceOptions = 3;

  List<String> validate(LanguageChallenge challenge) {
    final issues = <String>[];
    if (challenge.prompt.trim().isEmpty && challenge.inputMode == ChallengeInputMode.choice) {
      issues.add('empty prompt');
    }
    final normalizedOptions = challenge.options.map((o) => TextNormalizer.normalize(o.text)).toList();
    if (normalizedOptions.any((text) => text.isEmpty)) issues.add('empty option');
    final ids = challenge.options.map((o) => o.id).toSet();
    if (ids.length != challenge.options.length) issues.add('duplicate option ids');

    switch (challenge.inputMode) {
      case ChallengeInputMode.choice:
        final answer = TextNormalizer.normalize(challenge.correctAnswer);
        final matches = normalizedOptions.where((text) => text == answer).length;
        if (matches == 0) issues.add('correct answer missing');
        if (matches > 1) issues.add('correct answer appears more than once');
        if (normalizedOptions.toSet().length != normalizedOptions.length) {
          issues.add('duplicate options');
        }
        if (challenge.options.length < minChoiceOptions) issues.add('not enough distractors');
        if (TextNormalizer.normalize(challenge.prompt) == answer) issues.add('answer equals prompt');
      case ChallengeInputMode.arrange:
        if (challenge.options.length < 2) issues.add('too few tokens');
        if (challenge.acceptedAnswers.isEmpty) issues.add('no accepted answer');
        final sortedTokens = [...normalizedOptions]..sort();
        for (final accepted in challenge.acceptedAnswers) {
          final sortedAccepted = accepted.split(' ')..sort();
          if (sortedAccepted.join(' ') != sortedTokens.join(' ')) {
            issues.add('tokens do not build "$accepted"');
          }
        }
        if (challenge.acceptedAnswers.contains(normalizedOptions.join(' '))) {
          issues.add('tokens already in solved order');
        }
      case ChallengeInputMode.match:
        final pairs = challenge.pairs;
        if (pairs.length < 2) issues.add('needs at least two pairs');
        if (pairs.values.toSet().length != pairs.length) issues.add('pair targets repeat');
        if (challenge.options.length != pairs.length * 2) issues.add('every option needs a pair');
        for (final entry in pairs.entries) {
          if (!ids.contains(entry.key) || !ids.contains(entry.value)) issues.add('pair references unknown option');
        }
        if (normalizedOptions.toSet().length != normalizedOptions.length) issues.add('duplicate words');
    }
    return issues;
  }

  bool isValid(LanguageChallenge challenge) => validate(challenge).isEmpty;
}
