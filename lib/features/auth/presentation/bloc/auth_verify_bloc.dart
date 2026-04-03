import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/core/services/firebase_messaging_service.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_verify_event.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_verify_state.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';

class AuthVerifyBloc extends Bloc<AuthVerifyEvent, AuthVerifyState> {
  final AuthRemoteDataSource authRemoteDataSource;
  final AuthLocalDataSource authLocalDataSource;
  final UserRemoteDataSource userRemoteDataSource;

  AuthVerifyBloc(
      {required this.authRemoteDataSource,
      required this.authLocalDataSource,
      required this.userRemoteDataSource})
      : super(const AuthVerifyState()) {
    on<AuthVerifyOtpRequested>(handleVerifyOtp);
    on<AuthResendOtpRequested>(handleResendOtp);
  }

  Future<void> handleVerifyOtp(AuthVerifyOtpRequested event, Emitter<AuthVerifyState> emit) async {
    emit(state.copyWith(
        status: Status.loading,
        action: AuthVerifyAction.verifyOtp,
        errorMessage: null,
        clearMessage: true));
    try {
      final accessToken =
          await authRemoteDataSource.verifyOtp(tempId: event.tempId, otp: event.otp);
      await authLocalDataSource.setAccessToken(accessToken);
      await _registerDeviceToken();
      emit(state.copyWith(
          status: Status.success,
          action: AuthVerifyAction.verifyOtp,
          accessToken: accessToken,
          errorMessage: null,
          clearMessage: true));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: Status.error,
          action: AuthVerifyAction.verifyOtp,
          errorMessage: DioErrorMessage.from(error),
          clearMessage: true));
    } catch (error) {
      emit(state.copyWith(
          status: Status.error,
          action: AuthVerifyAction.verifyOtp,
          errorMessage: 'Request failed. Please try again.',
          clearMessage: true));
    }
  }

  Future<void> handleResendOtp(AuthResendOtpRequested event, Emitter<AuthVerifyState> emit) async {
    emit(state.copyWith(
        status: Status.loading,
        action: AuthVerifyAction.resendOtp,
        errorMessage: null,
        clearAccessToken: true,
        clearMessage: true));
    try {
      final message = await authRemoteDataSource.resendOtp(tempId: event.tempId);
      emit(state.copyWith(
          status: Status.success,
          action: AuthVerifyAction.resendOtp,
          message: message,
          errorMessage: null,
          clearAccessToken: true));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: Status.error,
          action: AuthVerifyAction.resendOtp,
          errorMessage: DioErrorMessage.from(error),
          clearAccessToken: true,
          clearMessage: true));
    } catch (error) {
      emit(state.copyWith(
          status: Status.error,
          action: AuthVerifyAction.resendOtp,
          errorMessage: 'Request failed. Please try again.',
          clearAccessToken: true,
          clearMessage: true));
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
}
