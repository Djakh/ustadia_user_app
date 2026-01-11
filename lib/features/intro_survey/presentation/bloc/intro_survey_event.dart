abstract class IntroSurveyEvent {
  const IntroSurveyEvent();
}

class IntroSurveyRequested extends IntroSurveyEvent {
  final int page;
  final int limit;

  const IntroSurveyRequested({this.page = 1, this.limit = 10});
}

class IntroSurveyAnswerSubmitted extends IntroSurveyEvent {
  final String questionId;
  final List<String> answerIds;

  const IntroSurveyAnswerSubmitted({required this.questionId, required this.answerIds});
}
