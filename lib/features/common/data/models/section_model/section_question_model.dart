import 'package:ustadia_user_app/features/common/data/models/section_model/section_answer_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class SectionQuestionModel {
  final String id;
  final String sectionId;
  final String? assignmentId;
  final String? unitId;
  final String? lessonId;
  final String title;
  final String? description;
  final String difficulty;
  final int orderIndex;
  final int xp;
  final List<SectionAnswerModel>? answers;
  final int numberOfBlanks;
  final List<SectionBlankAnswer> blankAnswers;
  final List<SectionBlankAnswer> userBlankAnswers;
  final SectionSource source;
  final String questionType;

  const SectionQuestionModel(
      {required this.id,
      required this.sectionId,
      required this.assignmentId,
      required this.unitId,
      required this.lessonId,
      required this.title,
      required this.description,
      required this.difficulty,
      required this.orderIndex,
      required this.xp,
      required this.answers,
      required this.numberOfBlanks,
      required this.blankAnswers,
      required this.userBlankAnswers,
      this.source = SectionSource.learn,
      required this.questionType});

  factory SectionQuestionModel.fromJson(Map<String, dynamic> json,
      {SectionSource source = SectionSource.learn,
      String? assignmentId,
      String? unitId,
      String? lessonId}) {
    final answers = (json['answers'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map(SectionAnswerModel.fromJson)
        .toList();
    answers?.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final blankAnswers = (json['blank_answers'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(SectionBlankAnswer.fromJson)
            .toList() ??
        const [];
    final userBlankAnswers = (json['user_blank_answers'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(SectionBlankAnswer.fromJson)
            .toList() ??
        const [];
    return SectionQuestionModel(
        id: json['id']?.toString() ?? '',
        sectionId:
            json['section_id']?.toString() ?? json['assignment_section_id']?.toString() ?? '',
        assignmentId: assignmentId,
        unitId: unitId,
        lessonId: lessonId,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString(),
        difficulty: json['difficulty']?.toString() ?? '',
        orderIndex: _toInt(json['order_index']),
        xp: _toInt(json['xp']),
        answers: answers,
        numberOfBlanks: _toInt(json['number_of_blanks']),
        blankAnswers: blankAnswers,
        userBlankAnswers: userBlankAnswers,
        source: source,
        questionType: json['type']?.toString() ?? '');
  }

  SectionQuestionModel copyWith(
      {String? unitId,
      String? lessonId,
      List<SectionAnswerModel>? answers,
      List<SectionBlankAnswer>? blankAnswers,
      List<SectionBlankAnswer>? userBlankAnswers}) {
    return SectionQuestionModel(
        id: id,
        sectionId: sectionId,
        assignmentId: assignmentId,
        unitId: unitId ?? this.unitId,
        lessonId: lessonId ?? this.lessonId,
        title: title,
        description: description,
        difficulty: difficulty,
        orderIndex: orderIndex,
        xp: xp,
        answers: answers ?? this.answers,
        numberOfBlanks: numberOfBlanks,
        blankAnswers: blankAnswers ?? this.blankAnswers,
        userBlankAnswers: userBlankAnswers ?? this.userBlankAnswers,
        source: source,
        questionType: questionType);
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}

class SectionBlankAnswer {
  final int position;
  final String? answer;

  const SectionBlankAnswer({required this.position, required this.answer});

  factory SectionBlankAnswer.fromJson(Map<String, dynamic> json) => SectionBlankAnswer(
      position: int.tryParse(json['position']?.toString() ?? '') ?? 0,
      answer: json['answer']?.toString());
}
