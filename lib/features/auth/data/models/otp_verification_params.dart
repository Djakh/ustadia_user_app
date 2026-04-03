class OtpVerificationParams {
  final String tempId;
  final String? email;
  final String? phoneNumber;

  const OtpVerificationParams({
    required this.tempId,
    this.email,
    this.phoneNumber,
  });

  String get contact =>
      email?.trim().isNotEmpty == true ? email!.trim() : (phoneNumber ?? '').trim();

  bool get isPhoneVerification => phoneNumber?.trim().isNotEmpty == true;
}
