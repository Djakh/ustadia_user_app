import 'package:ustadia_user_app/features/common/data/models/teacher_model.dart';

class UserProviderModel {
  final String provider;
  final String identifier;

  const UserProviderModel({required this.provider, required this.identifier});

  factory UserProviderModel.fromJson(Map<String, dynamic> json) => UserProviderModel(
      provider: json['provider']?.toString() ?? '',
      identifier: json['identifier']?.toString() ?? '');
}

class UserIntroAnswerModel {
  final String id;
  final String questionId;
  final String questionDescription;
  final String answerId;
  final String answerText;
  final String createdAt;

  const UserIntroAnswerModel(
      {required this.id,
      required this.questionId,
      required this.questionDescription,
      required this.answerId,
      required this.answerText,
      required this.createdAt});

  factory UserIntroAnswerModel.fromJson(Map<String, dynamic> json) => UserIntroAnswerModel(
      id: json['id']?.toString() ?? '',
      questionId: json['questionId']?.toString() ?? '',
      questionDescription: json['questionDescription']?.toString() ?? '',
      answerId: json['answerId']?.toString() ?? '',
      answerText: json['answerText']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '');
}

class UserLevelModel {
  final String id;
  final Map<String, String> name;
  final Map<String, String> description;
  final bool isPublic;
  final String? teacherId;
  final String createdAt;
  final String updatedAt;

  const UserLevelModel(
      {required this.id,
      required this.name,
      required this.description,
      required this.isPublic,
      required this.teacherId,
      required this.createdAt,
      required this.updatedAt});

  static Map<String, String> localizedMap(dynamic value) {
    if (value is! Map<String, dynamic>) return {};
    return value.map((key, value) => MapEntry(key, value?.toString() ?? ''));
  }

  factory UserLevelModel.fromJson(Map<String, dynamic> json) => UserLevelModel(
      id: json['id']?.toString() ?? '',
      name: localizedMap(json['name']),
      description: localizedMap(json['description']),
      isPublic: json['isPublic'] == true,
      teacherId: json['teacher_id']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      updatedAt: json['updated_at']?.toString() ?? '');

  String nameForLanguage(String languageCode) {
    final normalized = languageCode.toLowerCase();
    if (normalized.startsWith('ru'))
      return name['ru']?.trim().isNotEmpty == true ? name['ru']! : fallbackName;
    if (normalized.startsWith('uz'))
      return name['uz']?.trim().isNotEmpty == true ? name['uz']! : fallbackName;
    return name['en']?.trim().isNotEmpty == true ? name['en']! : fallbackName;
  }

  String descriptionForLanguage(String languageCode) {
    final normalized = languageCode.toLowerCase();
    if (normalized.startsWith('ru')) {
      return description['ru']?.trim().isNotEmpty == true
          ? description['ru']!
          : fallbackDescription;
    }
    if (normalized.startsWith('uz')) {
      return description['uz']?.trim().isNotEmpty == true
          ? description['uz']!
          : fallbackDescription;
    }
    return description['en']?.trim().isNotEmpty == true ? description['en']! : fallbackDescription;
  }

  String get fallbackName {
    for (final value in [name['en'], name['ru'], name['uz']]) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }

  String get fallbackDescription {
    for (final value in [description['en'], description['ru'], description['uz']]) {
      final text = value?.trim() ?? '';
      if (text.isNotEmpty) return text;
    }
    return '';
  }
}

/// Server-controlled permissions for features that can expose user content.
/// A null value means the backend did not provide the capability yet; the app
/// preserves the existing product behavior until the server contract is ready.
class SocialPermissionsModel {
  final bool? canSubmitIeltsWriting;
  final bool? canUploadPublicAvatar;

  const SocialPermissionsModel({this.canSubmitIeltsWriting, this.canUploadPublicAvatar});

  factory SocialPermissionsModel.fromJson(Map<String, dynamic> json) => SocialPermissionsModel(
      canSubmitIeltsWriting:
          _nullableBool(json['can_submit_ielts_writing'] ?? json['canSubmitIeltsWriting']),
      canUploadPublicAvatar:
          _nullableBool(json['can_upload_public_avatar'] ?? json['canUploadPublicAvatar']));
}

bool? _nullableBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return null;
}

class UserProfileBreakdownModel {
  final int practiceCompleted;
  final int assignmentCompleted;
  final int lessonCompleted;

  const UserProfileBreakdownModel(
      {required this.practiceCompleted,
      required this.assignmentCompleted,
      required this.lessonCompleted});

  factory UserProfileBreakdownModel.fromJson(Map<String, dynamic> json) =>
      UserProfileBreakdownModel(
          practiceCompleted: (json['practiceCompleted'] as num?)?.toInt() ?? 0,
          assignmentCompleted: (json['assignmentCompleted'] as num?)?.toInt() ?? 0,
          lessonCompleted: (json['lessonCompleted'] as num?)?.toInt() ?? 0);
}

class UserProfileModel {
  final String id;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phoneNumber;
  final List<UserProviderModel> providers;
  final List<String> roles;
  final String language;
  final String? levelId;
  final String createdAt;
  final String xp;
  final bool isDeleted;
  final List<dynamic> reasoningSessions;
  final String? profilePictureId;
  final String? profilePictureUrl;
  final UserLevelModel? level;
  final TeacherModel? currentTeacher;
  final bool introCompleted;
  final List<UserIntroAnswerModel> introAnswers;
  final int? totalCompletedTasks;
  final int? totalVocabulary;
  final int? myWeeklyRank;
  final int? myMonthlyRank;
  final UserProfileBreakdownModel? breakdown;
  final SocialPermissionsModel? socialPermissions;

  const UserProfileModel(
      {required this.id,
      required this.firstName,
      required this.lastName,
      required this.email,
      required this.phoneNumber,
      required this.providers,
      required this.roles,
      required this.language,
      required this.levelId,
      required this.createdAt,
      required this.xp,
      required this.isDeleted,
      required this.reasoningSessions,
      required this.profilePictureId,
      required this.profilePictureUrl,
      required this.level,
      required this.currentTeacher,
      required this.introCompleted,
      required this.introAnswers,
      required this.totalCompletedTasks,
      required this.totalVocabulary,
      required this.myWeeklyRank,
      required this.myMonthlyRank,
      required this.breakdown,
      this.socialPermissions});

  factory UserProfileModel.fromJson(Map<String, dynamic> json) {
    final profilePictureJson = json['profilePicture'];
    final profilePictureId =
        profilePictureJson is Map ? profilePictureJson['id']?.toString() : null;
    final profilePictureUrl = profilePictureJson is Map
        ? profilePictureJson['url']?.toString()
        : profilePictureJson?.toString();

    final permissionsValue = json['social_permissions'] ?? json['socialPermissions'];
    return UserProfileModel(
        id: json['id']?.toString() ?? '',
        firstName: json['firstName']?.toString() ?? '',
        lastName: json['lastName']?.toString() ?? '',
        email: json['email'] as String?,
        phoneNumber: json['phoneNumber'] as String?,
        providers: (json['providers'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(UserProviderModel.fromJson)
            .toList(),
        roles: (json['roles'] as List<dynamic>? ?? []).map((item) => item.toString()).toList(),
        language: json['language']?.toString() ?? 'en',
        levelId: json['level_id']?.toString(),
        createdAt: json['created_at']?.toString() ?? json['createdAt']?.toString() ?? '',
        xp: json['xp']?.toString() ?? '0',
        isDeleted: json['isDeleted'] == true,
        reasoningSessions: json['reasoningSessions'] as List<dynamic>? ?? const [],
        profilePictureId: profilePictureId,
        profilePictureUrl: profilePictureUrl,
        level: json['level'] is Map<String, dynamic>
            ? UserLevelModel.fromJson(json['level'] as Map<String, dynamic>)
            : null,
        currentTeacher:
            json['currentTeacher'] != null && json['currentTeacher'] is Map<String, dynamic>
                ? TeacherModel.fromJson(json['currentTeacher'])
                : null,
        introCompleted: json['introCompleted'] as bool? ?? false,
        introAnswers: (json['introAnswers'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(UserIntroAnswerModel.fromJson)
            .toList(),
        totalCompletedTasks: (json['totalCompletedTasks'] as num?)?.toInt(),
        totalVocabulary: (json['totalVocabulary'] as num?)?.toInt(),
        myWeeklyRank: (json['myWeeklyRank'] as num?)?.toInt(),
        myMonthlyRank: (json['myMonthlyRank'] as num?)?.toInt(),
        breakdown: json['breakdown'] is Map<String, dynamic>
            ? UserProfileBreakdownModel.fromJson(json['breakdown'] as Map<String, dynamic>)
            : null,
        socialPermissions: permissionsValue is Map
            ? SocialPermissionsModel.fromJson(Map<String, dynamic>.from(permissionsValue))
            : null);
  }
}
