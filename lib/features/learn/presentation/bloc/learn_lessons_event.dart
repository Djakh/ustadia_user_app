abstract class LearnLessonsEvent {
  const LearnLessonsEvent();
}

class LearnLessonsRequested extends LearnLessonsEvent {
  final int page;
  final int limit;

  const LearnLessonsRequested({this.page = 1, this.limit = 10});
}
