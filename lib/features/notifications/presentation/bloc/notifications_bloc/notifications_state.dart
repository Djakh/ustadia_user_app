import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/notifications/data/models/notification_api_model.dart';

class NotificationsState extends Equatable {
  final Status status;
  final String? errorMessage;
  final List<NotificationApiModel> notifications;
  final Status actionStatus;
  final String? actionErrorMessage;
  final String? actionInvitationId;

  const NotificationsState({
    this.status = Status.initial,
    this.errorMessage,
    this.notifications = const [],
    this.actionStatus = Status.initial,
    this.actionErrorMessage,
    this.actionInvitationId,
  });

  NotificationsState copyWith({
    Status? status,
    String? errorMessage,
    List<NotificationApiModel>? notifications,
    Status? actionStatus,
    String? actionErrorMessage,
    String? actionInvitationId,
  }) =>
      NotificationsState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        notifications: notifications ?? this.notifications,
        actionStatus: actionStatus ?? this.actionStatus,
        actionErrorMessage: actionErrorMessage,
        actionInvitationId: actionInvitationId,
      );

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        notifications,
        actionStatus,
        actionErrorMessage,
        actionInvitationId,
      ];
}
