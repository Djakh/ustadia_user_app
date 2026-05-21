import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/features/meets/data/datasources/student_meets_remote_data_source.dart';
import 'package:ustadia_user_app/features/meets/presentation/bloc/student_meets_bloc/student_meets_event.dart';
import 'package:ustadia_user_app/features/meets/presentation/bloc/student_meets_bloc/student_meets_state.dart';

class StudentMeetsBloc extends Bloc<StudentMeetsEvent, StudentMeetsState> {
  final StudentMeetsRemoteDataSource studentMeetsRemoteDataSource;

  StudentMeetsBloc({required this.studentMeetsRemoteDataSource})
      : super(const StudentMeetsState()) {
    on<StudentMeetsRequested>(handleMeetsRequested);
    on<StudentMeetsLoadMoreRequested>(handleMeetsLoadMoreRequested);
  }

  Future<void> handleMeetsRequested(
      StudentMeetsRequested event, Emitter<StudentMeetsState> emit) async {
    if (event.showLoading || state.meets.isEmpty) {
      emit(state.copyWith(
          status: Status.loading,
          meets: const [],
          pagination: const PaginationMeta(),
          isLoadingMore: false,
          errorMessage: null));
    } else {
      emit(state.copyWith(isLoadingMore: false, errorMessage: null));
    }
    try {
      final result =
          await studentMeetsRemoteDataSource.fetchMeets(page: event.page, limit: event.limit);
      emit(state.copyWith(
          status: Status.success,
          meets: result.items,
          pagination: result.meta,
          isLoadingMore: false,
          errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: event.showLoading || state.meets.isEmpty ? Status.error : state.status,
          isLoadingMore: false,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: event.showLoading || state.meets.isEmpty ? Status.error : state.status,
          isLoadingMore: false,
          errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  Future<void> handleMeetsLoadMoreRequested(
      StudentMeetsLoadMoreRequested event, Emitter<StudentMeetsState> emit) async {
    if (state.isLoadingMore || !state.pagination.hasNext) return;
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    try {
      final result = await studentMeetsRemoteDataSource.fetchMeets(
          page: state.pagination.page + 1, limit: state.pagination.limit);
      emit(state.copyWith(
          status: Status.success,
          meets: [...state.meets, ...result.items],
          pagination: result.meta,
          isLoadingMore: false,
          errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }
}
