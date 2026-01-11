import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_models.dart';

enum IntroSurveyStatus { initial, loading, success, failure }
enum IntroSurveySubmissionStatus { idle, submitting, success, failure }

class IntroSurveyState {
  final IntroSurveyStatus status;
  final List<IntroSurveyQuestionModel> questions;
  final String? errorMessage;
  final IntroSurveySubmissionStatus submissionStatus;
  final String? submissionQuestionId;
  final String? submissionErrorMessage;

  const IntroSurveyState({
    this.status = IntroSurveyStatus.initial,
    this.questions = const [],
    this.errorMessage,
    this.submissionStatus = IntroSurveySubmissionStatus.idle,
    this.submissionQuestionId,
    this.submissionErrorMessage
  });

  IntroSurveyState copyWith({
    IntroSurveyStatus? status,
    List<IntroSurveyQuestionModel>? questions,
    String? errorMessage,
    IntroSurveySubmissionStatus? submissionStatus,
    String? submissionQuestionId,
    String? submissionErrorMessage
  }) =>
      IntroSurveyState(
        status: status ?? this.status,
        questions: questions ?? this.questions,
        errorMessage: errorMessage,
        submissionStatus: submissionStatus ?? this.submissionStatus,
        submissionQuestionId: submissionQuestionId ?? this.submissionQuestionId,
        submissionErrorMessage: submissionErrorMessage
      );
}
