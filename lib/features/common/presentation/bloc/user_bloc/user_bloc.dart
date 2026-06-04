import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRemoteDataSource userRemoteDataSource;

  UserBloc({required this.userRemoteDataSource}) : super(const UserState()) {
    on<UserProfileRequested>(handleProfileRequested);
    on<UserProfileReset>(handleProfileReset);
    on<UserProfileUpdated>(handleProfileUpdated);
    on<UserProfileDelete>(handleProfileDelete);
  }

  void handleProfileReset(UserProfileReset event, Emitter<UserState> emit) {
    emit(const UserState());
  }

  Future<void> handleProfileRequested(UserProfileRequested event, Emitter<UserState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final profile = await userRemoteDataSource.fetchProfile();
      emit(state.copyWith(status: Status.success, profile: profile, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }

  Future<void> handleProfileUpdated(UserProfileUpdated event, Emitter<UserState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      if (state.profile == null) return;
      final profile = await userRemoteDataSource.updateProfile(
          firstName: event.firstName ?? state.profile!.firstName,
          lastName: event.lastName ?? state.profile!.lastName,
          language: event.language ?? state.profile!.language,
          profilePictureId: event.profilePictureId ?? state.profile!.profilePictureId);
      emit(state.copyWith(status: Status.success, profile: profile, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }

  Future<void> handleProfileDelete(UserProfileDelete event, Emitter<UserState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      await userRemoteDataSource.deleteProfile();
      emit(state.copyWith(status: Status.success, profile: null, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
