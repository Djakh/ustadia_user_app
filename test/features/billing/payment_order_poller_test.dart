import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:ustadia_user_app/features/billing/data/services/payment_order_poller.dart';

import 'billing_test_helpers.dart';

void main() {
  const orderRoute = 'GET /payments/orders/$orderId';
  late FakeBillingApi api;
  late List<Duration> delays;
  late PaymentOrderPoller poller;

  setUp(() {
    api = FakeBillingApi();
    delays = [];
    poller = PaymentOrderPoller(
        billingRemoteDataSource: BillingRemoteDataSource(dio: api.dio),
        delay: (duration) async => delays.add(duration));
  });

  test('defaults to every 3 seconds for about 2 minutes', () {
    expect(poller.interval, const Duration(seconds: 3));
    expect(poller.defaultAttempts, 40);
  });

  test('checks immediately and stops on SUCCESS', () async {
    api.onSequence(orderRoute, [
      FakeResponse(orderJson('0')),
      FakeResponse(orderJson('1')),
      FakeResponse(orderJson('SUCCESS')),
    ]);

    expect(await poller.poll(orderId), PaymentOrderOutcome.success);
    expect(api.count(orderRoute), 3);
    expect(delays, [const Duration(seconds: 3), const Duration(seconds: 3)]);
  });

  test('stops on CANCELLED', () async {
    api.on(orderRoute, FakeResponse(orderJson('CANCELLED')));

    expect(await poller.poll(orderId), PaymentOrderOutcome.cancelled);
    expect(api.count(orderRoute), 1);
  });

  test('times out after the allowed attempts without waiting after the last one', () async {
    api.on(orderRoute, FakeResponse(orderJson('1')));

    expect(await poller.poll(orderId), PaymentOrderOutcome.timeout);
    expect(api.count(orderRoute), 40);
    expect(delays, hasLength(39));
  });

  test('a single attempt is used when the student closed checkout', () async {
    api.on(orderRoute, FakeResponse(orderJson('1')));

    expect(await poller.poll(orderId, maxAttempts: 1), PaymentOrderOutcome.timeout);
    expect(api.count(orderRoute), 1);
    expect(delays, isEmpty);
  });

  test('stops on 404 order not found', () async {
    api.on(orderRoute, const FakeResponse({'message': 'Payment order not found'}, statusCode: 404));

    expect(await poller.poll(orderId), PaymentOrderOutcome.notFound);
    expect(api.count(orderRoute), 1);
  });

  test('keeps polling through server errors', () async {
    api.onSequence(orderRoute, [
      const FakeResponse({'message': 'Bad gateway'}, statusCode: 502),
      FakeResponse(orderJson('SUCCESS')),
    ]);

    expect(await poller.poll(orderId), PaymentOrderOutcome.success);
    expect(api.count(orderRoute), 2);
  });

  test('rethrows other client errors', () async {
    api.on(orderRoute, const FakeResponse({'message': 'Forbidden'}, statusCode: 403));

    expect(poller.poll(orderId), throwsA(isA<DioException>()));
  });

  test('aborts when the owner is gone', () async {
    api.on(orderRoute, FakeResponse(orderJson('1')));
    var checks = 0;

    final outcome = await poller.poll(orderId, isAborted: () => ++checks > 2);

    expect(outcome, PaymentOrderOutcome.aborted);
    expect(api.count(orderRoute), 2);
  });
}
