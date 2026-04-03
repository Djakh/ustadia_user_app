import 'package:dio/dio.dart';

class DioErrorMessage {
  const DioErrorMessage();

  static const noInternetMessage = 'No internet connection. Please reconnect and try again.';

  static String from(DioException error) {
    final data = error.response?.data;
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return noInternetMessage;
    }
    return 'Request failed. Please try again.';
  }

  static bool isConnectionMessage(String? message) =>
      message != null && message.trim() == noInternetMessage;

  static String fromUnknown(Object error) {
    if (error is DioException) return from(error);
    final text = error.toString().toLowerCase();
    if (text.contains('dioexception') && text.contains('connection error')) {
      return noInternetMessage;
    }
    if (text.contains('socketexception')) {
      return noInternetMessage;
    }
    if (text.contains('failed host lookup')) {
      return noInternetMessage;
    }
    if (text.contains('no route to host')) {
      return noInternetMessage;
    }
    if (text.contains('connection timed out')) {
      return noInternetMessage;
    }
    return 'Request failed. Please try again.';
  }
}
