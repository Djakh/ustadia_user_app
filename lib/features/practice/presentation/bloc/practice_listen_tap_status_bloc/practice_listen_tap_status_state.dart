import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

class PracticeListenTapStatusState extends Equatable {
  final Status status;
  final String? errorMessage;
  final String? listenTapId;
  final String? listenTapStatus;
  final int? correctAnswers;
  final int? wrongAnswers;
  final String? message;

  const PracticeListenTapStatusState({
    this.status = Status.initial,
    this.errorMessage,
    this.listenTapId,
    this.listenTapStatus,
    this.correctAnswers,
    this.wrongAnswers,
    this.message,
  });

  PracticeListenTapStatusState copyWith({
    Status? status,
    String? errorMessage,
    String? listenTapId,
    String? listenTapStatus,
    int? correctAnswers,
    int? wrongAnswers,
    String? message,
  }) =>
      PracticeListenTapStatusState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        listenTapId: listenTapId ?? this.listenTapId,
        listenTapStatus: listenTapStatus ?? this.listenTapStatus,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        wrongAnswers: wrongAnswers ?? this.wrongAnswers,
        message: message ?? this.message,
      );

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        listenTapId,
        listenTapStatus,
        correctAnswers,
        wrongAnswers,
        message,
      ];
}
