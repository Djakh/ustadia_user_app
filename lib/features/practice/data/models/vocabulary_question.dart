class VocabularyModel {
  final String category;
  final String prompt;
  final List<String> options;
  final int answerIndex;

  const VocabularyModel(
      {required this.category,
      required this.prompt,
      required this.options,
      required this.answerIndex});
}
