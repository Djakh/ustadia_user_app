import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/auth/data/models/auth_login_response.dart';

class AuthRemoteDataSource {
  final Dio dio;

  AuthRemoteDataSource({required this.dio});

  Options get requestOptions => Options(
      validateStatus: (status) => status != null && status < 500,
      headers: {'accept': '*/*', 'Content-Type': 'application/json'});

  void checkResponse(Response response) {
    final status = response.statusCode ?? 0;
    if (status >= 200 && status < 300) return;
    throw DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.badResponse);
  }

  Future<AuthLoginResponse> loginWithEmail({
    required String email,
    required String password
  }) async {
    final response = await dio.post('/auth/login',
        data: {'email': email, 'password': password}, options: requestOptions);
    checkResponse(response);
    return AuthLoginResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<String> forgotPassword({required String email}) async {
    final response = await dio.post('/auth/forgot-password',
        data: {'email': email}, options: requestOptions);
    checkResponse(response);
    final data = response.data as Map<String, dynamic>;
    return data['message']?.toString() ?? '';
  }

  Future<String> resetPassword(
      {required String email, required String otp, required String newPassword}) async {
    final response = await dio.post('/auth/reset-password',
        data: {'email': email, 'otp': otp, 'newPassword': newPassword},
        options: requestOptions);
    checkResponse(response);
    final data = response.data as Map<String, dynamic>;
    return data['message']?.toString() ?? '';
  }

  Future<String> registerWithEmail(
      {required String firstName,
      required String lastName,
      required String email,
      required String password}) async {
    final response = await dio.post('/auth/register',
        data: {
          'firstName': firstName,
          'lastName': lastName,
          'email': email,
          'password': password,
          'role': 'user'
        },
        options: requestOptions);
    checkResponse(response);
    final data = response.data as Map<String, dynamic>;
    return data['tempId']?.toString() ?? '';
  }

  Future<String> verifyOtp({required String tempId, required String otp}) async {
    final response = await dio.post('/auth/verify',
        data: {'tempId': tempId, 'otp': otp}, options: requestOptions);
    checkResponse(response);
    final data = response.data as Map<String, dynamic>;
    return data['access_token']?.toString() ?? '';
  }
}
