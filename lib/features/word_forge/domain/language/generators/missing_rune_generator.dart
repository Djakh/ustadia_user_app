import '../../content/sentence_content.dart';
import '../challenge_factory.dart';
import '../challenge_type.dart';
import '../language_challenge.dart';

/// Missing Rune: complete a curated sentence. Templates are weighted by the
/// weakest word they practise, so failed words return in a new context.
class MissingRuneGenerator implements ChallengeGenerator {
  const MissingRuneGenerator();

  @override
  ChallengeType get type => ChallengeType.missingRune;

  @override
  LanguageChallenge? generate(GenerationRequest request, GenerationContext context) {
    final recent = context.stats.recentContentKeys;
    final candidates = context.content.runes
        .where((rune) =>
            request.degrees.contains(rune.degree) &&
            !request.excludedContentKeys.contains(rune.id) &&
            !rune.wordIds.any(request.excludedWordIds.contains))
        .toList();
    final rune = context.selector.pick<RuneTemplate>(
      candidates,
      (rune) {
        final weight = context.selector.weightForWords(
            wordIds: rune.wordIds, lookup: context.stats, degree: rune.degree, range: request.degrees);
        return recent.contains(rune.id) ? weight * context.selector.weights.recentContentFactor : weight;
      },
      context.random,
    );
    if (rune == null) return null;

    final distractors = ([...rune.distractors]..shuffle(context.random))
        .take(request.optionCount - 1)
        .toList();
    final wordIds = knownWordIds(rune.wordIds, context.content);
    return LanguageChallenge(
      id: '',
      type: type,
      prompt: rune.sentence,
      correctAnswer: rune.answer,
      options: shuffledOptions([rune.answer, ...distractors], context.random),
      degree: rune.degree,
      wordIds: wordIds,
      focusWordId: wordIds.isEmpty ? null : wordIds.first,
      metadata: {'templateId': rune.id, 'topic': rune.topic},
    );
  }
}
