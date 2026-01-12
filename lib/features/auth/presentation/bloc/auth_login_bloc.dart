import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_login_event.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_login_state.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

class AuthLoginBloc extends Bloc<AuthLoginEvent, AuthLoginState> {
  final AuthRemoteDataSource authRemoteDataSource;
  final AuthLocalDataSource authLocalDataSource;

  AuthLoginBloc({required this.authRemoteDataSource, required this.authLocalDataSource})
      : super(const AuthLoginState()) {
    on<AuthLoginWithEmailRequested>(handleLoginWithEmail);
    on<AuthLoginWithPhoneRequested>(handleLoginWithPhone);
  }

  Future<void> handleLoginWithEmail(
      AuthLoginWithEmailRequested event, Emitter<AuthLoginState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final response = await authRemoteDataSource.loginWithEmail(
          email: event.email, password: event.password);
      await authLocalDataSource.setAccessToken(response.accessToken);
      emit(state.copyWith(
          status: Status.success,
          accessToken: response.accessToken,
          errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: Status.error, errorMessage: 'Login failed. Please try again.'));
    }
  }

  Future<void> handleLoginWithPhone(
      AuthLoginWithPhoneRequested event, Emitter<AuthLoginState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final response = await authRemoteDataSource.loginWithPhone(
          phoneNumber: event.phoneNumber, password: event.password);
      await authLocalDataSource.setAccessToken(response.accessToken);
      emit(state.copyWith(
          status: Status.success,
          accessToken: response.accessToken,
          errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: Status.error, errorMessage: 'Login failed. Please try again.'));
    }
  }
}
