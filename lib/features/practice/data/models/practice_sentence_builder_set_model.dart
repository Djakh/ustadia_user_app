class PracticeSentenceBuilderWordModel {
  final String id;
  final String sentenceBuilderQuestionId;
  final String word;
  final int correctPosition;
  final int order;

  const PracticeSentenceBuilderWordModel({
    required this.id,
    required this.sentenceBuilderQuestionId,
    required this.word,
    required this.correctPosition,
    required this.order,
  });

  factory PracticeSentenceBuilderWordModel.fromJson(Map<String, dynamic> json) =>
      PracticeSentenceBuilderWordModel(
        id: json['id']?.toString() ?? '',
        sentenceBuilderQuestionId: json['sentenceBuilderQuestionId']?.toString() ?? '',
        word: json['word']?.toString() ?? '',
        correctPosition: _toInt(json['correctPosition']),
        order: _toInt(json['order']),
      );
}

class PracticeSentenceBuilderQuestionModel {
  final String id;
  final String sentenceBuilderId;
  final String? audioId;
  final String? hint;
  final String? translation;
  final int order;
  final List<PracticeSentenceBuilderWordModel> words;

  const PracticeSentenceBuilderQuestionModel({
    required this.id,
    required this.sentenceBuilderId,
    required this.audioId,
    required this.hint,
    required this.translation,
    required this.order,
    required this.words,
  });

  List<String> get correctOrder {
    final sorted = [...words]..sort((a, b) => a.correctPosition.compareTo(b.correctPosition));
    return sorted.map((word) => word.word).toList();
  }

  factory PracticeSentenceBuilderQuestionModel.fromJson(Map<String, dynamic> json) {
    final words = (json['words'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(PracticeSentenceBuilderWordModel.fromJson)
            .toList() ??
        [];
    words.sort((a, b) => a.order.compareTo(b.order));
    return PracticeSentenceBuilderQuestionModel(
      id: json['id']?.toString() ?? '',
      sentenceBuilderId: json['sentenceBuilderId']?.toString() ?? '',
      audioId: json['audioId']?.toString(),
      hint: json['hint']?.toString(),
      translation: json['translation']?.toString(),
      order: _toInt(json['order']),
      words: words,
    );
  }
}

class PracticeSentenceBuilderSetModel {
  final String id;
  final String title;
  final String description;
  final String? difficulty;
  final bool isPublic;
  final bool isPublished;
  final String status;
  final int totalQuestions;
  final int answeredQuestions;
  final List<PracticeSentenceBuilderQuestionModel> questions;

  const PracticeSentenceBuilderSetModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.isPublic,
    required this.isPublished,
    required this.status,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.questions,
  });

  factory PracticeSentenceBuilderSetModel.fromJson(Map<String, dynamic> json) {
    final questions = (json['questions'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(PracticeSentenceBuilderQuestionModel.fromJson)
            .toList() ??
        [];
    questions.sort((a, b) => a.order.compareTo(b.order));
    return PracticeSentenceBuilderSetModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      difficulty: json['difficulty']?.toString(),
      isPublic: json['isPublic'] == true,
      isPublished: json['isPublished'] == true,
      status: json['status']?.toString() ?? '',
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
