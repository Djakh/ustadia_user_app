import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/notifications/data/models/notification_api_model.dart';

class NotificationsRemoteDataSource {
  final Dio dio;

  NotificationsRemoteDataSource({required this.dio});

  Future<List<NotificationApiModel>> fetchNotifications() async {
    final response = await dio.get('/notifications');
    final data = response.data;
    final items = data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(NotificationApiModel.fromJson)
        .toList();
  }

  Future<void> markNotificationRead(String notificationId) async {
    await dio.post('/notifications/$notificationId/read');
  }

  Future<void> markAllNotificationsRead() async {
    await dio.post('/notifications/read/all');
  }

  Future<void> acceptInvitation(String invitationId) async {
    await dio.post('/notifications/invitations/$invitationId/accept');
  }

  Future<void> rejectInvitation(String invitationId) async {
    await dio.post('/notifications/invitations/$invitationId/reject');
  }
}
