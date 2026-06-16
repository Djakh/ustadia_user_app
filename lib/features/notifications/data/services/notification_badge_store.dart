import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ustadia_user_app/core/services/firebase_messaging_service.dart';
import 'package:ustadia_user_app/features/notifications/data/datasources/notifications_remote_data_source.dart';
import 'package:ustadia_user_app/features/notifications/data/models/notification_api_model.dart';

class NotificationBadgeStore {
  final NotificationsRemoteDataSource notificationsRemoteDataSource;
  final ValueNotifier<int> unreadCount = ValueNotifier<int>(0);

  StreamSubscription? _messageSubscription;
  Future<void>? _refreshOperation;
  DateTime? _lastRefreshAt;

  NotificationBadgeStore({required this.notificationsRemoteDataSource}) {
    _messageSubscription =
        FirebaseMessagingService.notificationMessages.listen((_) => refresh(force: true));
  }

  Future<void> refreshIfNeeded() {
    final lastRefreshAt = _lastRefreshAt;
    if (lastRefreshAt != null &&
        DateTime.now().difference(lastRefreshAt) < const Duration(minutes: 1)) {
      return Future<void>.value();
    }
    return refresh();
  }

  Future<void> refresh({bool force = false}) {
    if (_refreshOperation != null && !force) return _refreshOperation!;
    final operation = _refresh();
    _refreshOperation = operation;
    unawaited(operation.whenComplete(() {
      if (identical(_refreshOperation, operation)) {
        _refreshOperation = null;
      }
    }));
    return operation;
  }

  Future<void> _refresh() async {
    try {
      final notifications = await notificationsRemoteDataSource.fetchNotifications();
      setNotifications(notifications);
      _lastRefreshAt = DateTime.now();
    } catch (error) {
      debugPrint('[NotificationBadgeStore] refresh failed: $error');
    }
  }

  void setNotifications(List<NotificationApiModel> notifications) {
    final nextCount = notifications.where((item) => !item.isRead).length;
    if (unreadCount.value == nextCount) return;
    unreadCount.value = nextCount;
  }

  void markReadLocally(String notificationId) {
    if (unreadCount.value <= 0) return;
    unreadCount.value -= 1;
  }

  void markAllReadLocally() {
    if (unreadCount.value == 0) return;
    unreadCount.value = 0;
  }

  void dispose() {
    _messageSubscription?.cancel();
    unreadCount.dispose();
  }
}
