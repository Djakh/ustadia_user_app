class SectionStatsModel {
  final String sectionId;
  final String sectionType;
  final int totalQuestions;
  final int answeredQuestions;
  final int unansweredQuestions;
  final int correct;
  final int incorrect;
  final int pending;

  const SectionStatsModel({
    required this.sectionId,
    required this.sectionType,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.unansweredQuestions,
    required this.correct,
    required this.incorrect,
    required this.pending,
  });

  factory SectionStatsModel.fromJson(Map<String, dynamic> json) => SectionStatsModel(
        sectionId: json['sectionId']?.toString() ?? json['section_id']?.toString() ?? '',
        sectionType: json['sectionType']?.toString() ?? json['section_type']?.toString() ?? '',
        totalQuestions: _toInt(json['totalQuestions'] ?? json['total_questions']),
        answeredQuestions: _toInt(json['answeredQuestions'] ?? json['answered_questions']),
        unansweredQuestions: _toInt(json['unansweredQuestions'] ?? json['unanswered_questions']),
        correct: _toInt(json['correct']),
        incorrect: _toInt(json['incorrect']),
        pending: _toInt(json['pending']),
      );

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
