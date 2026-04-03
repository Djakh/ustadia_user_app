import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/assignments/data/datasources/assignments_remote_data_source.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_state.dart';

class SectionDetailBloc extends Bloc<SectionDetailEvent, SectionDetailState> {
  final LearnRemoteDataSource learnRemoteDataSource;
  final AssignmentsRemoteDataSource assignmentsRemoteDataSource;

  SectionDetailBloc(
      {required this.learnRemoteDataSource, required this.assignmentsRemoteDataSource})
      : super(const SectionDetailState()) {
    on<SectionDetailRequested>(handleSectionDetailRequested);
  }

  Future<void> handleSectionDetailRequested(
      SectionDetailRequested event, Emitter<SectionDetailState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final fetched = event.source == SectionSource.assignment
          ? await assignmentsRemoteDataSource.fetchAssignmentSectionDetail(
              assignmentId: _assignmentId(event), sectionId: event.sectionId)
          : await learnRemoteDataSource.fetchSectionDetail(sectionId: event.sectionId);
      final updatedDetail = _applyLessonUnit(fetched, event.unitId, event.lessonId);
      emit(state.copyWith(status: Status.success, detail: updatedDetail, errorMessage: null));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  String _assignmentId(SectionDetailRequested event) {
    final assignmentId = event.assignmentId;
    if (assignmentId != null && assignmentId.isNotEmpty) return assignmentId;
    throw Exception('Assignment id is missing.');
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
