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
        listenTapQuestionId:
            (json['listenTapQuestionId'] ?? json['listen_tap_question_id'])?.toString() ?? '',
        word: (json['word'] ?? json['text'])?.toString() ?? '',
        isCorrect: _toBool(json['isCorrect'] ?? json['is_correct']),
        order: _toInt(json['order'] ?? json['orderIndex'] ?? json['order_index']),
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
    final options = _listFromAny(json, const ['options', 'answers'])
            ?.whereType<Map<String, dynamic>>()
            .map(PracticeListenTapOptionModel.fromJson)
            .toList() ??
        [];
    options.sort((a, b) => a.order.compareTo(b.order));
    return PracticeListenTapQuestionModel(
      id: json['id']?.toString() ?? '',
      listenTapId: (json['listenTapId'] ?? json['listen_tap_id'])?.toString() ?? '',
      audioId: (json['audioId'] ?? json['audio_id'])?.toString() ?? '',
      order: _toInt(json['order'] ?? json['orderIndex'] ?? json['order_index']),
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
    final questions = _listFromAny(json, const [
          'questions',
          'listenTapQuestions',
          'listen_tap_questions',
        ])
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
      isPublic: _toBool(json['isPublic'] ?? json['is_public']),
      isPublished: _toBool(json['isPublished'] ?? json['is_published']),
      totalQuestions:
          _toInt(json['totalQuestions'] ?? json['total_questions'], fallback: questions.length),
      answeredQuestions: _toInt(json['answeredQuestions'] ?? json['answered_questions']),
      questions: questions,
    );
  }
}

List<dynamic>? _listFromAny(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value is List<dynamic>) return value;
  }
  return null;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  final text = value?.toString().toLowerCase();
  return text == 'true' || text == '1';
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? fallback;
}
