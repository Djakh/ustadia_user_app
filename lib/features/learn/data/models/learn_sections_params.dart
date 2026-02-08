import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';

class LearnSectionsParams {
  final LearnUnitModel unit;
  final String lessonId;

  const LearnSectionsParams({required this.unit, required this.lessonId});
}
