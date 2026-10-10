import '../../content/word_entry.dart';
import '../challenge_factory.dart';
import '../challenge_type.dart';
import '../distractor_picker.dart';
import '../language_challenge.dart';

/// Antonym Counter and Synonym Resonance share one generator: pick a prompt
/// word adaptively, pick one of its related words as the answer, add safe
/// distractors.
class RelationChallengeGenerator implements ChallengeGenerator {
  @override
  final ChallengeType type;

  const RelationChallengeGenerator(this.type)
      : assert(type == ChallengeType.antonym || type == ChallengeType.synonym);

  RelationKind get _relation =>
      type == ChallengeType.antonym ? RelationKind.opposite : RelationKind.similar;

  List<String> _relatedOf(WordEntry word) =>
      _relation == RelationKind.opposite ? word.antonyms : word.synonyms;

  @override
  LanguageChallenge? generate(GenerationRequest request, GenerationContext context) {
    final forced = request.promptWordId == null ? null : context.content.words[request.promptWordId];
    final candidates = context.content.words.values
        .where((word) =>
            request.degrees.contains(word.degree) &&
            _relatedOf(word).isNotEmpty &&
            (!request.requireBothRelations || (word.canBeCountered && word.canResonate)) &&
            !request.excludedWordIds.contains(word.id))
        .toList();
    final prompt = forced != null && _relatedOf(forced).isNotEmpty
        ? forced
        : context.selector.pick<WordEntry>(
            candidates,
            (word) =>
                context.selector.weightFor(
                  stats: context.stats.statsFor(word.id),
                  degree: word.degree,
                  range: request.degrees,
                  battleIndex: context.stats.battleIndex,
                ) *
                familiarityFactor(context.stats, word.id, preferFamiliar: request.preferFamiliar),
            context.random,
          );
    if (prompt == null) return null;

    // Prefer answers that are entries themselves (their stats get tracked and
    // their meaning cluster protects distractor choice).
    final answer = context.selector.pick<String>(
      _relatedOf(prompt),
      (text) {
        final entry = context.content.wordByText(text);
        if (entry == null) return 1;
        return entry.degree <= request.degrees.max + 1 ? 2.5 : 0.5;
      },
      context.random,
    );
    if (answer == null) return null;

    final distractors = context.distractors.pick(
      relation: _relation,
      prompt: prompt,
      answer: answer,
      content: context.content,
      degrees: request.degrees,
      style: request.style,
      count: request.optionCount - 1,
      random: context.random,
    );
    if (distractors.length < 2) return null;

    final answerEntry = context.content.wordByText(answer);
    return LanguageChallenge(
      id: '',
      type: type,
      prompt: prompt.text,
      correctAnswer: answer,
      options: shuffledOptions([answer, ...distractors], context.random),
      degree: prompt.degree,
      wordIds: [prompt.id, if (answerEntry != null) answerEntry.id],
      focusWordId: prompt.id,
      metadata: {
        'definition': prompt.definition,
        if (answerEntry != null) 'answerDefinition': answerEntry.definition,
      },
    );
  }
}
