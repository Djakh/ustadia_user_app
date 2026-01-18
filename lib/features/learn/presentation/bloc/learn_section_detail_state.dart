import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_detail_model.dart';

class LearnSectionDetailState {
  final Status status;
  final LearnSectionDetailModel? detail;
  final String? errorMessage;

  const LearnSectionDetailState({this.status = Status.initial, this.detail, this.errorMessage});

  LearnSectionDetailState copyWith(
          {Status? status, LearnSectionDetailModel? detail, String? errorMessage}) =>
      LearnSectionDetailState(
          status: status ?? this.status,
          detail: detail ?? this.detail,
          errorMessage: errorMessage);
}
