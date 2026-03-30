import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:ustadia_user_app/router.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint('FCM background message: ${message.messageId}');
}

@pragma('vm:entry-point')
void onDidReceiveBackgroundNotificationResponse(NotificationResponse response) {
  FirebaseMessagingService.openNotificationsPage();
}

class FirebaseMessagingService {
  FirebaseMessagingService._();
  static const _channelId = 'ustadia_general';
  static const _channelName = 'General notifications';
  static const _channelDescription = 'General notifications';
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static Future<void> _initLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false);
    const settings = InitializationSettings(android: androidSettings, iOS: iosSettings);
    await _localNotifications.initialize(settings,
        onDidReceiveNotificationResponse: (_) => openNotificationsPage(),
        onDidReceiveBackgroundNotificationResponse: onDidReceiveBackgroundNotificationResponse);
    final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(const AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
      ));
    }
  }

  static Future<void> initialize() async {
    await Firebase.initializeApp();
    await _initLocalNotifications();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    final messaging = FirebaseMessaging.instance;
    await messaging.setAutoInitEnabled(true);
    final settings = await messaging.requestPermission(alert: true, badge: true, sound: true);
    debugPrint('FCM permission status: ${settings.authorizationStatus}');
    String? apnsToken;
    if (Platform.isIOS) {
      await messaging.setForegroundNotificationPresentationOptions(
          alert: true, badge: true, sound: true);
      try {
        apnsToken = await messaging.getAPNSToken();
        debugPrint('APNs token: $apnsToken');
      } catch (error) {
        debugPrint('APNs token is not available yet: $error');
      }
    }

    final token = await getToken(apnsToken: apnsToken);
    debugPrint('FCM token: $token');
    messaging.onTokenRefresh.listen((newToken) {
      debugPrint('FCM token refreshed: $newToken');
    });

    FirebaseMessaging.onMessage.listen((message) async {
      debugPrint('FCM foreground message: ${message.messageId}');
      final notification = message.notification;
      final title = notification?.title ?? message.data['title']?.toString();
      final body = notification?.body ?? message.data['body']?.toString();
      if (title == null && body == null) return;
      if (Platform.isIOS) return;
      await _localNotifications.show(
        DateTime.now().millisecondsSinceEpoch ~/ 1000,
        title,
        body,
        const NotificationDetails(
            android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        )),
      );
    });

    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('FCM message opened: ${message.messageId}');
      openNotificationsPage();
    });

    final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
    if (initialMessage != null) {
      openNotificationsPage();
    }
  }

  static void openNotificationsPage() {
    Future.microtask(() => appRouter.go(notificationsRoute));
  }

  static Future<String?> getToken({String? apnsToken}) async {
    try {
      if (Platform.isIOS) {
        final currentApnsToken = apnsToken ?? await FirebaseMessaging.instance.getAPNSToken();
        if (currentApnsToken == null || currentApnsToken.isEmpty) {
          debugPrint('Skipping FCM token fetch because APNs token is not available yet.');
          return null;
        }
      }
      return await FirebaseMessaging.instance.getToken();
    } catch (error) {
      debugPrint('Failed to get FCM token: $error');
      return null;
    }
  }

  static String deviceType() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
