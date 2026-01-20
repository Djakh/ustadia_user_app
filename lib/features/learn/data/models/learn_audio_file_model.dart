class LearnAudioFileModel {
  final String id;
  final String filename;
  final String path;
  final String mimetype;
  final String url;
  final String createdAt;

  const LearnAudioFileModel({
    required this.id,
    required this.filename,
    required this.path,
    required this.mimetype,
    required this.url,
    required this.createdAt,
  });

  static LearnAudioFileModel? fromDynamic(dynamic value) {
    if (value is Map<String, dynamic>) return LearnAudioFileModel.fromJson(value);
    if (value == null) return null;
    return LearnAudioFileModel(
      id: '',
      filename: '',
      path: '',
      mimetype: '',
      url: value.toString(),
      createdAt: '',
    );
  }

  factory LearnAudioFileModel.fromJson(Map<String, dynamic> json) => LearnAudioFileModel(
        id: json['id']?.toString() ?? '',
        filename: json['filename']?.toString() ?? '',
        path: json['path']?.toString() ?? '',
        mimetype: json['mimetype']?.toString() ?? '',
        url: json['url']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
      );
}
