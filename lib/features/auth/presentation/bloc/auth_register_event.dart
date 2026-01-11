import 'package:equatable/equatable.dart';

sealed class AuthRegisterEvent extends Equatable {
  const AuthRegisterEvent();

  @override
  List<Object?> get props => [];
}

class AuthRegisterWithEmailRequested extends AuthRegisterEvent {
  final String firstName;
  final String lastName;
  final String email;
  final String password;

  const AuthRegisterWithEmailRequested(
      {required this.firstName,
      required this.lastName,
      required this.email,
      required this.password});

  @override
  List<Object?> get props => [firstName, lastName, email, password];
}

class AuthRegisterWithPhoneRequested extends AuthRegisterEvent {
  final String firstName;
  final String lastName;
  final String phoneNumber;
  final String password;

  const AuthRegisterWithPhoneRequested(
      {required this.firstName,
      required this.lastName,
      required this.phoneNumber,
      required this.password});

  @override
  List<Object?> get props => [firstName, lastName, phoneNumber, password];
}
