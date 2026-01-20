import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_answer_model.dart';

class LearnSectionQuestionModel {
  final String id;
  final String sectionId;
  final String title;
  final String? description;
  final String difficulty;
  final int orderIndex;
  final int xp;
  final List<LearnSectionAnswerModel>? answers;

  const LearnSectionQuestionModel(
      {required this.id,
      required this.sectionId,
      required this.title,
      required this.description,
      required this.difficulty,
      required this.orderIndex,
      required this.xp,
      required this.answers});

  factory LearnSectionQuestionModel.fromJson(Map<String, dynamic> json) {
    final answers = (json['answers'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map(LearnSectionAnswerModel.fromJson)
        .toList();
    answers?.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return LearnSectionQuestionModel(
        id: json['id']?.toString() ?? '',
        sectionId: json['section_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        difficulty: json['difficulty']?.toString() ?? '',
        orderIndex: _toInt(json['order_index']),
        xp: _toInt(json['xp']),
        answers: answers);
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}
