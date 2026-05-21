class StudentMeetTeacherModel {
  final String id;
  final String firstName;
  final String lastName;

  const StudentMeetTeacherModel({
    required this.id,
    required this.firstName,
    required this.lastName,
  });

  factory StudentMeetTeacherModel.fromJson(Map<String, dynamic> json) => StudentMeetTeacherModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '');

  String get fullName {
    final name = '$firstName $lastName'.trim();
    return name.isEmpty ? 'Teacher' : name;
  }
}

class StudentMeetClassModel {
  final String id;
  final String name;

  const StudentMeetClassModel({required this.id, required this.name});

  factory StudentMeetClassModel.fromJson(Map<String, dynamic> json) =>
      StudentMeetClassModel(id: json['id']?.toString() ?? '', name: json['name']?.toString() ?? '');
}

class StudentMeetModel {
  final String id;
  final String teacherId;
  final String title;
  final String description;
  final String link;
  final DateTime? scheduledAt;
  final String type;
  final String? studentId;
  final String? classId;
  final StudentMeetTeacherModel? teacher;
  final StudentMeetClassModel? meetClass;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentMeetModel({
    required this.id,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.link,
    required this.scheduledAt,
    required this.type,
    required this.studentId,
    required this.classId,
    required this.teacher,
    required this.meetClass,
    required this.createdAt,
    required this.updatedAt,
  });

  factory StudentMeetModel.fromJson(Map<String, dynamic> json) => StudentMeetModel(
      id: json['id']?.toString() ?? '',
      teacherId: json['teacher_id']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      link: json['link']?.toString() ?? '',
      scheduledAt: DateTime.tryParse(json['scheduled_at']?.toString() ?? ''),
      type: json['type']?.toString() ?? '',
      studentId: json['student_id']?.toString(),
      classId: json['class_id']?.toString(),
      teacher: json['teacher'] is Map<String, dynamic>
          ? StudentMeetTeacherModel.fromJson(json['teacher'] as Map<String, dynamic>)
          : null,
      meetClass: json['class'] is Map<String, dynamic>
          ? StudentMeetClassModel.fromJson(json['class'] as Map<String, dynamic>)
          : null,
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''));

  bool isActual(DateTime now) => scheduledAt?.isAfter(now) ?? false;

  String get displayTitle => title.trim().isEmpty ? 'Meeting' : title.trim();

  String get displayDescription => description.trim();

  String get teacherName => teacher?.fullName ?? 'Teacher';

  String get className => meetClass?.name.trim() ?? '';
}
