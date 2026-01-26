import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_sentence_builder_set_model.dart';

class PracticeSentenceBuilderSetsState extends Equatable {
  final Status status;
  final String? errorMessage;
  final List<PracticeSentenceBuilderSetModel> sets;

  const PracticeSentenceBuilderSetsState({
    this.status = Status.initial,
    this.errorMessage,
    this.sets = const [],
  });

  PracticeSentenceBuilderSetsState copyWith({
    Status? status,
    String? errorMessage,
    List<PracticeSentenceBuilderSetModel>? sets,
  }) =>
      PracticeSentenceBuilderSetsState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        sets: sets ?? this.sets,
      );

  @override
  List<Object?> get props => [status, errorMessage, sets];
}
