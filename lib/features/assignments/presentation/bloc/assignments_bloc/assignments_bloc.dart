import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/assignments/data/datasources/assignments_remote_data_source.dart';
import 'package:ustadia_user_app/features/assignments/presentation/bloc/assignments_bloc/assignments_event.dart';
import 'package:ustadia_user_app/features/assignments/presentation/bloc/assignments_bloc/assignments_state.dart';

class AssignmentsBloc extends Bloc<AssignmentsEvent, AssignmentsState> {
  final AssignmentsRemoteDataSource assignmentsRemoteDataSource;

  AssignmentsBloc({required this.assignmentsRemoteDataSource})
      : super(const AssignmentsState()) {
    on<AssignmentsRequested>(handleAssignmentsRequested);
  }

  Future<void> handleAssignmentsRequested(
      AssignmentsRequested event, Emitter<AssignmentsState> emit) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final assignments = await assignmentsRemoteDataSource.fetchAssignments();
      emit(state.copyWith(status: Status.success, assignments: assignments, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
