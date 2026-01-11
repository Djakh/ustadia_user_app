import 'package:flutter_bloc/flutter_bloc.dart';
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
    IntroSurveyRequested event,
    Emitter<IntroSurveyState> emit
  ) async {
    emit(state.copyWith(status: IntroSurveyStatus.loading));
    try {
      final questions =
          await introSurveyRemoteDataSource.fetchQuestions(page: event.page, limit: event.limit);
      emit(state.copyWith(status: IntroSurveyStatus.success, questions: questions, errorMessage: null));
    } catch (error) {
      emit(state.copyWith(status: IntroSurveyStatus.failure, errorMessage: error.toString()));
    }
  }

  Future<void> onIntroSurveyAnswerSubmitted(
    IntroSurveyAnswerSubmitted event,
    Emitter<IntroSurveyState> emit
  ) async {
    emit(state.copyWith(
        submissionStatus: IntroSurveySubmissionStatus.submitting,
        submissionQuestionId: event.questionId,
        submissionErrorMessage: null));
    try {
      final submitted = await introSurveyRemoteDataSource.submitAnswers(
          questionId: event.questionId, answerIds: event.answerIds);
      if (!submitted) {
        emit(state.copyWith(
            submissionStatus: IntroSurveySubmissionStatus.failure,
            submissionQuestionId: event.questionId,
            submissionErrorMessage: 'Submission failed'));
        return;
      }
      emit(state.copyWith(
          submissionStatus: IntroSurveySubmissionStatus.success,
          submissionQuestionId: event.questionId,
          submissionErrorMessage: null));
    } catch (error) {
      emit(state.copyWith(
          submissionStatus: IntroSurveySubmissionStatus.failure,
          submissionQuestionId: event.questionId,
          submissionErrorMessage: error.toString()));
    }
  }
}
