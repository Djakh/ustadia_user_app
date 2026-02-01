import 'package:ustadia_user_app/features/common/data/models/section_model/section_answer_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class SectionQuestionModel {
  final String id;
  final String sectionId;
  final String? assignmentId;
  final String title;
  final String? description;
  final String difficulty;
  final int orderIndex;
  final int xp;
  final List<SectionAnswerModel>? answers;
  final SectionSource source;
  final String questionType;

  const SectionQuestionModel(
      {required this.id,
      required this.sectionId,
      required this.assignmentId,
      required this.title,
      required this.description,
      required this.difficulty,
      required this.orderIndex,
      required this.xp,
      required this.answers,
      this.source = SectionSource.learn,
      required this.questionType});

  factory SectionQuestionModel.fromJson(Map<String, dynamic> json,
      {SectionSource source = SectionSource.learn, String? assignmentId}) {
    final answers = (json['answers'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map(SectionAnswerModel.fromJson)
        .toList();
    answers?.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return SectionQuestionModel(
        id: json['id']?.toString() ?? '',
        sectionId:
            json['section_id']?.toString() ?? json['assignment_section_id']?.toString() ?? '',
        assignmentId: assignmentId,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        difficulty: json['difficulty']?.toString() ?? '',
        orderIndex: _toInt(json['order_index']),
        xp: _toInt(json['xp']),
        answers: answers,
        source: source,
        questionType: json['type']?.toString() ?? '');
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}
