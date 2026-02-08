class ProfileStatisticsModel {
  final ProfileLevelModel level;
  final int totalCompletedTasks;
  final int totalVocabulary;
  final ProfileStatisticsBreakdown breakdown;

  const ProfileStatisticsModel(
      {required this.level,
      required this.totalCompletedTasks,
      required this.totalVocabulary,
      required this.breakdown});

  factory ProfileStatisticsModel.fromJson(Map<String, dynamic> json) {
    final levelJson = json['level'];
    final parsedLevel = levelJson is Map<String, dynamic>
        ? ProfileLevelModel.fromJson(levelJson)
        : ProfileLevelModel.fromString(levelJson?.toString() ?? '');
    return ProfileStatisticsModel(
        level: parsedLevel,
        totalCompletedTasks: toIntValue(json['totalCompletedTasks']),
        totalVocabulary: toIntValue(json['totalVocabulary']),
        breakdown: ProfileStatisticsBreakdown.fromJson(
            json['breakdown'] is Map<String, dynamic> ? json['breakdown'] : const {}));
  }

  static int toIntValue(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}

class ProfileLevelModel {
  final String id;
  final ProfileLocalizedText name;
  final ProfileLocalizedText description;
  final bool isPublic;
  final String? teacherId;
  final String createdAt;
  final String updatedAt;

  const ProfileLevelModel(
      {required this.id,
      required this.name,
      required this.description,
      required this.isPublic,
      required this.teacherId,
      required this.createdAt,
      required this.updatedAt});

  factory ProfileLevelModel.fromJson(Map<String, dynamic> json) => ProfileLevelModel(
      id: json['id']?.toString() ?? '',
      name: ProfileLocalizedText.fromJson(json['name']),
      description: ProfileLocalizedText.fromJson(json['description']),
      isPublic: json['isPublic'] == true,
      teacherId: json['teacher_id']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '');

  factory ProfileLevelModel.fromString(String value) => ProfileLevelModel(
      id: '',
      name: ProfileLocalizedText(en: value, ru: '', uz: ''),
      description: const ProfileLocalizedText(en: '', ru: '', uz: ''),
      isPublic: false,
      teacherId: null,
      createdAt: '',
      updatedAt: '');

  const ProfileLevelModel.empty()
      : id = '',
        name = const ProfileLocalizedText(en: '', ru: '', uz: ''),
        description = const ProfileLocalizedText(en: '', ru: '', uz: ''),
        isPublic = false,
        teacherId = null,
        createdAt = '',
        updatedAt = '';
}

class ProfileLocalizedText {
  final String en;
  final String ru;
  final String uz;

  const ProfileLocalizedText({required this.en, required this.ru, required this.uz});

  factory ProfileLocalizedText.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return ProfileLocalizedText(
          en: json['en']?.toString() ?? '',
          ru: json['ru']?.toString() ?? '',
          uz: json['uz']?.toString() ?? '');
    }
    return ProfileLocalizedText(en: json?.toString() ?? '', ru: '', uz: '');
  }

  String get primary {
    if (en.isNotEmpty) return en;
    if (ru.isNotEmpty) return ru;
    if (uz.isNotEmpty) return uz;
    return '';
  }

  String forLanguage(String languageCode) {
    final value = languageCode.toLowerCase();
    if (value.startsWith('ru')) return ru.isNotEmpty ? ru : primary;
    if (value.startsWith('uz')) return uz.isNotEmpty ? uz : primary;
    return en.isNotEmpty ? en : primary;
  }
}

class ProfileStatisticsBreakdown {
  final int practiceCompleted;
  final int assignmentCompleted;
  final int lessonCompleted;

  const ProfileStatisticsBreakdown(
      {required this.practiceCompleted,
      required this.assignmentCompleted,
      required this.lessonCompleted});

  factory ProfileStatisticsBreakdown.fromJson(Map<String, dynamic> json) =>
      ProfileStatisticsBreakdown(
          practiceCompleted: toIntValue(json['practiceCompleted']),
          assignmentCompleted: toIntValue(json['assignmentCompleted']),
          lessonCompleted: toIntValue(json['lessonCompleted']));

  static int toIntValue(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}
