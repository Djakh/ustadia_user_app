abstract class LearnSectionDetailEvent {
  const LearnSectionDetailEvent();
}

class LearnSectionDetailRequested extends LearnSectionDetailEvent {
  final String sectionId;

  const LearnSectionDetailRequested({required this.sectionId});
}
