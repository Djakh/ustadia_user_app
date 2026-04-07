import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/practice/data/datasources/practice_remote_data_source.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_status_bloc/practice_sentence_builder_status_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_status_bloc/practice_sentence_builder_status_state.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';

class PracticeSentenceBuilderStatusBloc
    extends Bloc<PracticeSentenceBuilderStatusEvent, PracticeSentenceBuilderStatusState> {
  final PracticeRemoteDataSource practiceRemoteDataSource;
  final ProfileStatisticsStore profileStatisticsStore;

  PracticeSentenceBuilderStatusBloc(
      {required this.practiceRemoteDataSource, required this.profileStatisticsStore})
      : super(const PracticeSentenceBuilderStatusState()) {
    on<PracticeSentenceBuilderStatusRequested>(handleStatusRequested);
  }

  Future<void> handleStatusRequested(PracticeSentenceBuilderStatusRequested event,
      Emitter<PracticeSentenceBuilderStatusState> emit) async {
    if (state.status == Status.loading) return;
    emit(state.copyWith(
      status: Status.loading,
      errorMessage: null,
      sentenceBuilderId: event.sentenceBuilderId,
      sentenceBuilderStatus: null,
      correctAnswers: null,
      wrongAnswers: null,
      message: null,
    ));
    try {
      final response = await practiceRemoteDataSource.updateSentenceBuilderStatus(
        sentenceBuilderId: event.sentenceBuilderId,
        status: event.status,
        correctAnswers: event.correctAnswers,
        wrongAnswers: event.wrongAnswers,
      );
      profileStatisticsStore.markStale();
      emit(state.copyWith(
        status: Status.success,
        sentenceBuilderId: response.sentenceBuilderId,
        sentenceBuilderStatus: response.status,
        correctAnswers: response.correctAnswers,
        wrongAnswers: response.wrongAnswers,
        message: response.message,
      ));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
