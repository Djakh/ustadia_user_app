import 'package:equatable/equatable.dart';

sealed class AuthLoginEvent extends Equatable {
  const AuthLoginEvent();

  @override
  List<Object?> get props => [];
}

class AuthLoginWithEmailRequested extends AuthLoginEvent {
  final String email;
  final String password;

  const AuthLoginWithEmailRequested({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}
