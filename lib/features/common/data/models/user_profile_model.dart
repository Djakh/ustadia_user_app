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
  final String? profilePictureId;
  final String? profilePictureUrl;
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
      required this.profilePictureId,
      required this.profilePictureUrl,
      required this.currentTeacher,
      required this.introCompleted});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final profilePictureJson = json['profilePicture'];
    final profilePictureId = profilePictureJson is Map
        ? profilePictureJson['id']?.toString()
        : null;
    final profilePictureUrl = profilePictureJson is Map
        ? profilePictureJson['url']?.toString()
        : profilePictureJson?.toString();

    return UserProfileModel(
      id: json['id']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      roles: (json['roles'] as List<dynamic>? ?? []).map((item) => item.toString()).toList(),
      language: json['language']?.toString() ?? 'en',
      createdAt: json['created_at']?.toString() ?? '',
      xp: json['xp']?.toString() ?? '0',
      profilePictureId: profilePictureId,
      profilePictureUrl: profilePictureUrl,
      currentTeacher: json['currentTeacher'] is Map
          ? (json['currentTeacher'] as Map)['id']?.toString()
          : json['currentTeacher']?.toString(),
      introCompleted: json['introCompleted'] as bool? ?? false);
  }
}
