class TeacherClassModel {
  final String? id;
  final String? name;

  const TeacherClassModel({
     this.id,
     this.name,
  });

  factory TeacherClassModel.fromJson(Map<String, dynamic> json) => TeacherClassModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
      );
}

class TeacherModel {
  final String? id;
  final String? teacherId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? profilePicture;
  final String? level;
  final TeacherClassModel? teacherClass;
  final bool? isActive;
  final DateTime? createdAt;

  const TeacherModel({
    this.id,
    this.teacherId,
    this.firstName,
    this.lastName,
    this.email,
    this.profilePicture,
    this.level,
    this.teacherClass,
    this.isActive,
    this.createdAt,
  });

  String get fullName => '$firstName $lastName'.trim();

  TeacherModel copyWith({
    String? id,
    String? teacherId,
    String? firstName,
    String? lastName,
    String? email,
    String? profilePicture,
    String? level,
    TeacherClassModel? teacherClass,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return TeacherModel(
      id: id ?? this.id,
      teacherId: teacherId ?? this.teacherId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      profilePicture: profilePicture ?? this.profilePicture,
      level: level ?? this.level,
      teacherClass: teacherClass ?? this.teacherClass,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory TeacherModel.fromJson(Map<String, dynamic> json) => TeacherModel(
        id: json['id']?.toString() ?? '',
        teacherId: json['teacher_id']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        email: json['email']?.toString() ?? '',
        profilePicture: json['profilePicture']?.toString(),
        level: json['level']?.toString() ?? '',
        teacherClass: json['class'] is Map<String, dynamic>
            ? TeacherClassModel.fromJson(json['class'] as Map<String, dynamic>)
            : null,
        isActive: json['isActive'] == true,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}
