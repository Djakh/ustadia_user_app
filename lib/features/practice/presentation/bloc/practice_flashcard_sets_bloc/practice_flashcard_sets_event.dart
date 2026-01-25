import 'package:equatable/equatable.dart';

abstract class PracticeFlashcardSetsEvent extends Equatable {
  const PracticeFlashcardSetsEvent();

  @override
  List<Object?> get props => [];
}

class PracticeFlashcardSetsRequested extends PracticeFlashcardSetsEvent {
  const PracticeFlashcardSetsRequested();
}
