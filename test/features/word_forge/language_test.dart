import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/combat_config.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/timer_policy.dart';
import 'package:ustadia_user_app/features/word_forge/domain/content/difficulty.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/answer_validator.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/challenge_type.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/challenge_validator.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/language_challenge.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/text_normalizer.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/word_selector.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/word_mastery.dart';

LanguageChallenge _choice({String prompt = 'hot', String answer = 'cold', List<String> options = const ['cold', 'fast', 'clean', 'large']}) =>
    LanguageChallenge(
      id: 'c',
      type: ChallengeType.antonym,
      prompt: prompt,
      correctAnswer: answer,
      options: [for (var i = 0; i < options.length; i++) ChallengeOption(id: 'o$i', text: options[i])],
      degree: 1,
    );

LanguageChallenge _arrange(List<String> tokens, List<String> accepted) => LanguageChallenge(
      id: 'a',
      type: ChallengeType.incantation,
      prompt: '',
      correctAnswer: accepted.first,
      options: [for (var i = 0; i < tokens.length; i++) ChallengeOption(id: 't$i', text: tokens[i])],
      acceptedAnswers: accepted,
      degree: 1,
    );

WordStats _stats({int correct = 0, int wrong = 0, List<bool>? recent, Set<ChallengeType> types = const {}, int last = 0}) =>
    WordStats(
      seen: correct + wrong,
      correct: correct,
      wrong: wrong,
      recent: recent ?? [for (var i = 0; i < correct; i++) true],
      correctTypes: types,
      lastSeenBattle: last,
    );

void main() {
  group('TextNormalizer', () {
    test('ignores case, punctuation and extra spaces', () {
      expect(TextNormalizer.normalize('  Don’t   STOP! '), "don't stop");
      expect(TextNormalizer.normalize('well-known'), 'well-known');
    });

    test('tokenizes sentences and keeps the terminator separately', () {
      expect(TextNormalizer.tokenize('If it rains, we will stay at home.'),
          ['if', 'it', 'rains', 'we', 'will', 'stay', 'at', 'home']);
      expect(TextNormalizer.terminatorOf('Do you like music?'), '?');
    });
  });

  group('AnswerValidator', () {
    const validator = AnswerValidator();

    test('validates choices by normalised text', () {
      final challenge = _choice(options: const ['COLD', 'fast', 'clean', 'large']);
      expect(validator.isCorrectChoice(challenge, 'o0'), isTrue);
      expect(validator.isCorrectChoice(challenge, 'o1'), isFalse);
      expect(validator.isCorrectChoice(challenge, 'missing'), isFalse);
    });

    test('accepts any listed word order for incantations', () {
      final challenge = _arrange(
        ['every', 'day', 'she', 'goes', 'to', 'school'],
        ['she goes to school every day', 'every day she goes to school'],
      );
      expect(validator.isCorrectArrangement(challenge, ['t2', 't3', 't4', 't5', 't0', 't1']), isTrue);
      expect(validator.isCorrectArrangement(challenge, ['t0', 't1', 't2', 't3', 't4', 't5']), isTrue);
      expect(validator.isCorrectArrangement(challenge, ['t3', 't2', 't4', 't5', 't0', 't1']), isFalse);
    });

    test('handles duplicate words and finds the next correct token', () {
      final challenge = _arrange(['the', 'cat', 'the', 'sees', 'dog'], ['the cat sees the dog']);
      expect(validator.nextCorrectOptionId(challenge, const []), 't0');
      expect(validator.nextCorrectOptionId(challenge, const ['t0', 't1', 't3']), 't2');
      expect(validator.correctPrefixLength(challenge, const ['t0', 't3']), 1);
      expect(validator.isCorrectArrangement(challenge, const ['t2', 't1', 't3', 't0', 't4']), isTrue);
    });
  });

  group('ChallengeValidator', () {
    const validator = ChallengeValidator();

    test('accepts a good challenge', () => expect(validator.validate(_choice()), isEmpty));

    test('rejects missing, duplicated or ambiguous answers', () {
      expect(validator.validate(_choice(options: const ['warm', 'fast', 'clean'])), contains('correct answer missing'));
      expect(validator.validate(_choice(options: const ['cold', 'Cold', 'fast', 'clean'])),
          contains('correct answer appears more than once'));
      expect(validator.validate(_choice(options: const ['cold', 'fast'])), contains('not enough distractors'));
      expect(validator.validate(_choice(prompt: ' ')), contains('empty prompt'));
    });

    test('rejects malformed sentence tokens', () {
      expect(validator.validate(_arrange(['she', 'goes'], ['she goes home'])), isNotEmpty);
      expect(validator.validate(_arrange(['she', 'goes', 'home'], ['she goes home'])), contains('tokens already in solved order'));
    });
  });

  group('MasteryCalculator', () {
    const mastery = MasteryCalculator();

    test('grows with repeated, varied, reliable success', () {
      expect(mastery.level(null), 0);
      expect(mastery.level(_stats(correct: 1)), 1);
      expect(mastery.level(_stats(correct: 2)), 2);
      expect(mastery.level(_stats(correct: 4)), 3);
      expect(mastery.level(_stats(correct: 8)), 3, reason: 'needs two challenge types for level 4');
      expect(mastery.level(_stats(correct: 8, types: {ChallengeType.antonym, ChallengeType.missingRune})), 4);
      expect(mastery.level(_stats(correct: 11, types: {ChallengeType.antonym, ChallengeType.synonym})), 5);
    });

    test('recent mistakes lower visible mastery', () {
      final strong = _stats(correct: 11, types: {ChallengeType.antonym, ChallengeType.synonym});
      final slipped = strong.record(isCorrect: false, type: ChallengeType.antonym, battleIndex: 9);
      expect(mastery.level(slipped), lessThan(5));
    });

    test('recording keeps a bounded recent window', () {
      var stats = const WordStats();
      for (var i = 0; i < 20; i++) {
        stats = stats.record(isCorrect: i.isEven, type: ChallengeType.synonym, battleIndex: i, responseMs: 1000);
      }
      expect(stats.recent.length, WordStats.recentWindow);
      expect(stats.seen, 20);
      expect(stats.averageResponseSeconds, 1);
    });
  });

  group('WordSelector', () {
    const selector = WordSelector();
    const range = DegreeRange(1, 2);

    double weight(WordStats? stats, {int degree = 1, int battle = 10}) =>
        selector.weightFor(stats: stats, degree: degree, range: range, battleIndex: battle);

    test('favours failed, new and weak words over mastered ones', () {
      final failed = _stats(correct: 3, wrong: 1, recent: [true, true, true, false], last: 9);
      final fresh = weight(null);
      final weak = weight(_stats(correct: 1, last: 9));
      final mastered = weight(_stats(correct: 12, types: {ChallengeType.antonym, ChallengeType.synonym}, last: 9));
      expect(weight(failed), greaterThan(fresh));
      expect(fresh, greaterThan(mastered));
      expect(weak, greaterThan(mastered));
      expect(mastered, greaterThan(0), reason: 'mastered words still return for retention');
    });

    test('words not seen for a while gain weight', () {
      final seenRecently = weight(_stats(correct: 4, last: 9));
      final seenLongAgo = weight(_stats(correct: 4, last: 1));
      expect(seenLongAgo, greaterThan(seenRecently));
    });

    test('excludes words above the range and slightly prefers the target degree', () {
      expect(weight(null, degree: 3), 0);
      expect(weight(null, degree: 2), greaterThan(weight(null, degree: 1)));
    });

    test('weighted pick is deterministic for a seed and respects weights', () {
      final items = ['a', 'b', 'c'];
      final first = selector.pick(items, (item) => item == 'c' ? 10 : 1, Random(3));
      final second = selector.pick(items, (item) => item == 'c' ? 10 : 1, Random(3));
      expect(first, second);
      final counts = <String, int>{};
      final random = Random(1);
      for (var i = 0; i < 1000; i++) {
        final item = selector.pick(items, (item) => item == 'c' ? 8 : 1, random)!;
        counts[item] = (counts[item] ?? 0) + 1;
      }
      expect(counts['c']!, greaterThan(700));
      expect(selector.pick(<String>[], (_) => 1, random), isNull);
      expect(selector.pick(items, (_) => 0, random), isNull);
    });
  });

  group('TimerPolicy', () {
    const policy = TimerPolicy(TimerConfigSet());

    LanguageChallenge word(String prompt, List<String> options, {int degree = 1, String? focus}) => LanguageChallenge(
          id: 'c',
          type: ChallengeType.antonym,
          prompt: prompt,
          correctAnswer: options.first,
          options: [for (var i = 0; i < options.length; i++) ChallengeOption(id: 'o$i', text: options[i])],
          degree: degree,
          focusWordId: focus,
        );

    double seconds(LanguageChallenge challenge, {WordStats? stats}) =>
        policy.secondsFor(use: TimerUse.enemyCritical, tasks: [challenge], statsOf: (_) => stats);

    test('enemy criticals are short but never unfair', () {
      final easy = seconds(word('hot', ['cold', 'fast', 'big', 'sad']));
      expect(easy, inInclusiveRange(4.5, 6.5));
      final shortAdvanced = seconds(word('calm', ['angry', 'rich', 'wet', 'shy'], degree: 4));
      final longAdvanced = seconds(word('reluctant', ['willing', 'enthusiastic', 'eager', 'determined'], degree: 4));
      expect(shortAdvanced, lessThan(easy), reason: 'higher levels train faster recognition');
      expect(longAdvanced, greaterThan(shortAdvanced + 1), reason: 'long, close words need more reading time');
      expect(seconds(word('a', ['b', 'c', 'd'], degree: 6)), greaterThanOrEqualTo(3.5));
    });

    test('unknown words get extra time; mastered words slightly less', () {
      final prompt = word('hot', ['cold', 'fast', 'big', 'sad'], focus: 'hot');
      final unknown = seconds(prompt);
      final mastered = seconds(prompt,
          stats: const WordStats(seen: 12, correct: 12, recent: [true, true, true, true, true, true], correctTypes: {ChallengeType.antonym, ChallengeType.synonym}));
      expect(unknown, greaterThan(mastered));
    });

    test('untimed moves stay untimed', () {
      expect(policy.secondsFor(use: TimerUse.none, tasks: [word('hot', ['cold', 'fast', 'big'])], statsOf: (_) => null), 0);
    });
  });
}
