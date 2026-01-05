class LearnListeningQuestionModel {
  final String prompt;
  final List<String> options;
  final int correctIndex;

  const LearnListeningQuestionModel({
    required this.prompt,
    required this.options,
    required this.correctIndex
  });

  static const List<LearnListeningQuestionModel> sampleQuestions = [
    LearnListeningQuestionModel(
      prompt: 'Which sentence is correct?',
      options: ['I wake up at 7.', 'I waking up at 7.', 'I wakes up at 7.'],
      correctIndex: 0
    ),
    LearnListeningQuestionModel(
      prompt: "The past tense of 'go' is 'went'.",
      options: ['True', 'False'],
      correctIndex: 0
    ),
    LearnListeningQuestionModel(
      prompt: 'Complete: She ___ breakfast.',
      options: ['eats', 'eat', 'eating'],
      correctIndex: 0
    )
  ];
}
