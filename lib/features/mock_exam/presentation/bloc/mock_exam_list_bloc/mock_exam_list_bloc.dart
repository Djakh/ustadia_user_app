import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/features/mock_exam/data/datasources/mock_exam_remote_data_source.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/bloc/mock_exam_list_bloc/mock_exam_list_event.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/bloc/mock_exam_list_bloc/mock_exam_list_state.dart';

class MockExamListBloc extends Bloc<MockExamListEvent, MockExamListState> {
  final MockExamRemoteDataSource mockExamRemoteDataSource;

  MockExamListBloc({required this.mockExamRemoteDataSource}) : super(const MockExamListState()) {
    on<MockExamListRequested>(handleMockExamsRequested);
    on<MockExamListLoadMoreRequested>(handleMockExamsLoadMoreRequested);
  }

  Future<void> handleMockExamsRequested(
      MockExamListRequested event, Emitter<MockExamListState> emit) async {
    if (event.showLoading || state.exams.isEmpty) {
      emit(state.copyWith(
          status: Status.loading,
          exams: const [],
          pagination: const PaginationMeta(),
          isLoadingMore: false,
          errorMessage: null));
    } else {
      emit(state.copyWith(isLoadingMore: false, errorMessage: null));
    }
    try {
      final result =
          await mockExamRemoteDataSource.fetchMockExams(page: event.page, limit: event.limit);
      emit(state.copyWith(
          status: Status.success,
          exams: result.items,
          pagination: result.meta,
          errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: event.showLoading || state.exams.isEmpty ? Status.error : state.status,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: event.showLoading || state.exams.isEmpty ? Status.error : state.status,
          errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  Future<void> handleMockExamsLoadMoreRequested(
      MockExamListLoadMoreRequested event, Emitter<MockExamListState> emit) async {
    if (state.isLoadingMore || !state.pagination.hasNext) return;
    emit(state.copyWith(isLoadingMore: true));
    try {
      final result = await mockExamRemoteDataSource.fetchMockExams(
          page: state.pagination.page + 1, limit: state.pagination.limit);
      emit(state.copyWith(
          status: Status.success,
          exams: [...state.exams, ...result.items],
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
