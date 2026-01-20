class LearnQuestionAnswerResultModel {
  final String id;
  final String userId;
  final String questionId;
  final String? answerId;
  final String? userInputText;
  final String? userAudioId;
  final bool? isCorrect;
  final String? aiFeedback;
  final String createdAt;

  const LearnQuestionAnswerResultModel({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.answerId,
    required this.userInputText,
    required this.userAudioId,
    required this.isCorrect,
    required this.aiFeedback,
    required this.createdAt,
  });

  factory LearnQuestionAnswerResultModel.fromJson(Map<String, dynamic> json) {
    final dynamic isCorrectValue = json['isCorrect'] ?? json['is_correct'];
    final bool? isCorrect = isCorrectValue is bool ? isCorrectValue : null;
    return LearnQuestionAnswerResultModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      questionId: json['question_id']?.toString() ?? '',
      answerId: json['answer_id']?.toString(),
      userInputText: json['user_input_text']?.toString(),
      userAudioId: json['user_audio_id']?.toString(),
      isCorrect: isCorrect,
      aiFeedback: json['ai_feedback']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}
