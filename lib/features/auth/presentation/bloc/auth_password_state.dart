import 'package:equatable/equatable.dart';

enum AuthPasswordStatus { initial, loading, success, failure }

enum AuthPasswordAction { forgotPasswordEmail, resetPasswordEmail, forgotPasswordPhone, resetPasswordPhone }

class AuthPasswordState extends Equatable {
  final AuthPasswordStatus status;
  final AuthPasswordAction? action;
  final String? message;
  final String? errorMessage;

  const AuthPasswordState(
      {this.status = AuthPasswordStatus.initial,
      this.action,
      this.message,
      this.errorMessage});

  AuthPasswordState copyWith(
      {AuthPasswordStatus? status,
      AuthPasswordAction? action,
      String? message,
      String? errorMessage}) {
    return AuthPasswordState(
        status: status ?? this.status,
        action: action ?? this.action,
        message: message ?? this.message,
        errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, action, message, errorMessage];
}
