import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/core/network/dio_client.dart';

void main() {
  test('DioClient masks authorization tokens in logs', () {
    const token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.fakeSignature';
    final message = DioClient.sanitizeLogMessageForTest('Authorization: Bearer $token');

    expect(message, isNot(contains(token)));
    expect(message, contains('Bearer eyJhbG...ture'));
  });
}
