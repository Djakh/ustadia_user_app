import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final int timeLimit;
  final DateTime? deadline;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final int sectionCount;
  final int taskCount;
  final int completedTaskCount;
  final int pendingTaskCount;
  final int completedTaskPercentage;
  final bool isCompleted;
  final int progress;
  final List<SectionModel> sections;

  const AssignmentModel(
      {required this.id,
      required this.title,
      required this.description,
      required this.status,
      required this.timeLimit,
      required this.deadline,
      required this.createdAt,
      required this.updatedAt,
      required this.sectionCount,
      required this.taskCount,
      required this.completedTaskCount,
      required this.pendingTaskCount,
      required this.completedTaskPercentage,
      required this.isCompleted,
      required this.progress,
      required this.sections});

  bool get isActive => status == 'active';

  bool get isDeadlinePassed {
    final value = deadline;
    return value != null && !DateTime.now().isBefore(value);
  }

  bool get canOpen => isCompleted || (isActive && !isDeadlinePassed);

  SectionModel? get firstSection => sections.isNotEmpty ? sections.first : null;

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'];
    final parsedDeadline = parseDate(json['deadline']);
    final createdAt = parseDate(json['created_at']);
    final updatedAt = parseDate(json['updated_at']);
    final completedTaskPercentage = toIntValue(json['completedTaskPercentage']);
    final progressValue = completedTaskPercentage;
    return AssignmentModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? '',
        timeLimit: toIntValue(json['time_limit']),
        deadline: parsedDeadline,
        createdAt: createdAt,
        updatedAt: updatedAt,
        sectionCount: toIntValue(json['sectionCount']),
        taskCount: toIntValue(json['taskCount']),
        completedTaskCount: toIntValue(json['CompletedTaskCount'] ?? json['completedTaskCount']),
        pendingTaskCount: toIntValue(json['PendingTaskCount'] ?? json['pendingTaskCount']),
        completedTaskPercentage: completedTaskPercentage,
        isCompleted: json['isCompleted'] == true || json['status'] == 'completed',
        progress: progressValue,
        sections: sectionsJson is List
            ? sectionsJson
                .map((item) => SectionModel.fromJson(item as Map<String, dynamic>))
                .toList()
            : const []);
  }

  static int toIntValue(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }

  static DateTime? parseDate(dynamic value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }
}
