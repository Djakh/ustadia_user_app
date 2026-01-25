import 'package:ustadia_user_app/features/learn/data/models/learn_audio_file_model.dart';

class PracticeListenTapOptionModel {
  final String id;
  final String listenTapQuestionId;
  final String word;
  final bool isCorrect;
  final int order;

  const PracticeListenTapOptionModel({
    required this.id,
    required this.listenTapQuestionId,
    required this.word,
    required this.isCorrect,
    required this.order,
  });

  factory PracticeListenTapOptionModel.fromJson(Map<String, dynamic> json) =>
      PracticeListenTapOptionModel(
        id: json['id']?.toString() ?? '',
        listenTapQuestionId: json['listenTapQuestionId']?.toString() ?? '',
        word: json['word']?.toString() ?? '',
        isCorrect: json['isCorrect'] == true,
        order: _toInt(json['order']),
      );
}

class PracticeListenTapQuestionModel {
  final String id;
  final String listenTapId;
  final String audioId;
  final int order;
  final List<PracticeListenTapOptionModel> options;
  final LearnAudioFileModel? audio;

  const PracticeListenTapQuestionModel({
    required this.id,
    required this.listenTapId,
    required this.audioId,
    required this.order,
    required this.options,
    required this.audio,
  });

  int get correctIndex => options.indexWhere((option) => option.isCorrect);

  factory PracticeListenTapQuestionModel.fromJson(Map<String, dynamic> json) {
    final options = (json['options'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(PracticeListenTapOptionModel.fromJson)
            .toList() ??
        [];
    options.sort((a, b) => a.order.compareTo(b.order));
    return PracticeListenTapQuestionModel(
      id: json['id']?.toString() ?? '',
      listenTapId: json['listenTapId']?.toString() ?? '',
      audioId: json['audioId']?.toString() ?? '',
      order: _toInt(json['order']),
      options: options,
      audio: LearnAudioFileModel.fromDynamic(json['audio']),
    );
  }
}

class PracticeListenTapSetModel {
  final String id;
  final String title;
  final String description;
  final String? difficulty;
  final bool isPublic;
  final bool isPublished;
  final int totalQuestions;
  final int answeredQuestions;
  final List<PracticeListenTapQuestionModel> questions;

  const PracticeListenTapSetModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.isPublic,
    required this.isPublished,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.questions,
  });

  factory PracticeListenTapSetModel.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(PracticeListenTapQuestionModel.fromJson)
            .toList() ??
        [];
    questions.sort((a, b) => a.order.compareTo(b.order));
    return PracticeListenTapSetModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      difficulty: json['difficulty']?.toString(),
      isPublic: json['isPublic'] == true,
      isPublished: json['isPublished'] == true,
      totalQuestions: _toInt(json['totalQuestions']),
      answeredQuestions: _toInt(json['answeredQuestions']),
      questions: questions,
    );
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? fallback;
}
