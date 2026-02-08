import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

abstract class SectionDetailEvent {
  const SectionDetailEvent();
}

class SectionDetailRequested extends SectionDetailEvent {
  final String sectionId;
  final SectionSource source;
  final String? unitId;
  final String? lessonId;

  const SectionDetailRequested(
      {required this.sectionId, this.source = SectionSource.learn, this.unitId, this.lessonId});
}
