import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

class AuthLoginState extends Equatable {
  final Status status;
  final String? accessToken;
  final String? errorMessage;

  const AuthLoginState({this.status = Status.initial, this.accessToken, this.errorMessage});

  AuthLoginState copyWith(
      {Status? status, String? accessToken, String? errorMessage}) {
    return AuthLoginState(
        status: status ?? this.status,
        accessToken: accessToken ?? this.accessToken,
        errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, accessToken, errorMessage];
}
