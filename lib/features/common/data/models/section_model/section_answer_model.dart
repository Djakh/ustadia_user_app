class SectionAnswerModel {
  final String id;
  final String questionId;
  final String answerText;
  final bool isCorrect;
  final bool userSelected;
  final int orderIndex;

  const SectionAnswerModel(
      {required this.id,
      required this.questionId,
      required this.answerText,
      required this.isCorrect,
      required this.userSelected,
      required this.orderIndex});

  factory SectionAnswerModel.fromJson(Map<String, dynamic> json, {String? selectedAnswerId}) =>
      SectionAnswerModel(
          id: json['id']?.toString() ?? '',
          questionId:
              json['question_id']?.toString() ?? json['assignment_question_id']?.toString() ?? '',
          answerText: json['answer_text']?.toString() ?? '',
          isCorrect: _extractIsCorrect(json),
          userSelected: _toBool(json['user_selected']) ||
              (selectedAnswerId != null && selectedAnswerId == json['id']?.toString()),
          orderIndex: _toInt(json['order_index']));

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }

  static bool _toBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return fallback;
  }

  static bool _extractIsCorrect(Map<String, dynamic> json) {
    const keys = [
      'is_correct',
      'isCorrect',
      'correct',
      'is_right',
      'isRight',
      'correct_answer',
      'correctAnswer',
      'is_answer_correct',
      'isAnswerCorrect',
    ];
    for (final key in keys) {
      if (!json.containsKey(key)) continue;
      if (_toBool(json[key])) return true;
    }
    return false;
  }
}
