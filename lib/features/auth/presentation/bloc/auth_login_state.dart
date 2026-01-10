import 'package:equatable/equatable.dart';

enum AuthLoginStatus { initial, loading, success, failure }

class AuthLoginState extends Equatable {
  final AuthLoginStatus status;
  final String? accessToken;
  final String? errorMessage;

  const AuthLoginState(
      {this.status = AuthLoginStatus.initial, this.accessToken, this.errorMessage});

  AuthLoginState copyWith(
      {AuthLoginStatus? status, String? accessToken, String? errorMessage}) {
    return AuthLoginState(
        status: status ?? this.status,
        accessToken: accessToken ?? this.accessToken,
        errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, accessToken, errorMessage];
}
