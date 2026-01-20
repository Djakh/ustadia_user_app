class LearnSectionAnswerModel {
  final String id;
  final String questionId;
  final String answerText;
  final bool isCorrect;
  final int orderIndex;

  const LearnSectionAnswerModel(
      {required this.id,
      required this.questionId,
      required this.answerText,
      required this.isCorrect,
      required this.orderIndex});

  factory LearnSectionAnswerModel.fromJson(Map<String, dynamic> json) => LearnSectionAnswerModel(
      id: json['id']?.toString() ?? '',
      questionId: json['question_id']?.toString() ?? '',
      answerText: json['answer_text']?.toString() ?? '',
      isCorrect: json['is_correct'] == true,
      orderIndex: _toInt(json['order_index']));

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}
