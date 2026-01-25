import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';

class PracticeFlashcardSetsState extends Equatable {
  final Status status;
  final List<LearnFlashcardSetModel> sets;
  final String? errorMessage;

  const PracticeFlashcardSetsState({
    this.status = Status.initial,
    this.sets = const [],
    this.errorMessage,
  });

  PracticeFlashcardSetsState copyWith({
    Status? status,
    List<LearnFlashcardSetModel>? sets,
    String? errorMessage,
  }) {
    return PracticeFlashcardSetsState(
      status: status ?? this.status,
      sets: sets ?? this.sets,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, sets, errorMessage];
}
