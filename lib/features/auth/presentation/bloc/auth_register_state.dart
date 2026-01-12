import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

class AuthRegisterState extends Equatable {
  final Status status;
  final String? tempId;
  final String? errorMessage;

  const AuthRegisterState({this.status = Status.initial, this.tempId, this.errorMessage});

  AuthRegisterState copyWith({Status? status, String? tempId, String? errorMessage}) {
    return AuthRegisterState(
        status: status ?? this.status, tempId: tempId ?? this.tempId, errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, tempId, errorMessage];
}
