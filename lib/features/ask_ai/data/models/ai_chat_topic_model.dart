class AiChatTopicModel {
  final String id;
  final String title;
  final String description;
  final int duration;

  const AiChatTopicModel(
      {required this.id,
      required this.title,
      required this.description,
      required this.duration});

  factory AiChatTopicModel.fromJson(Map<String, dynamic> json) => AiChatTopicModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      duration: json['duration'] is int ? json['duration'] as int : 0);
}
