import 'dart:math';

import '../content/difficulty.dart';
import '../progression/word_mastery.dart';

/// Read-only view of learning statistics used while generating challenges.
abstract class WordStatsLookup {
  WordStats? statsFor(String wordId);

  /// Index of the battle being played; used to measure staleness.
  int get battleIndex;

  /// Template ids used in the last few battles (to avoid repeats).
  Set<String> get recentContentKeys;
}

class EmptyWordStatsLookup implements WordStatsLookup {
  const EmptyWordStatsLookup();

  @override
  WordStats? statsFor(String wordId) => null;

  @override
  int get battleIndex => 0;

  @override
  Set<String> get recentContentKeys => const {};
}

/// Tunable weights for adaptive selection. See [WordSelector.weightFor].
class SelectionWeights {
  final double newWord;
  final double weaknessPerLevel;
  final double recentFailure;
  final double stalenessPerBattle;
  final int stalenessCap;
  final double masteredFactor;
  final double targetDegreeFactor;
  final double lowerDegreeFactor;
  final double recentContentFactor;

  const SelectionWeights({
    this.newWord = 2.5,
    this.weaknessPerLevel = 0.6,
    this.recentFailure = 2.5,
    this.stalenessPerBattle = 0.15,
    this.stalenessCap = 8,
    this.masteredFactor = 0.35,
    this.targetDegreeFactor = 1.3,
    this.lowerDegreeFactor = 0.8,
    this.recentContentFactor = 0.25,
  });
}

/// Deterministic weighted selection. Favours new, recently failed, weak and
/// stale words; mastered words still appear occasionally for retention.
class WordSelector {
  final SelectionWeights weights;
  final MasteryCalculator mastery;

  const WordSelector({this.weights = const SelectionWeights(), this.mastery = const MasteryCalculator()});

  double weightFor({
    required WordStats? stats,
    required int degree,
    required DegreeRange range,
    required int battleIndex,
  }) {
    if (degree > range.max) return 0;
    double weight;
    if (stats == null || stats.seen == 0) {
      weight = weights.newWord;
    } else {
      final level = mastery.level(stats);
      weight = 1 + (MasteryCalculator.maxLevel - level) * weights.weaknessPerLevel;
      if (stats.lastWasWrong) weight += weights.recentFailure;
      final sinceSeen = (battleIndex - stats.lastSeenBattle).clamp(0, weights.stalenessCap);
      weight += sinceSeen * weights.stalenessPerBattle;
      if (level >= MasteryCalculator.maxLevel) weight *= weights.masteredFactor;
    }
    return weight * _degreeFactor(degree, range);
  }

  double _degreeFactor(int degree, DegreeRange range) {
    if (degree > range.max) return 0;
    if (degree == range.max) return weights.targetDegreeFactor;
    if (degree < range.min) return weights.lowerDegreeFactor;
    return 1;
  }

  /// Weight for content that practises several words (sentences, runes).
  double weightForWords({
    required List<String> wordIds,
    required WordStatsLookup lookup,
    required int degree,
    required DegreeRange range,
  }) {
    if (wordIds.isEmpty) return 1.5 * _degreeFactor(degree, range);
    var best = 0.0;
    for (final id in wordIds) {
      final weight = weightFor(
          stats: lookup.statsFor(id), degree: degree, range: range, battleIndex: lookup.battleIndex);
      if (weight > best) best = weight;
    }
    return best;
  }

  /// Picks one item with probability proportional to its weight.
  T? pick<T>(List<T> items, double Function(T item) weightOf, Random random) {
    if (items.isEmpty) return null;
    final itemWeights = items.map((item) => max(0.0, weightOf(item))).toList();
    final total = itemWeights.fold<double>(0, (sum, weight) => sum + weight);
    if (total <= 0) return null;
    var roll = random.nextDouble() * total;
    for (var index = 0; index < items.length; index++) {
      roll -= itemWeights[index];
      if (roll <= 0) return items[index];
    }
    return items.last;
  }
}
