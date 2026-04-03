import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/intro_survey/data/datasources/intro_survey_remote_data_source.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/bloc/intro_survey_event.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/bloc/intro_survey_state.dart';

class IntroSurveyBloc extends Bloc<IntroSurveyEvent, IntroSurveyState> {
  final IntroSurveyRemoteDataSource introSurveyRemoteDataSource;

  IntroSurveyBloc({required this.introSurveyRemoteDataSource}) : super(const IntroSurveyState()) {
    on<IntroSurveyRequested>(onIntroSurveyRequested);
    on<IntroSurveyAnswerSubmitted>(onIntroSurveyAnswerSubmitted);
  }

  Future<void> onIntroSurveyRequested(
      IntroSurveyRequested event, Emitter<IntroSurveyState> emit) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final questions = await introSurveyRemoteDataSource.fetchQuestions();
      emit(state.copyWith(status: Status.success, questions: questions, errorMessage: null));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  Future<void> onIntroSurveyAnswerSubmitted(
      IntroSurveyAnswerSubmitted event, Emitter<IntroSurveyState> emit) async {
    emit(state.copyWith(
        submissionStatus: Status.loading,
        submissionQuestionId: event.questionId,
        submissionErrorMessage: null));
    try {
      final submitted = await introSurveyRemoteDataSource.submitAnswers(
          questionId: event.questionId, answerIds: event.answerIds);
      if (!submitted) {
        emit(state.copyWith(
            submissionStatus: Status.error,
            submissionQuestionId: event.questionId,
            submissionErrorMessage: 'Submission failed'));
        return;
      }
      emit(state.copyWith(
          submissionStatus: Status.success,
          submissionQuestionId: event.questionId,
          submissionErrorMessage: null));
    } catch (error) {
      emit(state.copyWith(
          submissionStatus: Status.error,
          submissionQuestionId: event.questionId,
          submissionErrorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }
}
