import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

class FlashcardStatusState extends Equatable {
  final Status status;
  final String? flashcardId;
  final String? back;
  final String? cardStatus;
  final String? errorMessage;

  const FlashcardStatusState({
    this.status = Status.initial,
    this.flashcardId,
    this.back,
    this.cardStatus,
    this.errorMessage,
  });

  FlashcardStatusState copyWith({
    Status? status,
    String? flashcardId,
    String? back,
    String? cardStatus,
    String? errorMessage,
  }) {
    return FlashcardStatusState(
      status: status ?? this.status,
      flashcardId: flashcardId ?? this.flashcardId,
      back: back ?? this.back,
      cardStatus: cardStatus ?? this.cardStatus,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, flashcardId, back, cardStatus, errorMessage];
}
