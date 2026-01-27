import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:ustadia_user_app/features/notifications/data/models/notification_api_model.dart';
import 'package:ustadia_user_app/features/notifications/presentation/bloc/notifications_bloc/notifications_event.dart';
import 'package:ustadia_user_app/features/notifications/presentation/bloc/notifications_bloc/notifications_state.dart';

class NotificationsBloc extends Bloc<NotificationsEvent, NotificationsState> {
  final NotificationsRemoteDataSource notificationsRemoteDataSource;

  NotificationsBloc({required this.notificationsRemoteDataSource})
      : super(const NotificationsState()) {
    on<NotificationsRequested>(handleNotificationsRequested);
    on<NotificationsMarkedAllRead>(handleNotificationsMarkedAllRead);
    on<NotificationMarkedRead>(handleNotificationMarkedRead);
    on<NotificationInvitationAccepted>(handleInvitationAccepted);
    on<NotificationInvitationRejected>(handleInvitationRejected);
  }

  Future<void> handleNotificationsRequested(
      NotificationsRequested event, Emitter<NotificationsState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final notifications = await notificationsRemoteDataSource.fetchNotifications();
      emit(state.copyWith(status: Status.success, notifications: notifications, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }

  Future<void> handleNotificationMarkedRead(
      NotificationMarkedRead event, Emitter<NotificationsState> emit) async {
    await _markRead(event.notificationId, emit);
  }

  Future<void> handleNotificationsMarkedAllRead(
      NotificationsMarkedAllRead event, Emitter<NotificationsState> emit) async {
    await _markAllRead(emit);
  }

  Future<void> handleInvitationAccepted(
      NotificationInvitationAccepted event, Emitter<NotificationsState> emit) async {
    if (state.actionStatus == Status.loading) return;
    emit(state.copyWith(
      actionStatus: Status.loading,
      actionErrorMessage: null,
      actionInvitationId: event.invitationId,
    ));
    try {
      await notificationsRemoteDataSource.acceptInvitation(event.invitationId);
      final updated = _updateInvitationStatus(
          event.notificationId, event.invitationId, state.notifications, 'accepted');
      emit(state.copyWith(
        actionStatus: Status.success,
        notifications: updated,
        actionInvitationId: event.invitationId,
      ));
    } on DioException catch (error) {
      emit(state.copyWith(
          actionStatus: Status.error, actionErrorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(actionStatus: Status.error, actionErrorMessage: 'Request failed.'));
    }
  }

  Future<void> handleInvitationRejected(
      NotificationInvitationRejected event, Emitter<NotificationsState> emit) async {
    if (state.actionStatus == Status.loading) return;
    emit(state.copyWith(
      actionStatus: Status.loading,
      actionErrorMessage: null,
      actionInvitationId: event.invitationId,
    ));
    try {
      await notificationsRemoteDataSource.rejectInvitation(event.invitationId);
      final updated = _updateInvitationStatus(
          event.notificationId, event.invitationId, state.notifications, 'rejected');
      emit(state.copyWith(
        actionStatus: Status.success,
        notifications: updated,
        actionInvitationId: event.invitationId,
      ));
    } on DioException catch (error) {
      emit(state.copyWith(
          actionStatus: Status.error, actionErrorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(actionStatus: Status.error, actionErrorMessage: 'Request failed.'));
    }
  }

  List<NotificationApiModel> _updateInvitationStatus(
    String notificationId,
    String invitationId,
    List<NotificationApiModel> items,
    String status,
  ) {
    return items.map((item) {
      if (item.id != notificationId) return item;
      final invitation = item.invitation;
      if (invitation == null || invitation.id != invitationId) {
        return item.copyWith(isRead: true);
      }
      return item.copyWith(isRead: true, invitation: invitation.copyWith(status: status));
    }).toList();
  }

  Future<void> _markRead(String notificationId, Emitter<NotificationsState> emit) async {
    if (state.actionStatus == Status.loading) return;
    emit(state.copyWith(
      actionStatus: Status.loading,
      actionErrorMessage: null,
      actionInvitationId: notificationId,
    ));
    try {
      await notificationsRemoteDataSource.markNotificationRead(notificationId);
      if (emit.isDone) return;
      final updated = state.notifications
          .map((item) => item.id == notificationId ? item.copyWith(isRead: true) : item)
          .toList();
      emit(state.copyWith(
        actionStatus: Status.success,
        notifications: updated,
        actionInvitationId: notificationId,
      ));
    } on DioException catch (error) {
      if (emit.isDone) return;
      emit(state.copyWith(
          actionStatus: Status.error, actionErrorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      if (emit.isDone) return;
      emit(state.copyWith(actionStatus: Status.error, actionErrorMessage: 'Request failed.'));
    }
  }

  Future<void> _markAllRead(Emitter<NotificationsState> emit) async {
    if (state.actionStatus == Status.loading) return;
    emit(state.copyWith(
      actionStatus: Status.loading,
      actionErrorMessage: null,
      actionInvitationId: 'all',
    ));
    try {
      await notificationsRemoteDataSource.markAllNotificationsRead();
      if (emit.isDone) return;
      final updated = state.notifications.map((item) => item.copyWith(isRead: true)).toList();
      emit(state.copyWith(
        actionStatus: Status.success,
        notifications: updated,
        actionInvitationId: 'all',
      ));
    } on DioException catch (error) {
      if (emit.isDone) return;
      emit(state.copyWith(
          actionStatus: Status.error, actionErrorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      if (emit.isDone) return;
      emit(state.copyWith(actionStatus: Status.error, actionErrorMessage: 'Request failed.'));
    }
  }
}
