import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/core/network/dio_client.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';

/// Transport stub so the real interceptor chain (cache, auth, 402) runs.
class _QueueAdapter implements HttpClientAdapter {
  final List<(int, Object, Map<String, List<String>>)> responses = [];

  void add(int statusCode, Object body, {Map<String, List<String>> headers = const {}}) =>
      responses.add((statusCode, body, headers));

  @override
  Future<ResponseBody> fetch(
      RequestOptions options, Stream<Uint8List>? requestStream, Future<void>? cancelFuture) async {
    final (statusCode, body, headers) = responses.removeAt(0);
    return ResponseBody.fromString(jsonEncode(body), statusCode, headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
      ...headers,
    });
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  const expiredBody = {'statusCode': 402, 'code': 'SUBSCRIPTION_EXPIRED'};
  late _QueueAdapter adapter;
  late int expiredCalls;
  late String token;

  Dio createDio() => DioClient.create(
      baseUrl: 'https://example.com',
      accessTokenGetter: () => token,
      onUnauthorized: () async {},
      onSubscriptionExpired: () => expiredCalls++)
    ..httpClientAdapter = adapter;

  setUp(() async {
    await DioClient.clearCache();
    adapter = _QueueAdapter();
    expiredCalls = 0;
    token = 'access-token-value';
  });

  test('402 SUBSCRIPTION_EXPIRED notifies the app and still fails the request', () async {
    adapter.add(402, expiredBody);

    final error = await createDio()
        .get('/students/lessons')
        .then<DioException?>((_) => null, onError: (Object error) => error as DioException);

    expect(expiredCalls, 1);
    expect(error?.response?.statusCode, 402);
    expect(DioErrorMessage.from(error!), DioErrorMessage.subscriptionExpiredMessage);
  });

  test('402 is never answered from a cached copy', () async {
    final dio = createDio();
    adapter
      ..add(200, {
        'items': []
      }, headers: {
        'etag': ['"v1"'],
        'cache-control': ['max-age=0'],
      })
      ..add(402, expiredBody);

    await dio.get('/students/lessons');

    await expectLater(dio.get('/students/lessons'), throwsA(isA<DioException>()));
    expect(expiredCalls, 1);
  });

  test('other 402 bodies and signed-out requests do not open the paywall', () async {
    adapter
      ..add(402, {'statusCode': 402, 'code': 'PAYMENT_REQUIRED'})
      ..add(402, expiredBody);
    final dio = createDio();

    await expectLater(dio.get('/a'), throwsA(isA<DioException>()));
    token = '';
    await expectLater(dio.get('/b'), throwsA(isA<DioException>()));

    expect(expiredCalls, 0);
  });
}
