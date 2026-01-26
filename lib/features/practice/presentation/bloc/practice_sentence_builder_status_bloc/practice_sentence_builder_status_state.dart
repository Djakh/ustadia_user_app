import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

class PracticeSentenceBuilderStatusState extends Equatable {
  final Status status;
  final String? errorMessage;
  final String? sentenceBuilderId;
  final String? sentenceBuilderStatus;
  final int? correctAnswers;
  final int? wrongAnswers;
  final String? message;

  const PracticeSentenceBuilderStatusState({
    this.status = Status.initial,
    this.errorMessage,
    this.sentenceBuilderId,
    this.sentenceBuilderStatus,
    this.correctAnswers,
    this.wrongAnswers,
    this.message,
  });

  PracticeSentenceBuilderStatusState copyWith({
    Status? status,
    String? errorMessage,
    String? sentenceBuilderId,
    String? sentenceBuilderStatus,
    int? correctAnswers,
    int? wrongAnswers,
    String? message,
  }) =>
      PracticeSentenceBuilderStatusState(
        status: status ?? this.status,
        errorMessage: errorMessage,
        sentenceBuilderId: sentenceBuilderId ?? this.sentenceBuilderId,
        sentenceBuilderStatus: sentenceBuilderStatus ?? this.sentenceBuilderStatus,
        correctAnswers: correctAnswers ?? this.correctAnswers,
        wrongAnswers: wrongAnswers ?? this.wrongAnswers,
        message: message ?? this.message,
      );

  @override
  List<Object?> get props => [
        status,
        errorMessage,
        sentenceBuilderId,
        sentenceBuilderStatus,
        correctAnswers,
        wrongAnswers,
        message,
      ];
}
