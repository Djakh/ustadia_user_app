import 'package:equatable/equatable.dart';

abstract class PracticeSentenceBuilderStatusEvent extends Equatable {
  const PracticeSentenceBuilderStatusEvent();

  @override
  List<Object?> get props => [];
}

class PracticeSentenceBuilderStatusRequested extends PracticeSentenceBuilderStatusEvent {
  final String sentenceBuilderId;
  final String status;
  final int correctAnswers;
  final int wrongAnswers;

  const PracticeSentenceBuilderStatusRequested({
    required this.sentenceBuilderId,
    required this.status,
    required this.correctAnswers,
    required this.wrongAnswers,
  });

  @override
  List<Object?> get props => [sentenceBuilderId, status, correctAnswers, wrongAnswers];
}
