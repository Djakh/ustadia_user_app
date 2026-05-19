class AiChatTopicModel {
  final String id;
  final String title;
  final String description;
  final int duration;

  const AiChatTopicModel(
      {required this.id, required this.title, required this.description, required this.duration});

  factory AiChatTopicModel.fromJson(Map<String, dynamic> json) => AiChatTopicModel(
      id: json['id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      duration: _parseDuration(json['duration']));

  static int _parseDuration(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }
}
