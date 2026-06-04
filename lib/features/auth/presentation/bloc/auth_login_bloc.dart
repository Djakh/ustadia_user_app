import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/network/dio_client.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/core/services/firebase_messaging_service.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_login_event.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_login_state.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';

class AuthLoginBloc extends Bloc<AuthLoginEvent, AuthLoginState> {
  final AuthRemoteDataSource authRemoteDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final UserRemoteDataSource userRemoteDataSource;

  AuthLoginBloc(
      {required this.authRemoteDataSource,
      required this.authLocalDataSource,
      required this.userRemoteDataSource})
      : super(const AuthLoginState()) {
    on<AuthLoginWithEmailRequested>(handleLoginWithEmail);
    on<AuthLoginWithPhoneRequested>(handleLoginWithPhone);
  }

  Future<void> handleLoginWithEmail(
      AuthLoginWithEmailRequested event, Emitter<AuthLoginState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final response =
          await authRemoteDataSource.loginWithEmail(email: event.email, password: event.password);
      await authLocalDataSource.setAccessToken(response.accessToken);
      final accessToken = await _resetTeacherToSystemLessons();
      await _registerDeviceToken();
      emit(state.copyWith(status: Status.success, accessToken: accessToken, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Login failed. Please try again.'));
    }
  }

  Future<void> handleLoginWithPhone(
      AuthLoginWithPhoneRequested event, Emitter<AuthLoginState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final response = await authRemoteDataSource.loginWithPhone(
          phoneNumber: event.phoneNumber, password: event.password);
      await authLocalDataSource.setAccessToken(response.accessToken);
      final accessToken = await _resetTeacherToSystemLessons();
      await _registerDeviceToken();
      emit(state.copyWith(status: Status.success, accessToken: accessToken, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Login failed. Please try again.'));
    }
  }

  Future<void> _registerDeviceToken() async {
    final token = await FirebaseMessagingService.getToken();
    if (token == null || token.isEmpty) return;
    final deviceType = FirebaseMessagingService.deviceType();
    try {
      await userRemoteDataSource.registerDevice(token: token, deviceType: deviceType);
    } catch (_) {}
  }

  Future<String> _resetTeacherToSystemLessons() async {
    final response = await userRemoteDataSource.swapTeacher(teacherId: null);
    if (response.accessToken.isNotEmpty) {
      await authLocalDataSource.setAccessToken(response.accessToken);
    }
    await DioClient.clearCache();
    return authLocalDataSource.getAccessToken();
  }
}
