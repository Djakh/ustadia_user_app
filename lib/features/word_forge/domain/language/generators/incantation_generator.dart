import '../../content/sentence_content.dart';
import '../challenge_factory.dart';
import '../challenge_type.dart';
import '../language_challenge.dart';

/// Spell Construction: the player taps shuffled words into the right order.
class IncantationGenerator implements ChallengeGenerator {
  const IncantationGenerator();

  @override
  ChallengeType get type => ChallengeType.incantation;

  @override
  LanguageChallenge? generate(GenerationRequest request, GenerationContext context) {
    final recent = context.stats.recentContentKeys;
    final candidates = context.content.incantations
        .where((entry) =>
            request.degrees.contains(entry.degree) &&
            !request.excludedContentKeys.contains(entry.id) &&
            !entry.wordIds.any(request.excludedWordIds.contains))
        .toList();
    final entry = context.selector.pick<IncantationEntry>(
      candidates,
      (entry) {
        final weight = context.selector.weightForWords(
            wordIds: entry.wordIds, lookup: context.stats, degree: entry.degree, range: request.degrees);
        return recent.contains(entry.id) ? weight * context.selector.weights.recentContentFactor : weight;
      },
      context.random,
    );
    if (entry == null) return null;

    final accepted = entry.acceptedAnswers;
    var tokens = entry.tokens;
    for (var attempt = 0; attempt < 12 && accepted.contains(tokens.join(' ')); attempt++) {
      tokens = [...entry.tokens]..shuffle(context.random);
    }
    final wordIds = knownWordIds(entry.wordIds, context.content);
    return LanguageChallenge(
      id: '',
      type: type,
      prompt: '',
      correctAnswer: accepted.first,
      options: [
        for (var index = 0; index < tokens.length; index++)
          ChallengeOption(id: 't$index', text: tokens[index]),
      ],
      acceptedAnswers: accepted,
      degree: entry.degree,
      wordIds: wordIds,
      focusWordId: wordIds.isEmpty ? null : wordIds.first,
      metadata: {'templateId': entry.id, 'terminator': entry.terminator, 'sentence': entry.text},
    );
  }
}
