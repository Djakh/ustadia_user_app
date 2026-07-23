class PracticeWordMatchOptionModel {
  final String id;
  final String wordMatchId;
  final String word;
  final String? match;
  final String type;
  final int pairId;
  final int order;

  const PracticeWordMatchOptionModel({
    required this.id,
    required this.wordMatchId,
    required this.word,
    this.match,
    required this.type,
    required this.pairId,
    required this.order,
  });

  bool get isSource => type == 'source';

  bool get hasInlineMatch => match != null && match!.isNotEmpty;

  factory PracticeWordMatchOptionModel.fromJson(Map<String, dynamic> json) =>
      PracticeWordMatchOptionModel(
        id: json['id']?.toString() ?? '',
        wordMatchId: (json['wordMatchId'] ?? json['word_match_id'])?.toString() ?? '',
        word: json['word']?.toString() ?? '',
        match: json['match']?.toString(),
        type: json['type']?.toString() ?? '',
        pairId: _toInt(json['pairId'] ?? json['pair_id']),
        order: _toInt(json['order'] ?? json['orderIndex'] ?? json['order_index']),
      );
}

class PracticeWordMatchSetModel {
  final String id;
  final String title;
  final String description;
  final String? difficulty;
  final bool isPublic;
  final bool isPublished;
  final String status;
  final int totalOptions;
  final int answered;
  final List<PracticeWordMatchOptionModel> options;

  const PracticeWordMatchSetModel({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.isPublic,
    required this.isPublished,
    required this.status,
    required this.totalOptions,
    required this.answered,
    required this.options,
  });

  factory PracticeWordMatchSetModel.fromJson(Map<String, dynamic> json) {
    final options = _optionsFrom(json)
            ?.whereType<Map<String, dynamic>>()
            .map(PracticeWordMatchOptionModel.fromJson)
            .toList() ??
        [];
    options.sort((a, b) => a.order.compareTo(b.order));
    return PracticeWordMatchSetModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      difficulty: json['difficulty']?.toString(),
      isPublic: _toBool(json['isPublic'] ?? json['is_public']),
      isPublished: _toBool(json['isPublished'] ?? json['is_published']),
      status: json['status']?.toString() ?? '',
      totalOptions: _toInt(json['totalOptions'] ?? json['total_options'], fallback: options.length),
      answered: _toInt(json['answered'] ?? json['answered_options']),
      options: options,
    );
  }
}

List<dynamic>? _optionsFrom(Map<String, dynamic> json) {
  final direct = json['options'];
  if (direct is List<dynamic>) return direct;

  final questions = json['questions'] ?? json['wordMatchQuestions'] ?? json['word_match_questions'];
  if (questions is! List<dynamic>) return null;

  return questions.whereType<Map<String, dynamic>>().expand((question) {
    final options = question['options'];
    return options is List<dynamic> ? options : const <dynamic>[];
  }).toList();
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
