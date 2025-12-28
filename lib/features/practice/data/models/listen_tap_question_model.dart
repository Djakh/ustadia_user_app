class ListenTapQuestionModel {
  final String prompt;
  final List<String> options;
  final int answerIndex;

  const ListenTapQuestionModel(
      {required this.prompt, required this.options, required this.answerIndex});
}
