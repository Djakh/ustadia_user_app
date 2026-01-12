import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_register_event.dart';
import 'package:ustadia_user_app/features/auth/presentation/bloc/auth_register_state.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

class AuthRegisterBloc extends Bloc<AuthRegisterEvent, AuthRegisterState> {
  final AuthRemoteDataSource authRemoteDataSource;

  AuthRegisterBloc({required this.authRemoteDataSource}) : super(const AuthRegisterState()) {
    on<AuthRegisterWithEmailRequested>(handleRegisterWithEmail);
    on<AuthRegisterWithPhoneRequested>(handleRegisterWithPhone);
  }

  Future<void> handleRegisterWithEmail(
      AuthRegisterWithEmailRequested event, Emitter<AuthRegisterState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final tempId = await authRemoteDataSource.registerWithEmail(
          firstName: event.firstName,
          lastName: event.lastName,
          email: event.email,
          password: event.password);
      emit(state.copyWith(status: Status.success, tempId: tempId, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: Status.error, errorMessage: 'Request failed. Please try again.'));
    }
  }

  Future<void> handleRegisterWithPhone(
      AuthRegisterWithPhoneRequested event, Emitter<AuthRegisterState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final tempId = await authRemoteDataSource.registerWithPhone(
          firstName: event.firstName,
          lastName: event.lastName,
          phoneNumber: event.phoneNumber,
          password: event.password);
      emit(state.copyWith(status: Status.success, tempId: tempId, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: Status.error, errorMessage: 'Request failed. Please try again.'));
    }
  }
}
