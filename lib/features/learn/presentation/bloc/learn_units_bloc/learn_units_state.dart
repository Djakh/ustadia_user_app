import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';

class LearnUnitsState {
  final Status status;
  final List<LearnUnitModel> units;
  final String? errorMessage;
  final String? lessonId;

  const LearnUnitsState(
      {this.status = Status.initial,
      this.units = const [],
      this.errorMessage,
      this.lessonId});

  LearnUnitsState copyWith(
          {Status? status,
          List<LearnUnitModel>? units,
          String? errorMessage,
          String? lessonId}) =>
      LearnUnitsState(
          status: status ?? this.status,
          units: units ?? this.units,
          errorMessage: errorMessage,
          lessonId: lessonId ?? this.lessonId);
}
