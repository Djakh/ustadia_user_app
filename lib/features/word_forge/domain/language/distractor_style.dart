/// How believable the wrong options are. Strategies can evolve without
/// touching the generators (see `DistractorPicker`).
enum DistractorStyle {
  /// Unrelated words of similar difficulty and part of speech.
  standard,

  /// Adds words that are related to the prompt but still clearly wrong.
  semantic,

  /// Semantic plus look-alike / sound-alike words (lose / loose).
  mimic;

  static DistractorStyle parse(Object? raw) => DistractorStyle.values
      .firstWhere((value) => value.name == raw, orElse: () => DistractorStyle.standard);
}
