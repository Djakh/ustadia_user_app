import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

enum AuthVerifyAction { verifyOtp, resendOtp }

class AuthVerifyState extends Equatable {
  final Status status;
  final AuthVerifyAction? action;
  final String? accessToken;
  final String? message;
  final String? errorMessage;

  const AuthVerifyState(
      {this.status = Status.initial,
      this.action,
      this.accessToken,
      this.message,
      this.errorMessage});

  AuthVerifyState copyWith({
    Status? status,
    AuthVerifyAction? action,
    String? accessToken,
    String? message,
    String? errorMessage,
    bool clearAccessToken = false,
    bool clearMessage = false,
  }) {
    return AuthVerifyState(
        status: status ?? this.status,
        action: action ?? this.action,
        accessToken: clearAccessToken ? null : accessToken ?? this.accessToken,
        message: clearMessage ? null : message ?? this.message,
        errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, action, accessToken, message, errorMessage];
}
