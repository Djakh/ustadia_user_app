import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/mock_exam/data/datasources/mock_exam_remote_data_source.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/bloc/mock_exam_sections_bloc/mock_exam_sections_event.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/bloc/mock_exam_sections_bloc/mock_exam_sections_state.dart';

class MockExamSectionsBloc extends Bloc<MockExamSectionsEvent, MockExamSectionsState> {
  final MockExamRemoteDataSource mockExamRemoteDataSource;

  MockExamSectionsBloc({required this.mockExamRemoteDataSource})
      : super(const MockExamSectionsState()) {
    on<MockExamSectionsRequested>(handleMockExamSectionsRequested);
    on<MockExamFinishRequested>(handleMockExamFinishRequested);
  }

  Future<void> handleMockExamSectionsRequested(
      MockExamSectionsRequested event, Emitter<MockExamSectionsState> emit) async {
    if (event.showLoading || state.attempt == null) {
      emit(state.copyWith(
          status: Status.loading,
          actionStatus: Status.initial,
          sections: const [],
          errorMessage: null));
    } else {
      emit(state.copyWith(actionStatus: Status.initial, errorMessage: null));
    }
    try {
      final attempt = event.exam == null
          ? await mockExamRemoteDataSource.startMockExamAttempt(mockExamId: event.mockExamId)
          : await mockExamRemoteDataSource.startMockExamAttemptFromExam(event.exam!);
      final sections = attempt.components
          .expand((component) =>
              component.subSections.isNotEmpty ? component.subSections : [component.directSection])
          .toList();
      emit(state.copyWith(
          status: Status.success, attempt: attempt, sections: sections, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: event.showLoading || state.attempt == null ? Status.error : state.status,
          actionStatus: event.showLoading ? state.actionStatus : Status.error,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: event.showLoading || state.attempt == null ? Status.error : state.status,
          actionStatus: event.showLoading ? state.actionStatus : Status.error,
          errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  Future<void> handleMockExamFinishRequested(
      MockExamFinishRequested event, Emitter<MockExamSectionsState> emit) async {
    emit(state.copyWith(actionStatus: Status.loading, errorMessage: null));
    try {
      final result = await mockExamRemoteDataSource.finishMockExam(
          mockExamId: event.mockExamId, attemptId: event.attemptId);
      emit(state.copyWith(actionStatus: Status.success, result: result, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(actionStatus: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          actionStatus: Status.error, errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }
}
