import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_word_match_set_model.dart';

class PracticeWordMatchSetsState extends Equatable {
  final Status status;
  final String? errorMessage;
  final List<PracticeWordMatchSetModel> sets;

  const PracticeWordMatchSetsState({
    this.status = Status.initial,
    this.errorMessage,
    this.sets = const [],
  });

  PracticeWordMatchSetsState copyWith({
    Status? status,
    String? errorMessage,
    List<PracticeWordMatchSetModel>? sets,
  }) =>
      PracticeWordMatchSetsState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        sets: sets ?? this.sets,
      );

  @override
  List<Object?> get props => [status, errorMessage, sets];
}
