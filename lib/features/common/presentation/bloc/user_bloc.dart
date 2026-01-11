import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRemoteDataSource userRemoteDataSource;

  UserBloc({required this.userRemoteDataSource}) : super(const UserState()) {
    on<UserProfileRequested>(handleProfileRequested);
  }

  Future<void> handleProfileRequested(
      UserProfileRequested event, Emitter<UserState> emit) async {
    emit(state.copyWith(status: UserStatus.loading, errorMessage: null));
    try {
      final profile = await userRemoteDataSource.fetchProfile();
      emit(state.copyWith(status: UserStatus.success, profile: profile, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: UserStatus.failure, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(status: UserStatus.failure, errorMessage: 'Request failed.'));
    }
  }
}
