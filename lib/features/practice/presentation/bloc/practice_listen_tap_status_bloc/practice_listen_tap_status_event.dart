import 'package:equatable/equatable.dart';

abstract class PracticeListenTapStatusEvent extends Equatable {
  const PracticeListenTapStatusEvent();

  @override
  List<Object?> get props => [];
}

class PracticeListenTapStatusRequested extends PracticeListenTapStatusEvent {
  final String listenTapId;
  final String status;

  const PracticeListenTapStatusRequested({required this.listenTapId, required this.status});

  @override
  List<Object?> get props => [listenTapId, status];
}
