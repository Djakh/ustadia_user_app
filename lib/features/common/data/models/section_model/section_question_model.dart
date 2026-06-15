import 'package:flutter/foundation.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_answer_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class SectionQuestionModel {
  final String id;
  final String sectionId;
  final String? assignmentId;
  final String? mockExamId;
  final String? mockAttemptId;
  final String? unitId;
  final String? lessonId;
  final String title;
  final String? description;
  final String difficulty;
  final int orderIndex;
  final int xp;
  final bool? isAnswered;
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
      required this.mockExamId,
      required this.mockAttemptId,
      required this.unitId,
      required this.lessonId,
      required this.title,
      required this.description,
      required this.difficulty,
      required this.orderIndex,
      required this.xp,
      required this.isAnswered,
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
      String? mockExamId,
      String? mockAttemptId,
      String? sectionId,
      String? unitId,
      String? lessonId}) {
    final answersJson = json['answers'] ?? json['answer_options'];
    final answersList = answersJson is List ? answersJson : null;
    final rawAnswers = answersList?.whereType<Map<String, dynamic>>().toList() ?? const [];
    final answers = answersList
        ?.whereType<Map<String, dynamic>>()
        .map((answer) => SectionAnswerModel.fromJson(answer,
            selectedAnswerId: selectedAnswerId(json['studentAnswer'])))
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
    final blankAnswersJson = json['blank_answers'] ?? json['blankAnswers'];
    final userBlankAnswersJson = json['user_blank_answers'] ?? json['userBlankAnswers'];
    final blankAnswers = (blankAnswersJson as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(SectionBlankAnswer.fromJson)
            .toList() ??
        const [];
    final userBlankAnswers = (userBlankAnswersJson as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(SectionBlankAnswer.fromJson)
            .toList() ??
        studentBlankAnswers(json['studentAnswer']);
    return SectionQuestionModel(
      id: json['id']?.toString() ?? '',
      sectionId: json['section_id']?.toString() ??
          json['assignment_section_id']?.toString() ??
          json['sectionId']?.toString() ??
          json['mock_section_id']?.toString() ??
          json['sub_section_id']?.toString() ??
          json['subSectionId']?.toString() ??
          sectionId ??
          '',
      assignmentId: assignmentId,
      mockExamId: mockExamId,
      mockAttemptId: mockAttemptId,
      unitId: unitId,
      lessonId: lessonId,
      title: json['title']?.toString() ?? json['content']?.toString() ?? '',
      description: json['description']?.toString() ?? json['content']?.toString(),
      difficulty: json['difficulty']?.toString() ?? '',
      orderIndex: _toInt(json['order_index']),
      xp: _toInt(json['xp']),
      isAnswered: _toBoolOrNull(
          json['is_answered'] ?? json['isAnswered'] ?? json['isCompleted'] ?? json['completed']),
      answers: answers,
      numberOfBlanks: _toInt(json['number_of_blanks'] ?? json['numberOfBlanks']),
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
      String? mockExamId,
      String? mockAttemptId,
      List<SectionAnswerModel>? answers,
      List<SectionBlankAnswer>? blankAnswers,
      List<SectionBlankAnswer>? userBlankAnswers}) {
    return SectionQuestionModel(
        id: id,
        sectionId: sectionId,
        assignmentId: assignmentId,
        mockExamId: mockExamId ?? this.mockExamId,
        mockAttemptId: mockAttemptId ?? this.mockAttemptId,
        unitId: unitId ?? this.unitId,
        lessonId: lessonId ?? this.lessonId,
        title: title,
        description: description,
        difficulty: difficulty,
        orderIndex: orderIndex,
        xp: xp,
        isAnswered: isAnswered,
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

  static bool? _toBoolOrNull(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return null;
  }

  static String? selectedAnswerId(dynamic studentAnswer) {
    if (studentAnswer is! Map<String, dynamic>) return null;
    return studentAnswer['selected_answer_id']?.toString() ??
        studentAnswer['selectedAnswerId']?.toString() ??
        studentAnswer['answer_id']?.toString() ??
        studentAnswer['answerId']?.toString();
  }

  static List<SectionBlankAnswer> studentBlankAnswers(dynamic studentAnswer) {
    if (studentAnswer is! Map<String, dynamic>) return const [];
    final blanks = studentAnswer['blank_answers'] ?? studentAnswer['blankAnswers'];
    if (blanks is! List) return const [];
    return blanks.whereType<Map<String, dynamic>>().map(SectionBlankAnswer.fromJson).toList();
  }
}

class SectionBlankAnswer {
  final int position;
  final String? answer;
  final String? transcript;
  final double? audioStartTime;
  final double? audioEndTime;
  final List<SectionEvidencePosition> positions;

  const SectionBlankAnswer(
      {required this.position,
      required this.answer,
      this.transcript,
      this.audioStartTime,
      this.audioEndTime,
      this.positions = const []});

  bool get hasEvidenceRangeData => positions.isNotEmpty;

  bool get hasAudioEvidenceData =>
      audioStartTime != null &&
      audioEndTime != null &&
      audioStartTime! >= 0 &&
      audioEndTime! > audioStartTime!;

  bool get hasAnswerEvidenceData => hasEvidenceRangeData || hasAudioEvidenceData;

  SectionAnswerModel toEvidenceAnswer(String questionId) => SectionAnswerModel(
      id: 'blank_$position',
      questionId: questionId,
      answerText: answer ?? '',
      isCorrect: true,
      userSelected: false,
      orderIndex: position,
      transcript: transcript,
      startPosition: null,
      endPosition: null,
      audioStartTime: audioStartTime,
      audioEndTime: audioEndTime,
      positions: positions);

  factory SectionBlankAnswer.fromJson(Map<String, dynamic> json) => SectionBlankAnswer(
      position: int.tryParse(json['position']?.toString() ?? '') ?? 0,
      answer: json['answer']?.toString(),
      transcript: json['transcript']?.toString(),
      audioStartTime: _toDoubleOrNull(json['audio_start_time'] ?? json['audioStartTime']),
      audioEndTime: _toDoubleOrNull(json['audio_end_time'] ?? json['audioEndTime']),
      positions: sectionEvidencePositionsFromJson(json['positions']));

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }
}
