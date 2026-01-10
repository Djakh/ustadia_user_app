import 'package:equatable/equatable.dart';

enum AuthVerifyStatus { initial, loading, success, failure }

class AuthVerifyState extends Equatable {
  final AuthVerifyStatus status;
  final String? accessToken;
  final String? errorMessage;

  const AuthVerifyState({this.status = AuthVerifyStatus.initial, this.accessToken, this.errorMessage});

  AuthVerifyState copyWith(
      {AuthVerifyStatus? status, String? accessToken, String? errorMessage}) {
    return AuthVerifyState(
        status: status ?? this.status,
        accessToken: accessToken ?? this.accessToken,
        errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, accessToken, errorMessage];
}
