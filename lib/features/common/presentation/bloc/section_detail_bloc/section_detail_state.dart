import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class SectionDetailState {
  final Status status;
  final SectionModel? detail;
  final String? errorMessage;

  const SectionDetailState({this.status = Status.initial, this.detail, this.errorMessage});

  SectionDetailState copyWith({Status? status, SectionModel? detail, String? errorMessage}) =>
      SectionDetailState(
          status: status ?? this.status, detail: detail ?? this.detail, errorMessage: errorMessage);
}
