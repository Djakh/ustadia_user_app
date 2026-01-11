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
    on<AuthForgotPasswordPhoneRequested>(handleForgotPasswordPhone);
    on<AuthResetPasswordPhoneRequested>(handleResetPasswordPhone);
  }

  Future<void> handleForgotPassword(
      AuthForgotPasswordRequested event, Emitter<AuthPasswordState> emit) async {
    emit(state.copyWith(
        status: AuthPasswordStatus.loading,
        action: AuthPasswordAction.forgotPasswordEmail,
        errorMessage: null));
    try {
      final message = await authRemoteDataSource.forgotPassword(email: event.email);
      emit(state.copyWith(
          status: AuthPasswordStatus.success,
          action: AuthPasswordAction.forgotPasswordEmail,
          message: message));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: AuthPasswordStatus.failure,
          action: AuthPasswordAction.forgotPasswordEmail,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: AuthPasswordStatus.failure,
          action: AuthPasswordAction.forgotPasswordEmail,
          errorMessage: 'Request failed. Please try again.'));
    }
  }

  Future<void> handleResetPassword(
      AuthResetPasswordRequested event, Emitter<AuthPasswordState> emit) async {
    emit(state.copyWith(
        status: AuthPasswordStatus.loading,
        action: AuthPasswordAction.resetPasswordEmail,
        errorMessage: null));
    try {
      final message = await authRemoteDataSource.resetPassword(
          email: event.email, otp: event.otp, newPassword: event.newPassword);
      emit(state.copyWith(
          status: AuthPasswordStatus.success,
          action: AuthPasswordAction.resetPasswordEmail,
          message: message));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: AuthPasswordStatus.failure,
          action: AuthPasswordAction.resetPasswordEmail,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: AuthPasswordStatus.failure,
          action: AuthPasswordAction.resetPasswordEmail,
          errorMessage: 'Request failed. Please try again.'));
    }
  }

  Future<void> handleForgotPasswordPhone(
      AuthForgotPasswordPhoneRequested event, Emitter<AuthPasswordState> emit) async {
    emit(state.copyWith(
        status: AuthPasswordStatus.loading,
        action: AuthPasswordAction.forgotPasswordPhone,
        errorMessage: null));
    try {
      final message = await authRemoteDataSource.forgotPasswordPhone(
          phoneNumber: event.phoneNumber);
      emit(state.copyWith(
          status: AuthPasswordStatus.success,
          action: AuthPasswordAction.forgotPasswordPhone,
          message: message));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: AuthPasswordStatus.failure,
          action: AuthPasswordAction.forgotPasswordPhone,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: AuthPasswordStatus.failure,
          action: AuthPasswordAction.forgotPasswordPhone,
          errorMessage: 'Request failed. Please try again.'));
    }
  }

  Future<void> handleResetPasswordPhone(
      AuthResetPasswordPhoneRequested event, Emitter<AuthPasswordState> emit) async {
    emit(state.copyWith(
        status: AuthPasswordStatus.loading,
        action: AuthPasswordAction.resetPasswordPhone,
        errorMessage: null));
    try {
      final message = await authRemoteDataSource.resetPasswordPhone(
          phoneNumber: event.phoneNumber, otp: event.otp, newPassword: event.newPassword);
      emit(state.copyWith(
          status: AuthPasswordStatus.success,
          action: AuthPasswordAction.resetPasswordPhone,
          message: message));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: AuthPasswordStatus.failure,
          action: AuthPasswordAction.resetPasswordPhone,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: AuthPasswordStatus.failure,
          action: AuthPasswordAction.resetPasswordPhone,
          errorMessage: 'Request failed. Please try again.'));
    }
  }
}
