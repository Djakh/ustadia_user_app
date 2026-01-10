class AuthLoginResponse {
  final String accessToken;

  const AuthLoginResponse({required this.accessToken});

  factory AuthLoginResponse.fromJson(Map<String, dynamic> json) =>
      AuthLoginResponse(accessToken: json['access_token'] as String? ?? '');
}
