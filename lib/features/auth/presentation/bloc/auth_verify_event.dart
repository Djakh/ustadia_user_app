import 'package:equatable/equatable.dart';

sealed class AuthVerifyEvent extends Equatable {
  const AuthVerifyEvent();

  @override
  List<Object?> get props => [];
}

class AuthVerifyOtpRequested extends AuthVerifyEvent {
  final String tempId;
  final String otp;

  const AuthVerifyOtpRequested({required this.tempId, required this.otp});

  @override
  List<Object?> get props => [tempId, otp];
}

class AuthResendOtpRequested extends AuthVerifyEvent {
  final String tempId;

  const AuthResendOtpRequested({required this.tempId});

  @override
  List<Object?> get props => [tempId];
}
