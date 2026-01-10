import 'package:equatable/equatable.dart';

enum AuthRegisterStatus { initial, loading, success, failure }

class AuthRegisterState extends Equatable {
  final AuthRegisterStatus status;
  final String? tempId;
  final String? errorMessage;

  const AuthRegisterState({this.status = AuthRegisterStatus.initial, this.tempId, this.errorMessage});

  AuthRegisterState copyWith(
      {AuthRegisterStatus? status, String? tempId, String? errorMessage}) {
    return AuthRegisterState(
        status: status ?? this.status, tempId: tempId ?? this.tempId, errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, tempId, errorMessage];
}
