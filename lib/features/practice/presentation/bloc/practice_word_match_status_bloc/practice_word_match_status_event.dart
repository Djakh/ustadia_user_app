import 'package:equatable/equatable.dart';

abstract class PracticeWordMatchStatusEvent extends Equatable {
  const PracticeWordMatchStatusEvent();

  @override
  List<Object?> get props => [];
}

class PracticeWordMatchStatusRequested extends PracticeWordMatchStatusEvent {
  final String wordMatchId;
  final String status;

  const PracticeWordMatchStatusRequested({required this.wordMatchId, required this.status});

  @override
  List<Object?> get props => [wordMatchId, status];
}
