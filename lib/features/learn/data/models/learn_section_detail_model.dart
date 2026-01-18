import 'package:ustadia_user_app/features/learn/data/models/learn_quiz_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model.dart';

class LearnSectionDetailModel {
  final String id;
  final String unitId;
  final LearnSectionType type;
  final String title;
  final String content;
  final String? audioFileId;
  final int orderIndex;
  final String? audioFile;
  final bool unitIsPublished;
  final bool lessonIsPublic;
  final List<LearnSectionQuestionModel> questions;

  const LearnSectionDetailModel(
      {required this.id,
      required this.unitId,
      required this.type,
      required this.title,
      required this.content,
      required this.audioFileId,
      required this.orderIndex,
      required this.audioFile,
      required this.unitIsPublished,
      required this.lessonIsPublic,
      required this.questions});

  factory LearnSectionDetailModel.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(LearnSectionQuestionModel.fromJson)
            .toList() ??
        [];
    questions.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return LearnSectionDetailModel(
        id: json['id']?.toString() ?? '',
        unitId: json['unit_id']?.toString() ?? '',
        type: LearnSectionTypeX.fromApi(json['type']?.toString() ?? ''),
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        audioFileId: json['audio_file_id']?.toString(),
        orderIndex: _toInt(json['order_index']),
        audioFile: json['audio_file']?.toString(),
        unitIsPublished: json['unit_ispublished'] == true,
        lessonIsPublic: json['lesson_isPublic'] == true,
        questions: questions);
  }

  List<LearnQuizModel> get quizModels => questions
      .map((question) => question.toQuizModel())
      .whereType<LearnQuizModel>()
      .toList();

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}

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

  LearnQuizModel? toQuizModel() {
    if (answers == null || answers!.isEmpty) return null;
    final options = answers!.map((answer) => answer.answerText).toList();
    final correctIndex = answers!.indexWhere((answer) => answer.isCorrect);
    return LearnQuizModel(
        prompt: title, options: options, correctIndex: correctIndex == -1 ? 0 : correctIndex);
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}

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
