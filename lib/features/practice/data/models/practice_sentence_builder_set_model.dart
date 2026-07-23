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
        sentenceBuilderQuestionId:
            (json['sentenceBuilderQuestionId'] ?? json['sentence_builder_question_id'])
                    ?.toString() ??
                '',
        word: json['word']?.toString() ?? '',
        correctPosition: _toInt(json['correctPosition'] ?? json['correct_position']),
        order: _toInt(json['order'] ?? json['orderIndex'] ?? json['order_index']),
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
    final words = _listFromAny(json, const [
          'words',
          'sentenceBuilderWords',
          'sentence_builder_words',
        ])
            ?.whereType<Map<String, dynamic>>()
            .map(PracticeSentenceBuilderWordModel.fromJson)
            .toList() ??
        [];
    words.sort((a, b) => a.order.compareTo(b.order));
    return PracticeSentenceBuilderQuestionModel(
      id: json['id']?.toString() ?? '',
      sentenceBuilderId:
          (json['sentenceBuilderId'] ?? json['sentence_builder_id'])?.toString() ?? '',
      audioId: (json['audioId'] ?? json['audio_id'])?.toString(),
      hint: json['hint']?.toString(),
      translation: json['translation']?.toString(),
      order: _toInt(json['order'] ?? json['orderIndex'] ?? json['order_index']),
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
    final questions = _listFromAny(json, const [
          'questions',
          'sentenceBuilderQuestions',
          'sentence_builder_questions',
        ])
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
      isPublic: _toBool(json['isPublic'] ?? json['is_public']),
      isPublished: _toBool(json['isPublished'] ?? json['is_published']),
      status: json['status']?.toString() ?? '',
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
