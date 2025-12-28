enum SpeedMixTaskType { vocabulary, listen, sentence, wordMatch }

class SpeedMixTaskModel {
  final SpeedMixTaskType type;

  final String prompt;
  final List<String> options;
  final int answerIndex;

  const SpeedMixTaskModel(
      {required this.type,
      required this.prompt,
      required this.options,
      required this.answerIndex});
}
