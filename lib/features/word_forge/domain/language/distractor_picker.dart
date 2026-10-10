import 'dart:math';

import '../content/difficulty.dart';
import '../content/word_entry.dart';
import '../content/word_forge_content.dart';
import 'distractor_style.dart';
import 'text_normalizer.dart';

enum RelationKind { opposite, similar }

/// Chooses wrong options for relationship challenges (antonym / synonym).
///
/// Safety first: a distractor must never be a plausible correct answer. Words
/// are excluded when they are listed relations of the prompt or the answer,
/// when they share the answer's meaning cluster, or (for opposites) when they
/// share the prompt's topic domain — e.g. for HOT we never offer CHILLY, and
/// for TALL ≈ ? we never offer BIG.
///
/// Believability second: [DistractorStyle.semantic] and [DistractorStyle.mimic]
/// add options that are related but clearly wrong (the prompt's own synonyms
/// for an opposite challenge, look-alike words for mimics).
class DistractorPicker {
  const DistractorPicker();

  List<String> pick({
    required RelationKind relation,
    required WordEntry prompt,
    required String answer,
    required WordForgeContent content,
    required DegreeRange degrees,
    required DistractorStyle style,
    required int count,
    required Random random,
  }) {
    final answerEntry = content.wordByText(answer);
    final forbidden = _forbiddenTexts(relation, prompt, answer, answerEntry, content);
    final chosen = <String>[];
    final used = <String>{...forbidden};

    void take(String text) {
      final normalized = TextNormalizer.normalize(text);
      if (chosen.length >= count || normalized.isEmpty || used.contains(normalized)) return;
      used.add(normalized);
      chosen.add(text);
    }

    if (style != DistractorStyle.standard) {
      final related = _relatedButWrong(relation, prompt, content)..shuffle(random);
      final relatedQuota = style == DistractorStyle.mimic ? 1 : min(2, count - 1);
      for (final text in related.take(relatedQuota)) {
        take(text);
      }
    }
    if (style == DistractorStyle.mimic) {
      final lookAlikes = [...?answerEntry?.confusables]..shuffle(random);
      if (lookAlikes.isNotEmpty) take(lookAlikes.first);
    }

    final pool = _pool(relation, prompt, answerEntry, content, degrees, forbidden);
    final scored = [
      for (final word in pool) MapEntry(word, _score(word, prompt, random)),
    ]..sort((a, b) => b.value.compareTo(a.value));
    for (final entry in scored) {
      if (chosen.length >= count) break;
      take(entry.key.text);
    }
    return chosen;
  }

  double _score(WordEntry candidate, WordEntry prompt, Random random) {
    var score = random.nextDouble() * 2.5;
    if (candidate.partOfSpeech == prompt.partOfSpeech) score += 2;
    score -= (candidate.degree - prompt.degree).abs() * 0.6;
    return score;
  }

  Set<String> _forbiddenTexts(RelationKind relation, WordEntry prompt, String answer,
      WordEntry? answerEntry, WordForgeContent content) {
    final forbidden = <String>{
      prompt.normalized,
      TextNormalizer.normalize(answer),
    };
    switch (relation) {
      case RelationKind.opposite:
        // Any other opposite of the prompt is also a correct answer.
        forbidden.addAll(prompt.normalizedAntonyms);
        if (answerEntry != null) forbidden.addAll(answerEntry.normalizedSynonyms);
      case RelationKind.similar:
        forbidden.addAll(prompt.normalizedSynonyms);
        if (answerEntry != null) forbidden.addAll(answerEntry.normalizedSynonyms);
    }
    return forbidden;
  }

  /// Entries that could be offered as wrong answers.
  List<WordEntry> _pool(RelationKind relation, WordEntry prompt, WordEntry? answerEntry,
      WordForgeContent content, DegreeRange degrees, Set<String> forbidden) {
    final answerClusters = <String>{
      if (answerEntry != null) answerEntry.cluster,
      if (relation == RelationKind.opposite)
        for (final antonym in prompt.antonyms)
          if (content.wordByText(antonym) case final entry?) entry.cluster,
      if (relation == RelationKind.similar) prompt.cluster,
    };
    final oppositeClusters = <String>{
      for (final antonym in prompt.antonyms)
        if (content.wordByText(antonym) case final entry?) entry.cluster,
    };
    final range = degrees.widen();
    return content.words.values.where((word) {
      if (forbidden.contains(word.normalized)) return false;
      if (!range.contains(word.degree)) return false;
      if (answerClusters.contains(word.cluster)) return false;
      switch (relation) {
        case RelationKind.opposite:
          if (word.domain == prompt.domain) return false;
          if (word.normalizedAntonyms.contains(prompt.normalized)) return false;
          if (word.normalizedAntonyms.intersection(prompt.normalizedSynonyms).isNotEmpty) return false;
          if (word.normalizedSynonyms.intersection(prompt.normalizedAntonyms).isNotEmpty) return false;
        case RelationKind.similar:
          // Same-topic words are too easy to argue for; only clear
          // opposites of the prompt may come from its own topic.
          if (word.domain == prompt.domain && !oppositeClusters.contains(word.cluster)) return false;
          if (word.normalizedSynonyms.contains(prompt.normalized)) return false;
          if (answerEntry != null && word.normalizedSynonyms.contains(answerEntry.normalized)) {
            return false;
          }
          if (word.normalizedSynonyms.intersection(prompt.normalizedSynonyms).isNotEmpty) return false;
      }
      return true;
    }).toList();
  }

  /// Related-but-wrong texts used by harder distractor styles.
  List<String> _relatedButWrong(RelationKind relation, WordEntry prompt, WordForgeContent content) {
    switch (relation) {
      case RelationKind.opposite:
        // Words that mean the same as the prompt are never its opposite.
        return {
          ...prompt.synonyms,
          for (final word in content.words.values)
            if (word.cluster == prompt.cluster && word.id != prompt.id) word.text,
        }.toList();
      case RelationKind.similar:
        // Opposites of the prompt are never similar to it.
        return {
          ...prompt.antonyms,
          for (final antonym in prompt.antonyms) ...?content.wordByText(antonym)?.synonyms,
        }.toList();
    }
  }
}
