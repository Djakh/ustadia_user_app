import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_state.dart';

class LearnSectionDetailBloc extends Bloc<LearnSectionDetailEvent, LearnSectionDetailState> {
  final LearnRemoteDataSource learnRemoteDataSource;

  LearnSectionDetailBloc({required this.learnRemoteDataSource})
      : super(const LearnSectionDetailState()) {
    on<LearnSectionDetailRequested>(handleSectionDetailRequested);
  }

  Future<void> handleSectionDetailRequested(
      LearnSectionDetailRequested event, Emitter<LearnSectionDetailState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final detail = await learnRemoteDataSource.fetchSectionDetail(sectionId: event.sectionId);
      emit(state.copyWith(status: Status.success, detail: detail, errorMessage: null));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: error.toString()));
    }
  }
}
