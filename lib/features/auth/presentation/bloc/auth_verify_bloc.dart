import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_verify_event.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_verify_state.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

class AuthVerifyBloc extends Bloc<AuthVerifyEvent, AuthVerifyState> {
  final AuthRemoteDataSource authRemoteDataSource;
  final AuthLocalDataSource authLocalDataSource;

  AuthVerifyBloc({required this.authRemoteDataSource, required this.authLocalDataSource})
      : super(const AuthVerifyState()) {
    on<AuthVerifyOtpRequested>(handleVerifyOtp);
  }

  Future<void> handleVerifyOtp(
      AuthVerifyOtpRequested event, Emitter<AuthVerifyState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final accessToken =
          await authRemoteDataSource.verifyOtp(tempId: event.tempId, otp: event.otp);
      await authLocalDataSource.setAccessToken(accessToken);
      emit(state.copyWith(
          status: Status.success, accessToken: accessToken, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: Status.error, errorMessage: 'Request failed. Please try again.'));
    }
  }
}
