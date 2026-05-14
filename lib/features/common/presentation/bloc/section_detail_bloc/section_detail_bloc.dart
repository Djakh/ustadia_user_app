import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/assignments/data/datasources/assignments_remote_data_source.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_state.dart';
import 'package:ustadia_user_app/features/mock_exam/data/datasources/mock_exam_remote_data_source.dart';

class SectionDetailBloc extends Bloc<SectionDetailEvent, SectionDetailState> {
  final LearnRemoteDataSource learnRemoteDataSource;
  final AssignmentsRemoteDataSource assignmentsRemoteDataSource;
  final MockExamRemoteDataSource mockExamRemoteDataSource;

  SectionDetailBloc(
      {required this.learnRemoteDataSource,
      required this.assignmentsRemoteDataSource,
      required this.mockExamRemoteDataSource})
      : super(const SectionDetailState()) {
    on<SectionDetailRequested>(handleSectionDetailRequested);
  }

  Future<void> handleSectionDetailRequested(
      SectionDetailRequested event, Emitter<SectionDetailState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final fetched = await fetchSectionDetail(event);
      final updatedDetail = _applyLessonUnit(fetched, event.unitId, event.lessonId);
      emit(state.copyWith(status: Status.success, detail: updatedDetail, errorMessage: null));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  Future<SectionModel> fetchSectionDetail(SectionDetailRequested event) {
    if (event.source == SectionSource.assignment) {
      return assignmentsRemoteDataSource.fetchAssignmentSectionDetail(
          assignmentId: assignmentId(event), sectionId: event.sectionId);
    }
    if (event.source == SectionSource.mockExam) {
      return mockExamRemoteDataSource.fetchMockExamSectionDetail(
          mockExamId: mockExamId(event),
          attemptId: mockAttemptId(event),
          sectionId: event.sectionId);
    }
    return learnRemoteDataSource.fetchSectionDetail(sectionId: event.sectionId);
  }

  String assignmentId(SectionDetailRequested event) {
    final assignmentId = event.assignmentId;
    if (assignmentId != null && assignmentId.isNotEmpty) return assignmentId;
    throw Exception('Assignment id is missing.');
  }

  String mockExamId(SectionDetailRequested event) {
    final mockExamId = event.mockExamId;
    if (mockExamId != null && mockExamId.isNotEmpty) return mockExamId;
    throw Exception('Mock exam id is missing.');
  }

  String mockAttemptId(SectionDetailRequested event) {
    final mockAttemptId = event.mockAttemptId;
    if (mockAttemptId != null && mockAttemptId.isNotEmpty) return mockAttemptId;
    throw Exception('Mock exam attempt id is missing.');
  }

  SectionModel _applyLessonUnit(SectionModel detail, String? unitId, String? lessonId) {
    final nextUnitId = unitId?.isNotEmpty == true ? unitId : detail.unitId;
    final nextLessonId = lessonId?.isNotEmpty == true ? lessonId : detail.lessonId;
    if ((nextUnitId == detail.unitId) && (nextLessonId == detail.lessonId)) return detail;
    final questions = detail.questions
        .map((q) => q.copyWith(unitId: nextUnitId, lessonId: nextLessonId))
        .toList();
    return detail.copyWith(unitId: nextUnitId, lessonId: nextLessonId, questions: questions);
  }
}
