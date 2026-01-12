import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_models.dart';

class IntroSurveyState {
  final Status status;
  final List<IntroSurveyQuestionModel> questions;
  final String? errorMessage;
  final Status submissionStatus;
  final String? submissionQuestionId;
  final String? submissionErrorMessage;

  const IntroSurveyState({
    this.status = Status.initial,
    this.questions = const [],
    this.errorMessage,
    this.submissionStatus = Status.initial,
    this.submissionQuestionId,
    this.submissionErrorMessage
  });

  IntroSurveyState copyWith({
    Status? status,
    List<IntroSurveyQuestionModel>? questions,
    String? errorMessage,
    Status? submissionStatus,
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
