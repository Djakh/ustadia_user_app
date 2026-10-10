import '../../content/word_entry.dart';
import '../challenge_factory.dart';
import '../challenge_type.dart';
import '../language_challenge.dart';
import '../text_normalizer.dart';

/// Word Match: tap pairs of opposites (BIG ↔ SMALL, FAST ↔ SLOW ...).
///
/// Pairs come from different topic domains, and no left word may be related
/// to another pair's right word, so every board has exactly one solution.
class WordMatchGenerator implements ChallengeGenerator {
  const WordMatchGenerator();

  @override
  ChallengeType get type => ChallengeType.wordMatch;

  @override
  LanguageChallenge? generate(GenerationRequest request, GenerationContext context) {
    final content = context.content;
    final candidates = content.words.values
        .where((word) =>
            request.degrees.contains(word.degree) &&
            !request.excludedWordIds.contains(word.id) &&
            word.antonyms.any((antonym) => content.wordByText(antonym) != null))
        .toList();

    final lefts = <WordEntry>[];
    final rights = <WordEntry>[];
    final usedDomains = <String>{};
    var guard = 0;
    while (lefts.length < request.pairCount && guard++ < 60) {
      final pick = context.selector.pick<WordEntry>(
        candidates.where((word) => !usedDomains.contains(word.domain)).toList(),
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
      if (pick == null) break;
      final answers = [
        for (final antonym in pick.antonyms)
          if (content.wordByText(antonym) case final entry? when !request.excludedWordIds.contains(entry.id)) entry,
      ];
      if (answers.isEmpty) {
        candidates.remove(pick);
        continue;
      }
      final answer = answers[context.random.nextInt(answers.length)];
      if (_clashes(pick, answer, lefts, rights)) {
        candidates.remove(pick);
        continue;
      }
      lefts.add(pick);
      rights.add(answer);
      usedDomains.add(pick.domain);
    }
    if (lefts.length < 2) return null;

    final rightOrder = List.generate(rights.length, (index) => index)..shuffle(context.random);
    final options = <ChallengeOption>[
      for (var i = 0; i < lefts.length; i++) ChallengeOption(id: 'l$i', text: lefts[i].text),
      for (var i = 0; i < rights.length; i++) ChallengeOption(id: 'r$i', text: rights[rightOrder[i]].text),
    ];
    final pairs = <String, String>{
      for (var i = 0; i < lefts.length; i++) 'l$i': 'r${rightOrder.indexOf(i)}',
    };
    return LanguageChallenge(
      id: '',
      type: type,
      prompt: '',
      correctAnswer: '',
      options: options,
      pairs: pairs,
      degree: lefts.map((word) => word.degree).reduce((a, b) => a > b ? a : b),
      wordIds: [for (var i = 0; i < lefts.length; i++) ...[lefts[i].id, rights[i].id]],
      focusWordId: lefts.first.id,
      metadata: const {'relation': 'opposite'},
    );
  }

  /// True when the new pair could be confused with an existing one.
  bool _clashes(WordEntry left, WordEntry right, List<WordEntry> lefts, List<WordEntry> rights) {
    final words = {...lefts.map((w) => w.normalized), ...rights.map((w) => w.normalized)};
    if (words.contains(left.normalized) || words.contains(right.normalized)) return true;
    bool related(WordEntry a, WordEntry b) =>
        a.cluster == b.cluster ||
        a.normalizedAntonyms.contains(b.normalized) ||
        b.normalizedAntonyms.contains(a.normalized) ||
        a.normalizedSynonyms.contains(b.normalized) ||
        b.normalizedSynonyms.contains(a.normalized) ||
        TextNormalizer.normalize(a.domain) == TextNormalizer.normalize(b.domain);
    for (var i = 0; i < lefts.length; i++) {
      if (related(left, rights[i]) || related(lefts[i], right) || related(left, lefts[i]) || related(right, rights[i])) {
        return true;
      }
    }
    return false;
  }
}
