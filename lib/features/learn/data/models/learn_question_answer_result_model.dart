class LearnQuestionAnswerResultModel {
  final String id;
  final String userId;
  final String questionId;
  final String? answerId;
  final String? correctAnswerId;
  final List<String> correctAnswerIds;
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
    required this.correctAnswerId,
    required this.correctAnswerIds,
    required this.userInputText,
    required this.userAudioId,
    required this.isCorrect,
    required this.aiFeedback,
    required this.createdAt,
  });

  factory LearnQuestionAnswerResultModel.fromJson(Map<String, dynamic> json) {
    final dynamic isCorrectValue = json['isCorrect'] ?? json['is_correct'];
    final bool? isCorrect = _toBoolOrNull(isCorrectValue);
    return LearnQuestionAnswerResultModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      questionId: json['question_id']?.toString() ?? '',
      answerId: json['answer_id']?.toString(),
      correctAnswerId: _firstString([
        json['correct_answer_id'],
        json['correctAnswerId'],
        json['correct_answer'],
        json['correctAnswer'],
      ]),
      correctAnswerIds: _extractIds(json),
      userInputText: json['user_input_text']?.toString(),
      userAudioId: json['user_audio_id']?.toString(),
      isCorrect: isCorrect,
      aiFeedback: json['ai_feedback']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  static bool? _toBoolOrNull(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }

  static String? _firstString(List<dynamic> values) {
    for (final value in values) {
      final text = value?.toString();
      if (text != null && text.isNotEmpty) return text;
    }
    return null;
  }

  static List<String> _extractIds(Map<String, dynamic> json) {
    const keys = [
      'correct_answer_ids',
      'correctAnswerIds',
      'correct_answers',
      'correctAnswers',
    ];
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        final ids = value
            .map((item) {
              if (item is Map<String, dynamic>) {
                return item['id']?.toString() ??
                    item['answer_id']?.toString() ??
                    item['correct_answer_id']?.toString() ??
                    '';
              }
              return item?.toString() ?? '';
            })
            .where((id) => id.isNotEmpty)
            .toList();
        if (ids.isNotEmpty) return ids;
      }
    }
    return const [];
  }
}
