import 'package:equatable/equatable.dart';

sealed class AuthPasswordEvent extends Equatable {
  const AuthPasswordEvent();

  @override
  List<Object?> get props => [];
}

class AuthForgotPasswordRequested extends AuthPasswordEvent {
  final String email;

  const AuthForgotPasswordRequested({required this.email});

  @override
  List<Object?> get props => [email];
}

class AuthResetPasswordRequested extends AuthPasswordEvent {
  final String email;
  final String otp;
  final String newPassword;

  const AuthResetPasswordRequested(
      {required this.email, required this.otp, required this.newPassword});

  @override
  List<Object?> get props => [email, otp, newPassword];
}
