import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/services/firebase_messaging_service.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_event.dart';
import 'package:ustadia_user_app/router.dart';

class SessionLogoutService {
  static bool isLoggingOut = false;

  static Future<void> logout(
      {required AuthLocalDataSource authLocalDataSource,
      UserRemoteDataSource? userRemoteDataSource,
      bool unregisterDevice = true}) async {
    if (isLoggingOut) return;
    isLoggingOut = true;
    try {
      if (unregisterDevice && userRemoteDataSource != null) {
        final token = await FirebaseMessagingService.getToken();
        final deviceType = FirebaseMessagingService.deviceType();
        if (token != null && token.isNotEmpty) {
          try {
            await userRemoteDataSource.unregisterDevice(
                token: token, deviceType: deviceType, skipUnauthorizedLogout: true);
          } catch (_) {}
        }
      }
      await authLocalDataSource.clearAccessToken();
      final rootContext = rootNavigatorKey.currentContext;
      if (rootContext != null && rootContext.mounted) {
        try {
          rootContext.read<TeacherBloc>().add(const TeachersReset());
        } catch (_) {}
      }
      appRouter.go(loginRoute);
    } finally {
      Future<void>.delayed(const Duration(milliseconds: 300), () {
        isLoggingOut = false;
      });
    }
  }
}
