class ProfileStatisticsModel {
  final String level;
  final int totalCompletedTasks;
  final int totalVocabulary;
  final ProfileStatisticsBreakdown breakdown;

  const ProfileStatisticsModel(
      {required this.level,
      required this.totalCompletedTasks,
      required this.totalVocabulary,
      required this.breakdown});

  factory ProfileStatisticsModel.fromJson(Map<String, dynamic> json) => ProfileStatisticsModel(
      level: json['level']?.toString() ?? '',
      totalCompletedTasks: toIntValue(json['totalCompletedTasks']),
      totalVocabulary: toIntValue(json['totalVocabulary']),
      breakdown: ProfileStatisticsBreakdown.fromJson(
          json['breakdown'] is Map<String, dynamic> ? json['breakdown'] : const {}));

  static int toIntValue(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
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
