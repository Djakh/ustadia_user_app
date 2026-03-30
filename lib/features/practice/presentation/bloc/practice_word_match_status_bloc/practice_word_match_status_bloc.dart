import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/practice/data/datasources/practice_remote_data_source.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_word_match_status_bloc/practice_word_match_status_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_word_match_status_bloc/practice_word_match_status_state.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';

class PracticeWordMatchStatusBloc
    extends Bloc<PracticeWordMatchStatusEvent, PracticeWordMatchStatusState> {
  final PracticeRemoteDataSource practiceRemoteDataSource;
  final ProfileStatisticsStore profileStatisticsStore;

  PracticeWordMatchStatusBloc(
      {required this.practiceRemoteDataSource, required this.profileStatisticsStore})
      : super(const PracticeWordMatchStatusState()) {
    on<PracticeWordMatchStatusRequested>(handleStatusRequested);
  }

  Future<void> handleStatusRequested(
      PracticeWordMatchStatusRequested event, Emitter<PracticeWordMatchStatusState> emit) async {
    if (state.status == Status.loading) return;
    emit(state.copyWith(
      status: Status.loading,
      errorMessage: null,
      wordMatchId: event.wordMatchId,
      matchStatus: null,
      correctAnswers: null,
      wrongAnswers: null,
      message: null,
    ));
    try {
      final response = await practiceRemoteDataSource.updateWordMatchStatus(
        wordMatchId: event.wordMatchId,
        status: event.status,
      );
      profileStatisticsStore.markStale();
      emit(state.copyWith(
        status: Status.success,
        wordMatchId: response.wordMatchId,
        matchStatus: response.status,
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
