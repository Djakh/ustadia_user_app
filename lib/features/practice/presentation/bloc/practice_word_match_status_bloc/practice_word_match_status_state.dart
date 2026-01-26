import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

class PracticeWordMatchStatusState extends Equatable {
  final Status status;
  final String? errorMessage;
  final String? wordMatchId;
  final String? matchStatus;
  final int? correctAnswers;
  final int? wrongAnswers;
  final String? message;

  const PracticeWordMatchStatusState({
    this.status = Status.initial,
    this.errorMessage,
    this.wordMatchId,
    this.matchStatus,
    this.correctAnswers,
    this.wrongAnswers,
    this.message,
  });

  PracticeWordMatchStatusState copyWith({
    Status? status,
    String? errorMessage,
    String? wordMatchId,
    String? matchStatus,
    int? correctAnswers,
    int? wrongAnswers,
    String? message,
  }) =>
      PracticeWordMatchStatusState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        wordMatchId: wordMatchId ?? this.wordMatchId,
        matchStatus: matchStatus ?? this.matchStatus,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        wrongAnswers: wrongAnswers ?? this.wrongAnswers,
        message: message ?? this.message,
      );

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        wordMatchId,
        matchStatus,
        correctAnswers,
        wrongAnswers,
        message,
      ];
}
