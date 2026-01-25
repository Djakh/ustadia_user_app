import 'package:equatable/equatable.dart';

abstract class FlashcardStatusEvent extends Equatable {
  const FlashcardStatusEvent();

  @override
  List<Object?> get props => [];
}

class FlashcardStatusRequested extends FlashcardStatusEvent {
  final String flashcardId;
  final String status;
  final bool isPractice;

  const FlashcardStatusRequested({
    required this.flashcardId,
    required this.status,
    required this.isPractice,
  });

  @override
  List<Object?> get props => [flashcardId, status, isPractice];
}
