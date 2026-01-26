import 'package:equatable/equatable.dart';

abstract class PracticeWordMatchSetsEvent extends Equatable {
  const PracticeWordMatchSetsEvent();

  @override
  List<Object?> get props => [];
}

class PracticeWordMatchSetsRequested extends PracticeWordMatchSetsEvent {
  const PracticeWordMatchSetsRequested();
}
