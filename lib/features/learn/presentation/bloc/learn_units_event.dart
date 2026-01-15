abstract class LearnUnitsEvent {
  const LearnUnitsEvent();
}

class LearnUnitsRequested extends LearnUnitsEvent {
  final String lessonId;
  final int page;
  final int limit;

  const LearnUnitsRequested({required this.lessonId, this.page = 1, this.limit = 10});
}
