class UserProfileModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;
  final List<String> roles;
  final String language;
  final String createdAt;
  final String xp;
  final String? profilePicture;
  final String? currentTeacher;
  final bool introCompleted;

  const UserProfileModel(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.phoneNumber,
      required this.roles,
      required this.language,
      required this.createdAt,
      required this.xp,
      required this.profilePicture,
      required this.currentTeacher,
      required this.introCompleted});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) => UserProfileModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      roles: (json['roles'] as List<dynamic>? ?? []).map((item) => item.toString()).toList(),
      language: json['language']?.toString() ?? 'en',
      createdAt: json['created_at']?.toString() ?? '',
      xp: json['xp']?.toString() ?? '0',
      profilePicture: json['profilePicture'] as String?,
      currentTeacher: json['currentTeacher'] as String?,
      introCompleted: json['introCompleted'] as bool? ?? false);
}
