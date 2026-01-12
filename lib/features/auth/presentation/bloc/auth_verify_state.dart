import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

class AuthVerifyState extends Equatable {
  final Status status;
  final String? accessToken;
  final String? errorMessage;

  const AuthVerifyState({this.status = Status.initial, this.accessToken, this.errorMessage});

  AuthVerifyState copyWith({Status? status, String? accessToken, String? errorMessage}) {
    return AuthVerifyState(
        status: status ?? this.status,
        accessToken: accessToken ?? this.accessToken,
        errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, accessToken, errorMessage];
}
