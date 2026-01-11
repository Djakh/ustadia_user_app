import 'package:equatable/equatable.dart';

sealed class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class UserProfileRequested extends UserEvent {
  const UserProfileRequested();
}
