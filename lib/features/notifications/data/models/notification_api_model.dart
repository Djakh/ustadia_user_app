import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/features/notifications/data/models/notification_model.dart';

class NotificationInvitationModel {
  final String id;
  final String teacherId;
  final String studentId;
  final String status;
  final String message;
  final String classId;
  final String level;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationInvitationModel({
    required this.id,
    required this.teacherId,
    required this.studentId,
    required this.status,
    required this.message,
    required this.classId,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
  });

  NotificationInvitationModel copyWith({String? status}) => NotificationInvitationModel(
        id: id,
        teacherId: teacherId,
        studentId: studentId,
        status: status ?? this.status,
        message: message,
        classId: classId,
        level: level,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  factory NotificationInvitationModel.fromJson(Map<String, dynamic> json) =>
      NotificationInvitationModel(
        id: json['id']?.toString() ?? '',
        teacherId: json['teacher_id']?.toString() ?? '',
        studentId: json['student_id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        classId: json['class_id']?.toString() ?? '',
        level: json['level']?.toString() ?? '',
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
      );
}

class NotificationApiModel {
  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final NotificationInvitationModel? invitation;
  final DateTime createdAt;
  final DateTime updatedAt;

  const NotificationApiModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.invitation,
    required this.createdAt,
    required this.updatedAt,
  });

  bool get isInvitation => type == 'invitation' && invitation != null;

  String get iconAsset {
    switch (type) {
      case 'invitation':
        return AppImages.notificationDailyRemainder;
      default:
        return AppImages.notificationFeaturesAndTips;
    }
  }

  NotificationApiModel copyWith({
    bool? isRead,
    NotificationInvitationModel? invitation,
  }) =>
      NotificationApiModel(
        id: id,
        type: type,
        title: title,
        message: message,
        isRead: isRead ?? this.isRead,
        invitation: invitation ?? this.invitation,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  NotificationModel toDisplayModel() => NotificationModel(
        id: id,
        title: title,
        message: message,
        iconAsset: iconAsset,
        createdAt: createdAt,
        isRead: isRead,
        category: NotificationCategory.featuresAndTips,
      );

  factory NotificationApiModel.fromJson(Map<String, dynamic> json) => NotificationApiModel(
        id: json['id']?.toString() ?? '',
        type: json['type']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        isRead: _toBool(json['is_read'] ?? json['isRead']),
        invitation: json['invitation'] is Map<String, dynamic>
            ? NotificationInvitationModel.fromJson(json['invitation'] as Map<String, dynamic>)
            : null,
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
      );
}

bool _toBool(dynamic value) {
  if (value == null) return false;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  return normalized == 'true' || normalized == '1';
}

DateTime _parseDate(dynamic value) {
  if (value == null) return DateTime.now();
  return DateTime.tryParse(value.toString()) ?? DateTime.now();
}
