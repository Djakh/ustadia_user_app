import 'package:dio/dio.dart';

class DioErrorMessage {
  const DioErrorMessage();

  static const noInternetMessage = 'No internet connection. Please reconnect and try again.';
  static const accountNotFoundMessage = 'Account not found';

  static String from(DioException error) {
    final data = error.response?.data;
    if (_isDeletedAccountResponse(error, data)) return accountNotFoundMessage;
    if (data is Map && data['message'] != null) return data['message'].toString();
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return noInternetMessage;
    }
    return 'Request failed. Please try again.';
  }

  static bool _isDeletedAccountResponse(DioException error, Object? data) {
    if (!_isAuthRequest(error)) return false;
    if (_isAuthLoginRequest(error) && error.response?.statusCode == 404) return true;
    if (data is Map && data['isDeleted'] == true) return true;
    return _responseText(data).contains('deleted');
  }

  static bool _isAuthRequest(DioException error) {
    final path = error.requestOptions.path.toLowerCase();
    return path.contains('/auth/');
  }

  static bool _isAuthLoginRequest(DioException error) {
    final path = error.requestOptions.path.toLowerCase();
    return path.endsWith('/auth/login') || path.contains('/auth/login?');
  }

  static String _responseText(Object? data) {
    if (data is Map) {
      return data.values.map(_responseText).where((text) => text.isNotEmpty).join(' ');
    }
    if (data is Iterable) {
      return data.map(_responseText).where((text) => text.isNotEmpty).join(' ');
    }
    return data?.toString().toLowerCase().trim() ?? '';
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
