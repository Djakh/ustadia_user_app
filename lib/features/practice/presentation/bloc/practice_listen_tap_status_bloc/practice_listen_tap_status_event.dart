import 'package:equatable/equatable.dart';

abstract class PracticeListenTapStatusEvent extends Equatable {
  const PracticeListenTapStatusEvent();

  @override
  List<Object?> get props => [];
}

class PracticeListenTapStatusRequested extends PracticeListenTapStatusEvent {
  final String listenTapId;
  final String status;
  final int correctAnswers;
  final int wrongAnswers;

  const PracticeListenTapStatusRequested({
    required this.listenTapId,
    required this.status,
    required this.correctAnswers,
    required this.wrongAnswers,
  });

  @override
  List<Object?> get props => [listenTapId, status, correctAnswers, wrongAnswers];
}
