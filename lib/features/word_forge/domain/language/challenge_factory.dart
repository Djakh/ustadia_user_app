import 'dart:math';

import '../content/difficulty.dart';
import '../content/word_forge_content.dart';
import 'challenge_type.dart';
import 'challenge_validator.dart';
import 'distractor_picker.dart';
import 'distractor_style.dart';
import 'generators/incantation_generator.dart';
import 'generators/missing_rune_generator.dart';
import 'generators/relation_generator.dart';
import 'generators/word_match_generator.dart';
import 'language_challenge.dart';
import 'word_selector.dart';

/// What the battle needs right now.
class GenerationRequest {
  final ChallengeType type;
  final DegreeRange degrees;
  final DistractorStyle style;
  final int optionCount;
  final Set<String> excludedWordIds;
  final Set<String> excludedContentKeys;

  /// Forces the prompt word (e.g. Mirror Spell asks two things about one word).
  final String? promptWordId;

  /// Weights familiar words up (timed moves should not ambush with new words).
  final bool preferFamiliar;

  /// Number of pairs for match challenges.
  final int pairCount;

  /// Only prompt words that have both synonyms and antonyms (Mirror Spell).
  final bool requireBothRelations;

  const GenerationRequest({
    required this.type,
    required this.degrees,
    this.style = DistractorStyle.standard,
    this.optionCount = 4,
    this.excludedWordIds = const {},
    this.excludedContentKeys = const {},
    this.promptWordId,
    this.preferFamiliar = false,
    this.pairCount = 3,
    this.requireBothRelations = false,
  });

  GenerationRequest copyWith({
    DegreeRange? degrees,
    Set<String>? excludedWordIds,
    Set<String>? excludedContentKeys,
  }) =>
      GenerationRequest(
        type: type,
        degrees: degrees ?? this.degrees,
        style: style,
        optionCount: optionCount,
        excludedWordIds: excludedWordIds ?? this.excludedWordIds,
        excludedContentKeys: excludedContentKeys ?? this.excludedContentKeys,
        promptWordId: promptWordId,
        preferFamiliar: preferFamiliar,
        pairCount: pairCount,
        requireBothRelations: requireBothRelations,
      );
}

/// Everything a generator may read. Randomness is injected for testability.
class GenerationContext {
  final WordForgeContent content;
  final WordStatsLookup stats;
  final Random random;
  final WordSelector selector;
  final DistractorPicker distractors;

  const GenerationContext({
    required this.content,
    required this.random,
    this.stats = const EmptyWordStatsLookup(),
    this.selector = const WordSelector(),
    this.distractors = const DistractorPicker(),
  });
}

/// Extension point for language mechanics.
abstract class ChallengeGenerator {
  ChallengeType get type;

  /// Returns null when no suitable content exists for [request].
  LanguageChallenge? generate(GenerationRequest request, GenerationContext context);
}

typedef InvalidChallengeCallback = void Function(LanguageChallenge challenge, List<String> issues);

/// Builds validated challenges. Retries with other content and finally relaxes
/// the difficulty range, so a battle never stalls on missing content.
class ChallengeFactory {
  final Map<ChallengeType, ChallengeGenerator> generators;
  final ChallengeValidator validator;
  final InvalidChallengeCallback? onInvalid;
  int _counter = 0;

  ChallengeFactory({
    Map<ChallengeType, ChallengeGenerator>? generators,
    this.validator = const ChallengeValidator(),
    this.onInvalid,
  }) : generators = generators ?? defaultGenerators();

  static Map<ChallengeType, ChallengeGenerator> defaultGenerators() => {
        ChallengeType.antonym: const RelationChallengeGenerator(ChallengeType.antonym),
        ChallengeType.synonym: const RelationChallengeGenerator(ChallengeType.synonym),
        ChallengeType.missingRune: const MissingRuneGenerator(),
        ChallengeType.incantation: const IncantationGenerator(),
        ChallengeType.wordMatch: const WordMatchGenerator(),
      };

  bool supports(ChallengeType type) => generators.containsKey(type);

  LanguageChallenge? create(GenerationRequest request, GenerationContext context) {
    final generator = generators[request.type];
    if (generator == null) return null;
    final rejectedWords = <String>{};
    final rejectedKeys = <String>{};
    for (var attempt = 0; attempt < 8; attempt++) {
      final degrees = attempt < 4 ? request.degrees : request.degrees.widen(attempt < 6 ? 1 : 2);
      final challenge = generator.generate(
        request.copyWith(
          degrees: degrees,
          excludedWordIds: {...request.excludedWordIds, ...rejectedWords},
          excludedContentKeys: {...request.excludedContentKeys, ...rejectedKeys},
        ),
        context,
      );
      if (challenge == null) continue;
      final issues = validator.validate(challenge);
      if (issues.isEmpty) return _withId(challenge);
      onInvalid?.call(challenge, issues);
      rejectedKeys.add(challenge.contentKey);
      if (challenge.focusWordId != null) rejectedWords.add(challenge.focusWordId!);
    }
    return null;
  }

  LanguageChallenge _withId(LanguageChallenge challenge) => challenge.withId('${challenge.type.name}_${_counter++}');
}

/// Shuffles [texts] into options with ids that do not reveal the answer.
List<ChallengeOption> shuffledOptions(List<String> texts, Random random) {
  final shuffled = [...texts]..shuffle(random);
  return [
    for (var index = 0; index < shuffled.length; index++)
      ChallengeOption(id: 'o$index', text: shuffled[index]),
  ];
}

/// Familiarity factor for timed moves: known words up, brand-new words down.
double familiarityFactor(WordStatsLookup stats, String wordId, {required bool preferFamiliar}) {
  if (!preferFamiliar) return 1;
  final word = stats.statsFor(wordId);
  if (word == null || word.seen == 0) return 0.25;
  if (word.correct >= 2) return 3;
  return 1.5;
}

/// Content ids that exist in [content]; used to keep stats clean.
List<String> knownWordIds(Iterable<String> ids, WordForgeContent content) =>
    [for (final id in ids) if (content.words.containsKey(id)) id];
