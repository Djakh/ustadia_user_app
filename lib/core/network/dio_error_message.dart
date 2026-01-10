import 'package:dio/dio.dart';

class DioErrorMessage {
  const DioErrorMessage();

  static String from(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    return 'Request failed. Please try again.';
  }
}
