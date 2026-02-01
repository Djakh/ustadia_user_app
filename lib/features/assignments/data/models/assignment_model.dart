import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class AssignmentModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final int timeLimit;
  final DateTime? deadline;
  final int progress;
  final List<SectionModel> sections;

  const AssignmentModel(
      {required this.id,
      required this.title,
      required this.description,
      required this.status,
      required this.timeLimit,
      required this.deadline,
      required this.progress,
      required this.sections});

  bool get isActive => status == 'active';

  bool get isCompleted => status == 'completed';

  SectionModel? get firstSection => sections.isNotEmpty ? sections.first : null;

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final sectionsJson = json['sections'];
    final rawDeadline = json['deadline'] as String?;
    final parsedDeadline = rawDeadline == null ? null : DateTime.tryParse(rawDeadline);
    final rawProgress = json['completedTaskPercentage'];
    final progressValue = rawProgress is num ? rawProgress.round() : 0;
    return AssignmentModel(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? '',
        timeLimit: json['time_limit'] as int? ?? 0,
        deadline: parsedDeadline,
        progress: progressValue,
        sections: sectionsJson is List
            ? sectionsJson
                .map((item) => SectionModel.fromJson(item as Map<String, dynamic>))
                .toList()
            : const []);
  }
}
