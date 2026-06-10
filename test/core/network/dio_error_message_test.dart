import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';

void main() {
  group('DioErrorMessage', () {
    test('returns account not found for auth login 404', () {
      final error = DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 404,
              data: {'message': 'User not found'}),
          type: DioExceptionType.badResponse);

      expect(DioErrorMessage.from(error), DioErrorMessage.accountNotFoundMessage);
    });

    test('returns account not found for deleted auth account response', () {
      final error = DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 403,
              data: {'message': 'This account has been deleted'}),
          type: DioExceptionType.badResponse);

      expect(DioErrorMessage.from(error), DioErrorMessage.accountNotFoundMessage);
    });

    test('keeps regular backend auth error message', () {
      final error = DioException(
          requestOptions: RequestOptions(path: '/auth/login'),
          response: Response(
              requestOptions: RequestOptions(path: '/auth/login'),
              statusCode: 401,
              data: {'message': 'Invalid password'}),
          type: DioExceptionType.badResponse);

      expect(DioErrorMessage.from(error), 'Invalid password');
    });
  });
}
