import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_event.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_password_state.dart';

class AuthPasswordBloc extends Bloc<AuthPasswordEvent, AuthPasswordState> {
  final AuthRemoteDataSource authRemoteDataSource;

  AuthPasswordBloc({required this.authRemoteDataSource}) : super(const AuthPasswordState()) {
    on<AuthForgotPasswordRequested>(handleForgotPassword);
    on<AuthResetPasswordRequested>(handleResetPassword);
  }

  Future<void> handleForgotPassword(
      AuthForgotPasswordRequested event, Emitter<AuthPasswordState> emit) async {
    emit(state.copyWith(
        status: AuthPasswordStatus.loading,
        action: AuthPasswordAction.forgotPassword,
        errorMessage: null));
    try {
      final message = await authRemoteDataSource.forgotPassword(email: event.email);
      emit(state.copyWith(
          status: AuthPasswordStatus.success,
          action: AuthPasswordAction.forgotPassword,
          message: message));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: AuthPasswordStatus.failure,
          action: AuthPasswordAction.forgotPassword,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: AuthPasswordStatus.failure,
          action: AuthPasswordAction.forgotPassword,
          errorMessage: 'Request failed. Please try again.'));
    }
  }

  Future<void> handleResetPassword(
      AuthResetPasswordRequested event, Emitter<AuthPasswordState> emit) async {
    emit(state.copyWith(
        status: AuthPasswordStatus.loading,
        action: AuthPasswordAction.resetPassword,
        errorMessage: null));
    try {
      final message = await authRemoteDataSource.resetPassword(
          email: event.email, otp: event.otp, newPassword: event.newPassword);
      emit(state.copyWith(
          status: AuthPasswordStatus.success,
          action: AuthPasswordAction.resetPassword,
          message: message));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: AuthPasswordStatus.failure,
          action: AuthPasswordAction.resetPassword,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: AuthPasswordStatus.failure,
          action: AuthPasswordAction.resetPassword,
          errorMessage: 'Request failed. Please try again.'));
    }
  }
}
