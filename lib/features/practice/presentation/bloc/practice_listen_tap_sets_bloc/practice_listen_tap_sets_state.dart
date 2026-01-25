import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_listen_tap_set_model.dart';

class PracticeListenTapSetsState extends Equatable {
  final Status status;
  final List<PracticeListenTapSetModel> sets;
  final String? errorMessage;

  const PracticeListenTapSetsState({
    this.status = Status.initial,
    this.sets = const [],
    this.errorMessage,
  });

  PracticeListenTapSetsState copyWith({
    Status? status,
    List<PracticeListenTapSetModel>? sets,
    String? errorMessage,
  }) {
    return PracticeListenTapSetsState(
      status: status ?? this.status,
      sets: sets ?? this.sets,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, sets, errorMessage];
}
