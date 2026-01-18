class SwapTeacherResponse {
  final String accessToken;
  final String teacherId;
  final String message;

  const SwapTeacherResponse({
    required this.accessToken,
    required this.teacherId,
    required this.message,
  });

  factory SwapTeacherResponse.fromJson(Map<String, dynamic> json) => SwapTeacherResponse(
        accessToken: json['access_token']?.toString() ?? '',
        teacherId: json['teacher_id']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
      );
}
