import 'package:flutter/foundation.dart';
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
  final int? maxSelections;
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
      required this.maxSelections,
      this.source = SectionSource.learn,
      required this.questionType});

  factory SectionQuestionModel.fromJson(Map<String, dynamic> json,
      {SectionSource source = SectionSource.learn,
      String? assignmentId,
      String? unitId,
      String? lessonId}) {
    final rawAnswers =
        (json['answers'] as List<dynamic>?)?.whereType<Map<String, dynamic>>().toList() ?? const [];
    final answers = (json['answers'] as List<dynamic>?)
        ?.whereType<Map<String, dynamic>>()
        .map(SectionAnswerModel.fromJson)
        .toList();
    answers?.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final questionType = json['type']?.toString() ?? '';
    final hasChoiceAnswers = rawAnswers.isNotEmpty &&
        (questionType.toLowerCase() == 'multiple-choice' ||
            questionType.toLowerCase() == 'single-choice');
    final parsedCorrectCount = answers?.where((answer) => answer.isCorrect).length ?? 0;
    if (kDebugMode && hasChoiceAnswers && parsedCorrectCount == 0) {
      debugPrint('[MalformedQuestion] questionId=${json['id']} type=$questionType '
          'has answers but no correct option in payload. '
          'rawAnswers=${rawAnswers.map((answer) => {
                'id': answer['id'],
                'text': answer['answer_text'],
                'is_correct': answer['is_correct'],
                'isCorrect': answer['isCorrect'],
                'correct': answer['correct'],
                'user_selected': answer['user_selected'],
              }).toList()}');
    }
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
      sectionId: json['section_id']?.toString() ?? json['assignment_section_id']?.toString() ?? '',
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
      questionType: questionType,
      maxSelections: _toInt(json['max_selections']),
    );
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
        maxSelections: maxSelections ?? this.maxSelections,
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
