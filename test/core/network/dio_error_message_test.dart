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

    test('recognises an expired subscription only by 402 and its code', () {
      Response<dynamic> response(int statusCode, Object? data) => Response(
          requestOptions: RequestOptions(path: '/students/lessons'),
          statusCode: statusCode,
          data: data);

      expect(
          DioErrorMessage.isSubscriptionExpiredResponse(
              response(402, {'statusCode': 402, 'code': 'SUBSCRIPTION_EXPIRED'})),
          isTrue);
      expect(DioErrorMessage.isSubscriptionExpiredResponse(response(402, {'code': 'OTHER'})),
          isFalse);
      expect(
          DioErrorMessage.isSubscriptionExpiredResponse(
              response(403, {'code': 'SUBSCRIPTION_EXPIRED'})),
          isFalse);
      expect(DioErrorMessage.isSubscriptionExpiredResponse(response(402, 'SUBSCRIPTION_EXPIRED')),
          isFalse);
      expect(DioErrorMessage.isSubscriptionExpiredResponse(null), isFalse);
    });

    test('an expired subscription gets its own message instead of a generic error', () {
      final error = DioException(
          requestOptions: RequestOptions(path: '/students/lessons'),
          response: Response(
              requestOptions: RequestOptions(path: '/students/lessons'),
              statusCode: 402,
              data: {'statusCode': 402, 'code': 'SUBSCRIPTION_EXPIRED'}),
          type: DioExceptionType.badResponse);

      final message = DioErrorMessage.from(error);

      expect(message, DioErrorMessage.subscriptionExpiredMessage);
      expect(DioErrorMessage.isSubscriptionExpiredMessage(message), isTrue);
    });
  });
}
