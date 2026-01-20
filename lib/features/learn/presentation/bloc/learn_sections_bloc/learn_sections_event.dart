abstract class LearnSectionsEvent {
  const LearnSectionsEvent();
}

class LearnSectionsRequested extends LearnSectionsEvent {
  final String unitId;
  final int page;
  final int limit;

  const LearnSectionsRequested({required this.unitId, this.page = 1, this.limit = 10});
}

class LearnSectionsLoadMoreRequested extends LearnSectionsEvent {
  final String unitId;

  const LearnSectionsLoadMoreRequested({required this.unitId});
}
