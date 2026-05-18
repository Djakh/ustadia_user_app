import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/practice/data/datasources/practice_remote_data_source.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_session_bloc/monkey_type_session_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_session_bloc/monkey_type_session_state.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';

class MonkeyTypeSessionBloc extends Bloc<MonkeyTypeSessionEvent, MonkeyTypeSessionState> {
  final PracticeRemoteDataSource practiceRemoteDataSource;
  final ProfileStatisticsStore profileStatisticsStore;

  MonkeyTypeSessionBloc({
    required this.practiceRemoteDataSource,
    required this.profileStatisticsStore,
  }) : super(const MonkeyTypeSessionState()) {
    on<MonkeyTypeTextsRequested>(handleTextsRequested);
    on<MonkeyTypeAnswerSubmitted>(handleAnswerSubmitted);
  }

  Future<void> handleTextsRequested(
      MonkeyTypeTextsRequested event, Emitter<MonkeyTypeSessionState> emit) async {
    if (event.practiceId.isEmpty) return;
    emit(state.copyWith(status: Status.loading, texts: const [], errorMessage: null));
    try {
      final texts = await practiceRemoteDataSource.fetchMonkeyTypeTexts(event.practiceId);
      emit(state.copyWith(status: Status.success, texts: texts, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }

  Future<void> handleAnswerSubmitted(
      MonkeyTypeAnswerSubmitted event, Emitter<MonkeyTypeSessionState> emit) async {
    emit(state.copyWith(submitStatus: Status.loading, submitErrorMessage: null));
    try {
      final answer = await practiceRemoteDataSource.submitMonkeyTypeAnswer(
          practiceId: event.practiceId,
          text: event.text,
          wpm: event.wpm,
          accuracy: event.accuracy,
          correctChars: event.correctChars,
          totalChars: event.totalChars,
          timeTakenSeconds: event.timeTakenSeconds);
      profileStatisticsStore.refresh();
      emit(state.copyWith(submitStatus: Status.success, answer: answer, submitErrorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          submitStatus: Status.error, submitErrorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(submitStatus: Status.error, submitErrorMessage: 'Request failed.'));
    }
  }
}
