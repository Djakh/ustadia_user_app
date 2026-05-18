import 'package:equatable/equatable.dart';

abstract class MonkeyTypeSessionEvent extends Equatable {
  const MonkeyTypeSessionEvent();

  @override
  List<Object?> get props => [];
}

class MonkeyTypeTextsRequested extends MonkeyTypeSessionEvent {
  final String practiceId;

  const MonkeyTypeTextsRequested({required this.practiceId});

  @override
  List<Object?> get props => [practiceId];
}

class MonkeyTypeAnswerSubmitted extends MonkeyTypeSessionEvent {
  final String practiceId;
  final String text;
  final double wpm;
  final double accuracy;
  final int correctChars;
  final int totalChars;
  final int timeTakenSeconds;

  const MonkeyTypeAnswerSubmitted({
    required this.practiceId,
    required this.text,
    required this.wpm,
    required this.accuracy,
    required this.correctChars,
    required this.totalChars,
    required this.timeTakenSeconds,
  });

  @override
  List<Object?> get props =>
      [practiceId, text, wpm, accuracy, correctChars, totalChars, timeTakenSeconds];
}
