class LearnLessonModel {
  final String id;
  final String name;
  final String description;
  final int orderIndex;
  final int totalUnits;
  final int totalSections;
  final int completedSections;
  final double completionPercentage;
  final String? imageUrl;
  final bool isPublic;
  final bool isPublished;

  const LearnLessonModel({
    required this.id,
    required this.name,
    required this.description,
    required this.orderIndex,
    required this.totalUnits,
    required this.totalSections,
    required this.completedSections,
    required this.completionPercentage,
    required this.imageUrl,
    required this.isPublic,
    required this.isPublished
  });

  factory LearnLessonModel.fromJson(Map<String, dynamic> json) => LearnLessonModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      orderIndex: json['order_index'] is int ? json['order_index'] as int : 0,
      totalUnits: json['totalUnits'] is int ? json['totalUnits'] as int : 0,
      totalSections: json['totalSections'] is int ? json['totalSections'] as int : 0,
      completedSections: json['completedSections'] is int ? json['completedSections'] as int : 0,
      completionPercentage: (json['completionPercentage'] is num)
          ? (json['completionPercentage'] as num).toDouble()
          : 0,
      imageUrl: json['image'] is Map ? json['image']['url']?.toString() : json['image']?.toString(),
      isPublic: json['isPublic'] == true,
      isPublished: json['isPublished'] == true);

  const LearnLessonModel.empty()
      : id = '',
        name = 'Lessons',
        description = '',
        orderIndex = 0,
        totalUnits = 0,
        totalSections = 0,
        completedSections = 0,
        completionPercentage = 0,
        imageUrl = null,
        isPublic = true,
        isPublished = true;
}
