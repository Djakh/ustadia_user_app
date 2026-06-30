class MonkeyTypePracticeModel {
  final String id;
  final String title;
  final String description;
  final bool isPublic;
  final String teacherId;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? monkeyTypeUrl;
  final List<MonkeyTypeTextModel> texts;

  const MonkeyTypePracticeModel({
    required this.id,
    required this.title,
    required this.description,
    required this.isPublic,
    required this.teacherId,
    required this.createdAt,
    required this.updatedAt,
    this.monkeyTypeUrl,
    this.texts = const [],
  });

  factory MonkeyTypePracticeModel.fromJson(Map<String, dynamic> json) {
    final texts = _listFrom(json['texts'])
        .whereType<Map<String, dynamic>>()
        .map(MonkeyTypeTextModel.fromJson)
        .toList();
    texts.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return MonkeyTypePracticeModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      isPublic: _toBool(json['isPublic'] ?? json['is_public']),
      teacherId: json['teacher_id']?.toString() ?? json['teacherId']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
      monkeyTypeUrl: _nullableString(json['monkeyTypeUrl'] ?? json['monkey_type_url']),
      texts: texts,
    );
  }
}

String? _nullableString(dynamic value) {
  final text = value?.toString().trim() ?? '';
  return text.isEmpty ? null : text;
}

class MonkeyTypeTextModel {
  final String id;
  final String practiceId;
  final String text;
  final int orderIndex;
  final DateTime? createdAt;

  const MonkeyTypeTextModel({
    required this.id,
    required this.practiceId,
    required this.text,
    required this.orderIndex,
    required this.createdAt,
  });

  factory MonkeyTypeTextModel.fromJson(Map<String, dynamic> json) => MonkeyTypeTextModel(
        id: json['id']?.toString() ?? '',
        practiceId: json['practice_id']?.toString() ?? json['practiceId']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        orderIndex: _toInt(json['order_index'] ?? json['orderIndex']),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

class MonkeyTypeAnswerModel {
  final String id;
  final String practiceId;
  final String studentId;
  final String text;
  final double wpm;
  final double accuracy;
  final int correctChars;
  final int totalChars;
  final int timeTakenSeconds;
  final DateTime? createdAt;

  const MonkeyTypeAnswerModel({
    required this.id,
    required this.practiceId,
    required this.studentId,
    required this.text,
    required this.wpm,
    required this.accuracy,
    required this.correctChars,
    required this.totalChars,
    required this.timeTakenSeconds,
    required this.createdAt,
  });

  factory MonkeyTypeAnswerModel.fromJson(Map<String, dynamic> json) => MonkeyTypeAnswerModel(
        id: json['id']?.toString() ?? '',
        practiceId: json['practice_id']?.toString() ?? json['practiceId']?.toString() ?? '',
        studentId: json['student_id']?.toString() ?? json['studentId']?.toString() ?? '',
        text: json['text']?.toString() ?? '',
        wpm: _toDouble(json['wpm']),
        accuracy: _toDouble(json['accuracy']),
        correctChars: _toInt(json['correct_chars'] ?? json['correctChars']),
        totalChars: _toInt(json['total_chars'] ?? json['totalChars']),
        timeTakenSeconds: _toInt(json['time_taken_seconds'] ?? json['timeTakenSeconds']),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}

int _toInt(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString()) ?? fallback;
}

double _toDouble(dynamic value, {double fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? fallback;
}

bool _toBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value?.toString().toLowerCase().trim();
  return normalized == 'true' || normalized == '1' || normalized == 'yes';
}

List<dynamic> _listFrom(dynamic value) => value is List ? value : const [];
