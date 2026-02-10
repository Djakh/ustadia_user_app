import 'package:dio/dio.dart';

class DioErrorMessage {
  const DioErrorMessage();

  static String from(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'No internet connection. Please reconnect and try again.';
    }
    return 'Request failed. Please try again.';
  }
}
