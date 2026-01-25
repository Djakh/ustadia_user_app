import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_model.dart';

class LearnFlashcardSetModel {
  final String id;
  final String title;
  final String description;
  final List<LearnFlashcardModel> flashcards;
  final String? difficulty;
  final int? totalFlashcards;
  final int? revealedCount;
  final int? notRevealedCount;

  const LearnFlashcardSetModel({
    required this.id,
    required this.title,
    required this.description,
    required this.flashcards,
    required this.difficulty,
    required this.totalFlashcards,
    required this.revealedCount,
    required this.notRevealedCount,
  });

  factory LearnFlashcardSetModel.fromJson(Map<String, dynamic> json) {
    final items = (json['flashcards'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(LearnFlashcardModel.fromJson)
            .toList() ??
        [];
    items.sort((a, b) => a.order.compareTo(b.order));
    return LearnFlashcardSetModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      flashcards: items,
      difficulty: json['difficulty']?.toString(),
      totalFlashcards: _toIntOrNull(json['totalFlashcards']),
      revealedCount: _toIntOrNull(json['revealedCount']),
      notRevealedCount: _toIntOrNull(json['notRevealedCount']),
    );
  }

  static int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }
}
