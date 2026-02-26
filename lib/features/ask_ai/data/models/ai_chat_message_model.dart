class AiChatMessageModel {
  final String id;
  final String topicId;
  final String userId;
  final String role;
  final String content;
  final DateTime createdAt;

  const AiChatMessageModel(
      {required this.id,
      required this.topicId,
      required this.userId,
      required this.role,
      required this.content,
      required this.createdAt});

  factory AiChatMessageModel.fromJson(Map<String, dynamic> json) => AiChatMessageModel(
      id: json['id']?.toString() ?? '',
      topicId: json['topicId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      content: json['content']?.toString() ?? '',
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now());
}
