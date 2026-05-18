import 'package:equatable/equatable.dart';

abstract class MonkeyTypePracticesEvent extends Equatable {
  const MonkeyTypePracticesEvent();

  @override
  List<Object?> get props => [];
}

class MonkeyTypePracticesRequested extends MonkeyTypePracticesEvent {
  const MonkeyTypePracticesRequested();
}
