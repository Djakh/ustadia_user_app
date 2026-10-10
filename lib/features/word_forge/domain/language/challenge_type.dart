/// The English skill a challenge trains. A challenge type knows nothing about
/// combat; the battle decides what a correct or wrong answer does.
///
/// To add a mechanic (definitions, word families, phrasal verbs...): add a
/// value here, register a `ChallengeGenerator` for it in `ChallengeFactory`
/// and, if it needs a new input style, a panel in `ChallengePanel`.
enum ChallengeType {
  /// Choose the opposite of the prompt word.
  antonym,

  /// Choose a word with a similar meaning.
  synonym,

  /// Complete a sentence with the missing word.
  missingRune,

  /// Put words in order to build a sentence.
  incantation,

  /// Tap pairs of opposite words.
  wordMatch;

  ChallengeInputMode get inputMode => switch (this) {
        ChallengeType.incantation => ChallengeInputMode.arrange,
        ChallengeType.wordMatch => ChallengeInputMode.match,
        _ => ChallengeInputMode.choice,
      };

  static ChallengeType? tryParse(Object? raw) {
    final value = raw?.toString();
    for (final type in ChallengeType.values) {
      if (type.name == value) return type;
    }
    return null;
  }
}

enum ChallengeInputMode { choice, arrange, match }
