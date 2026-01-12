import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

enum AuthPasswordAction { forgotPasswordEmail, resetPasswordEmail, forgotPasswordPhone, resetPasswordPhone }

class AuthPasswordState extends Equatable {
  final Status status;
  final AuthPasswordAction? action;
  final String? message;
  final String? errorMessage;

  const AuthPasswordState(
      {this.status = Status.initial, this.action, this.message, this.errorMessage});

  AuthPasswordState copyWith(
      {Status? status, AuthPasswordAction? action, String? message, String? errorMessage}) {
    return AuthPasswordState(
        status: status ?? this.status,
        action: action ?? this.action,
        message: message ?? this.message,
        errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, action, message, errorMessage];
}
