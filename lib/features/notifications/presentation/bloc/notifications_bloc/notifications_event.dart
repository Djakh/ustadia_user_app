import 'package:equatable/equatable.dart';

abstract class NotificationsEvent extends Equatable {
  const NotificationsEvent();

  @override
  List<Object?> get props => [];
}

class NotificationsRequested extends NotificationsEvent {
  const NotificationsRequested();
}

class NotificationsMarkedAllRead extends NotificationsEvent {
  const NotificationsMarkedAllRead();
}

class NotificationMarkedRead extends NotificationsEvent {
  final String notificationId;

  const NotificationMarkedRead({required this.notificationId});

  @override
  List<Object?> get props => [notificationId];
}

class NotificationInvitationAccepted extends NotificationsEvent {
  final String notificationId;
  final String invitationId;

  const NotificationInvitationAccepted({
    required this.notificationId,
    required this.invitationId,
  });

  @override
  List<Object?> get props => [notificationId, invitationId];
}

class NotificationInvitationRejected extends NotificationsEvent {
  final String notificationId;
  final String invitationId;

  const NotificationInvitationRejected({
    required this.notificationId,
    required this.invitationId,
  });

  @override
  List<Object?> get props => [notificationId, invitationId];
}
