import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
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
      final detail = event.source == SectionSource.assignment
          ? await assignmentsRemoteDataSource.fetchAssignmentSectionDetail(
              sectionId: event.sectionId)
          : await learnRemoteDataSource.fetchSectionDetail(sectionId: event.sectionId);
      emit(state.copyWith(status: Status.success, detail: detail, errorMessage: null));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: error.toString()));
    }
  }
}
