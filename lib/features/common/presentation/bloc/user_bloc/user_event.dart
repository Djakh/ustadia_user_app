import 'package:equatable/equatable.dart';

sealed class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class UserProfileRequested extends UserEvent {
  const UserProfileRequested();
}

class UserProfileReset extends UserEvent {
  const UserProfileReset();
}

class UserProfileUpdated extends UserEvent {
  final String? firstName;
  final String? lastName;
  final String? language;
  final String? profilePictureId;

  const UserProfileUpdated({this.firstName, this.lastName, this.language, this.profilePictureId});

  @override
  List<Object?> get props => [firstName, lastName, language, profilePictureId];
}

class UserProfileDelete extends UserEvent {
  const UserProfileDelete();
}
