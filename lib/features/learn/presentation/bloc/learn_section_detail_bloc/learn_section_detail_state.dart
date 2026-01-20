import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';

class LearnSectionDetailState {
  final Status status;
  final LearnSectionModel? detail;
  final String? errorMessage;

  const LearnSectionDetailState({this.status = Status.initial, this.detail, this.errorMessage});

  LearnSectionDetailState copyWith(
          {Status? status, LearnSectionModel? detail, String? errorMessage}) =>
      LearnSectionDetailState(
          status: status ?? this.status,
          detail: detail ?? this.detail,
          errorMessage: errorMessage);
}
