import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';

enum NotificationCategory { dailyReminder, streakReminder, featuresAndTips }

class NotificationModel extends Equatable {
  final String id;
  final String title;
  final String message;
  final String iconAsset;
  final DateTime createdAt;
  final bool isRead;
  final NotificationCategory category;

  const NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.iconAsset,
    required this.createdAt,
    required this.isRead,
    required this.category,
  });

  NotificationModel copyWith({bool? isRead}) => NotificationModel(
        id: id,
        title: title,
        message: message,
        iconAsset: iconAsset,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        category: category,
      );

  static List<NotificationModel> get mockNotifications => [
        NotificationModel(
          id: 'n-1001',
          title: 'Daily reminder',
          message: 'Review your tasks and stay on track',
          iconAsset: AppImages.notificationDailyRemainder,
          createdAt: DateTime(2025, 12, 4, 9, 10),
          isRead: false,
          category: NotificationCategory.dailyReminder,
        ),
        NotificationModel(
          id: 'n-1002',
          title: 'Streak reminders',
          message: "Keep your momentum and don't break the chain",
          iconAsset: AppImages.notificationStreakRemainders,
          createdAt: DateTime(2025, 12, 4, 8, 40),
          isRead: false,
          category: NotificationCategory.streakReminder,
        ),
        NotificationModel(
          id: 'n-1003',
          title: 'New features and tips',
          message: 'Learn how to get more out of the app',
          iconAsset: AppImages.notificationFeaturesAndTips,
          createdAt: DateTime(2025, 12, 4, 8, 5),
          isRead: true,
          category: NotificationCategory.featuresAndTips,
        ),
        NotificationModel(
          id: 'n-0999',
          title: 'Daily reminder',
          message: 'Review your tasks and stay on track',
          iconAsset: AppImages.notificationDailyRemainder,
          createdAt: DateTime(2025, 12, 3, 9, 12),
          isRead: true,
          category: NotificationCategory.dailyReminder,
        ),
        NotificationModel(
          id: 'n-0998',
          title: 'Streak reminders',
          message: "Keep your momentum and don't break the chain",
          iconAsset: AppImages.notificationStreakRemainders,
          createdAt: DateTime(2025, 12, 3, 8, 32),
          isRead: true,
          category: NotificationCategory.streakReminder,
        ),
      ];

  @override
  List<Object?> get props => [id, title, message, iconAsset, createdAt, isRead, category];
}



class NotificationSection {
  final DateTime date;
  final List<NotificationModel> items;

  const NotificationSection({required this.date, required this.items});
}