class AiChatMessageModel {
  final String id;
  final String topicId;
  final String userId;
  final String role;
  final String content;
  final DateTime createdAt;
  final bool isFinished;

  const AiChatMessageModel(
      {required this.id,
      required this.topicId,
      required this.userId,
      required this.role,
      required this.content,
      required this.createdAt,
      this.isFinished = false});

  factory AiChatMessageModel.fromJson(Map<String, dynamic> json) => AiChatMessageModel(
      id: _resolveId(json),
      topicId: (json['topicId'] ?? json['topic_id'])?.toString() ?? '',
      userId: (json['userId'] ?? json['user_id'])?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse((json['created_at'] ?? json['createdAt'])?.toString() ?? '') ??
          DateTime.now(),
      isFinished: _parseBool(json['isFinished']));

  AiChatMessageModel copyWith(
          {String? id,
          String? topicId,
          String? userId,
          String? role,
          String? content,
          DateTime? createdAt,
          bool? isFinished}) =>
      AiChatMessageModel(
          id: id ?? this.id,
          topicId: topicId ?? this.topicId,
          userId: userId ?? this.userId,
          role: role ?? this.role,
          content: content ?? this.content,
          createdAt: createdAt ?? this.createdAt,
          isFinished: isFinished ?? this.isFinished);

  static String _resolveId(Map<String, dynamic> json) {
    final directId = json['id']?.toString() ?? '';
    if (directId.isNotEmpty) return directId;
    final topicId = (json['topicId'] ?? json['topic_id'])?.toString() ?? '';
    final userId = (json['userId'] ?? json['user_id'])?.toString() ?? '';
    final role = json['role']?.toString() ?? '';
    final createdAt = (json['created_at'] ?? json['createdAt'])?.toString() ?? '';
    final content = json['content']?.toString() ?? '';
    return '$topicId|$userId|$role|$createdAt|$content';
  }

  static bool _parseBool(dynamic value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalizedValue = value?.toString().toLowerCase().trim();
    return normalizedValue == 'true' || normalizedValue == '1';
  }
}
