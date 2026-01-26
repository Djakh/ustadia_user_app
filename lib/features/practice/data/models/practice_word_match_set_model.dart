class PracticeWordMatchOptionModel {
  final String id;
  final String wordMatchId;
  final String word;
  final String type;
  final int pairId;
  final int order;

  const PracticeWordMatchOptionModel({
    required this.id,
    required this.wordMatchId,
    required this.word,
    required this.type,
    required this.pairId,
    required this.order,
  });

  bool get isSource => type == 'source';

  factory PracticeWordMatchOptionModel.fromJson(Map<String, dynamic> json) =>
      PracticeWordMatchOptionModel(
        id: json['id']?.toString() ?? '',
        wordMatchId: json['wordMatchId']?.toString() ?? '',
        word: json['word']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        pairId: _toInt(json['pairId']),
        order: _toInt(json['order']),
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
    final options = (json['options'] as List<dynamic>?)
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
      isPublic: json['isPublic'] == true,
      isPublished: json['isPublished'] == true,
      status: json['status']?.toString() ?? '',
      totalOptions: _toInt(json['totalOptions']),
      answered: _toInt(json['answered']),
      options: options,
    );
  }
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  return int.tryParse(value.toString()) ?? fallback;
}
