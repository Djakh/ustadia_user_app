class LearnQuestionAnswerBlankResultModel {
  final int position;
  final String answer;

  const LearnQuestionAnswerBlankResultModel({
    required this.position,
    required this.answer,
  });

  factory LearnQuestionAnswerBlankResultModel.fromJson(Map<String, dynamic> json) {
    return LearnQuestionAnswerBlankResultModel(
      position: _toInt(json['position']),
      answer: json['answer']?.toString() ?? '',
    );
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}

class LearnQuestionAnswerResultModel {
  final String id;
  final String userId;
  final String questionId;
  final bool success;
  final String? error;
  final String? answerId;
  final List<String> correctAnswerIds;
  final String? userInputText;
  final String? userAudioId;
  final List<LearnQuestionAnswerBlankResultModel> userBlankAnswers;
  final List<LearnQuestionAnswerBlankResultModel> correctBlankAnswers;
  final bool? isCorrect;
  final String? aiFeedback;
  final String createdAt;

  const LearnQuestionAnswerResultModel({
    required this.id,
    required this.userId,
    required this.questionId,
    required this.success,
    required this.error,
    required this.answerId,
    required this.correctAnswerIds,
    required this.userInputText,
    required this.userAudioId,
    required this.userBlankAnswers,
    required this.correctBlankAnswers,
    required this.isCorrect,
    required this.aiFeedback,
    required this.createdAt,
  });

  factory LearnQuestionAnswerResultModel.fromJson(Map<String, dynamic> json) {
    final isCorrectValue = json['isCorrect'] ?? json['is_correct'];
    return LearnQuestionAnswerResultModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      questionId: (json['questionId'] ?? json['question_id'])?.toString() ?? '',
      success: _toBool(json['success'], fallback: true),
      error: _nullableText(json['error']),
      answerId: _nullableText(json['answer_id']),
      correctAnswerIds: _extractIds(json),
      userInputText: _nullableText(json['user_input_text']),
      userAudioId: _nullableText(json['user_audio_id']),
      userBlankAnswers: _extractBlankAnswers(json['user_blank_answers']),
      correctBlankAnswers: _extractBlankAnswers(json['correct_blank_answers']),
      isCorrect: _toBoolOrNull(isCorrectValue),
      aiFeedback: _nullableText(json['ai_feedback']),
      createdAt: json['created_at']?.toString() ?? '',
    );
  }

  String? get correctAnswerId => correctAnswerIds.isNotEmpty ? correctAnswerIds.first : null;

  static String? _nullableText(dynamic value) {
    final text = value?.toString();
    if (text == null || text.isEmpty || text == 'null') return null;
    return text;
  }

  static bool _toBool(dynamic value, {required bool fallback}) {
    final parsed = _toBoolOrNull(value);
    return parsed ?? fallback;
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

  static List<String> _extractIds(Map<String, dynamic> json) {
    const keys = [
      'correct_answer_ids',
      'correctAnswerIds',
      'correct_answers',
      'correctAnswers',
      'correct_answer_id',
      'correctAnswerId',
    ];
    final ids = <String>[];
    for (final key in keys) {
      final value = json[key];
      if (value is List) {
        ids.addAll(value.map((item) {
          if (item is Map<String, dynamic>) {
            return item['id']?.toString() ?? item['answer_id']?.toString() ?? '';
          }
          return item?.toString() ?? '';
        }).where((id) => id.isNotEmpty));
      } else {
        final text = _nullableText(value);
        if (text != null) ids.add(text);
      }
    }
    return ids.toSet().toList();
  }

  static List<LearnQuestionAnswerBlankResultModel> _extractBlankAnswers(dynamic value) {
    if (value is! List) return const [];
    return value
        .whereType<Map<String, dynamic>>()
        .map(LearnQuestionAnswerBlankResultModel.fromJson)
        .toList();
  }
}
