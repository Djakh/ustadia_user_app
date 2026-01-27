class CurrentUnitLessonModel {
  final String id;
  final String name;
  final int orderIndex;
  final bool isPublic;
  final bool isPublished;
  final String teacherId;

  const CurrentUnitLessonModel({
    required this.id,
    required this.name,
    required this.orderIndex,
    required this.isPublic,
    required this.isPublished,
    required this.teacherId,
  });

  factory CurrentUnitLessonModel.fromJson(Map<String, dynamic> json) => CurrentUnitLessonModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        orderIndex: json['order_index'] is int ? json['order_index'] as int : 0,
        isPublic: json['isPublic'] == true,
        isPublished: json['isPublished'] == true,
        teacherId: json['teacher_id']?.toString() ?? '',
      );

  const CurrentUnitLessonModel.empty()
      : id = '',
        name = '',
        orderIndex = 0,
        isPublic = false,
        isPublished = false,
        teacherId = '';
}

class CurrentUnitModel {
  final String id;
  final String name;
  final int orderIndex;
  final int totalSections;
  final int completedSections;
  final double completionPercentage;
  final CurrentUnitLessonModel lesson;

  const CurrentUnitModel({
    required this.id,
    required this.name,
    required this.orderIndex,
    required this.totalSections,
    required this.completedSections,
    required this.completionPercentage,
    required this.lesson,
  });

  factory CurrentUnitModel.fromJson(Map<String, dynamic> json) {
    final totalSectionsValue = json['totalSections'];
    final completedSectionsValue = json['completedSections'];
    final totalSections = totalSectionsValue is int
        ? totalSectionsValue
        : int.tryParse(totalSectionsValue?.toString() ?? '') ?? 0;
    final completedSections = completedSectionsValue is int
        ? completedSectionsValue
        : int.tryParse(completedSectionsValue?.toString() ?? '') ?? 0;
    return CurrentUnitModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      orderIndex: json['order_index'] is int ? json['order_index'] as int : 0,
      totalSections: totalSections,
      completedSections: completedSections,
      completionPercentage: (json['completionPercentage'] is num)
          ? (json['completionPercentage'] as num).toDouble()
          : 0,
      lesson: json['lesson'] is Map<String, dynamic>
          ? CurrentUnitLessonModel.fromJson(json['lesson'] as Map<String, dynamic>)
          : const CurrentUnitLessonModel.empty(),
    );
  }

  const CurrentUnitModel.empty()
      : id = '',
        name = '',
        orderIndex = 0,
        totalSections = 0,
        completedSections = 0,
        completionPercentage = 0,
        lesson = const CurrentUnitLessonModel.empty();
}
