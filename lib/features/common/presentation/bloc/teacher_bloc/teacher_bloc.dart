import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/teacher_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_state.dart';

class TeacherBloc extends Bloc<TeacherEvent, TeacherState> {
  final UserRemoteDataSource userRemoteDataSource;
  final AuthLocalDataSource authLocalDataSource;

  TeacherBloc({required this.userRemoteDataSource, required this.authLocalDataSource})
      : super(const TeacherState()) {
    on<TeachersRequested>(handleTeachersRequested);
    on<TeacherSwapRequested>(handleTeacherSwapRequested);
  }

  Future<void> handleTeachersRequested(
      TeachersRequested event, Emitter<TeacherState> emit) async {
    emit(state.copyWith(
      status: Status.loading,
      teachers: const [],
      errorMessage: null,
    ));
    try {
      final teachers = await userRemoteDataSource.fetchTeachers();
      emit(state.copyWith(status: Status.success, teachers: teachers, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }

  Future<void> handleTeacherSwapRequested(
      TeacherSwapRequested event, Emitter<TeacherState> emit) async {
    if (state.swapStatus == Status.loading) return;
    emit(state.copyWith(
      swapStatus: Status.loading,
      swapErrorMessage: null,
      swapMessage: null,
      swappingTeacherId: event.teacherId,
    ));
    try {
      final response = await userRemoteDataSource.swapTeacher(teacherId: event.teacherId);
      await authLocalDataSource.setAccessToken(response.accessToken);
      final updatedTeachers = markActiveTeacher(
        state.teachers,
        response.teacherId.isNotEmpty ? response.teacherId : event.teacherId,
      );
      emit(state.copyWith(
        swapStatus: Status.success,
        teachers: updatedTeachers,
        swapMessage: response.message,
        swappingTeacherId: null,
      ));
    } on DioException catch (error) {
      emit(state.copyWith(
        swapStatus: Status.error,
        swapErrorMessage: DioErrorMessage.from(error),
        swappingTeacherId: null,
      ));
    } catch (_) {
      emit(state.copyWith(
        swapStatus: Status.error,
        swapErrorMessage: 'Request failed.',
        swappingTeacherId: null,
      ));
    }
  }

  List<TeacherModel> markActiveTeacher(List<TeacherModel> teachers, String teacherId) {
    return teachers
        .map((teacher) => teacher.copyWith(isActive: teacherIdentifier(teacher) == teacherId))
        .toList();
  }

  String teacherIdentifier(TeacherModel teacher) =>
      teacher.teacherId.isNotEmpty ? teacher.teacherId : teacher.id;
}
