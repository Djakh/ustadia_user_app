import 'package:equatable/equatable.dart';

abstract class PracticeWordMatchStatusEvent extends Equatable {
  const PracticeWordMatchStatusEvent();

  @override
  List<Object?> get props => [];
}

class PracticeWordMatchStatusRequested extends PracticeWordMatchStatusEvent {
  final String wordMatchId;
  final String status;
  final int correctAnswers;
  final int wrongAnswers;

  const PracticeWordMatchStatusRequested({
    required this.wordMatchId,
    required this.status,
    required this.correctAnswers,
    required this.wrongAnswers,
  });

  @override
  List<Object?> get props => [wordMatchId, status, correctAnswers, wrongAnswers];
}
