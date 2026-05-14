import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

const _unset = Object();

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
    Object? flashcardId = _unset,
    Object? back = _unset,
    Object? cardStatus = _unset,
    String? errorMessage,
  }) {
    return FlashcardStatusState(
      status: status ?? this.status,
      flashcardId: identical(flashcardId, _unset) ? this.flashcardId : flashcardId as String?,
      back: identical(back, _unset) ? this.back : back as String?,
      cardStatus: identical(cardStatus, _unset) ? this.cardStatus : cardStatus as String?,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, flashcardId, back, cardStatus, errorMessage];
}
