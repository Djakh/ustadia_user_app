enum LearnUnitProgressState { locked, inProgress, completed }

class LearnUnitModel {
  final String id;
  final int unitNumber;
  final String title;
  final String description;
  final int totalSections;
  final String? imageUrl;
  final double progressPercent;
  final LearnUnitProgressState progressState;
  final bool isPublished;

  const LearnUnitModel({
    required this.id,
    required this.unitNumber,
    required this.title,
    required this.description,
    required this.totalSections,
    required this.imageUrl,
    required this.progressPercent,
    required this.progressState,
    required this.isPublished
  });

  factory LearnUnitModel.fromJson(Map<String, dynamic> json) {
    final isPublished = json['isPublished'] == true;
    final progressPercent = (json['completionPercentage'] is num)
        ? (json['completionPercentage'] as num).toDouble()
        : 0;
    final progressValue = progressPercent > 1 ? progressPercent / 100 : progressPercent;
    final progressState = progressValue >= 1
        ? LearnUnitProgressState.completed
        : isPublished
            ? LearnUnitProgressState.inProgress
            : LearnUnitProgressState.locked;
    final totalSectionsValue = json['totalSections'];
    final totalSections = totalSectionsValue is int
        ? totalSectionsValue
        : int.tryParse(totalSectionsValue?.toString() ?? '') ?? 0;
    return LearnUnitModel(
        id: json['id']?.toString() ?? '',
        unitNumber: json['order_index'] is int ? json['order_index'] as int : 0,
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        totalSections: totalSections,
        imageUrl: json['image'] is Map ? json['image']['url']?.toString() : json['image']?.toString(),
        progressPercent: progressValue.toDouble(),
        progressState: progressState,
        isPublished: isPublished);
  }

  const LearnUnitModel.empty()
      : id = '',
        unitNumber = 0,
        title = '',
        description = '',
        totalSections = 0,
        imageUrl = null,
        progressPercent = 0,
        progressState = LearnUnitProgressState.locked,
        isPublished = false;
}
