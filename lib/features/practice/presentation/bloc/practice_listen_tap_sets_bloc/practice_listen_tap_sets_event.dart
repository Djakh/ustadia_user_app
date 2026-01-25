import 'package:equatable/equatable.dart';

abstract class PracticeListenTapSetsEvent extends Equatable {
  const PracticeListenTapSetsEvent();

  @override
  List<Object?> get props => [];
}

class PracticeListenTapSetsRequested extends PracticeListenTapSetsEvent {
  const PracticeListenTapSetsRequested();
}
