import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_order_model.dart';

import 'billing_test_helpers.dart';

void main() {
  late FakeBillingApi api;
  late BillingRemoteDataSource dataSource;

  setUp(() {
    api = FakeBillingApi();
    dataSource = BillingRemoteDataSource(dio: api.dio);
  });

  test('plans are fetched from the student endpoint and sorted by sort_order', () async {
    api.on('GET /students/billing/plans', FakeResponse(prodPlans().reversed.toList()));

    final plans = await dataSource.fetchPlans();

    expect(plans.map((plan) => plan.name), ['Standard', 'Plus', 'Max']);
  });

  test('plans accept a wrapped list response', () async {
    api.on('GET /students/billing/plans', FakeResponse({'data': prodPlans()}));

    expect(await dataSource.fetchPlans(), hasLength(3));
  });

  test('purchase posts only planId, never a payment provider', () async {
    api.on('POST /students/billing/purchase', FakeResponse(purchaseJson(), statusCode: 201));

    final purchase = await dataSource.purchase(planId: standardPlanId);

    final request = api.requests.single;
    expect(request.data, {'planId': standardPlanId});
    expect(purchase.id, orderId);
    expect(purchase.checkoutUrl, startsWith('https://my.paylov.uz/'));
  });

  test('order state, current subscription and history use documented paths', () async {
    api
      ..on('GET /payments/orders/$orderId', FakeResponse(orderJson('SUCCESS')))
      ..on('GET /students/billing/me', FakeResponse(meJson()))
      ..on(
          'GET /students/billing/history',
          const FakeResponse([
            {'id': 'h1', 'planName': 'Standard', 'status': 'active', 'source': 'payment'}
          ]));

    final order = await dataSource.fetchOrder(orderId);
    final me = await dataSource.fetchMySubscription();
    final history = await dataSource.fetchHistory();

    expect(order.state, BillingOrderState.success);
    expect(me.daysLeft, 60);
    expect(history.single.planName, 'Standard');
  });

  test('every billing request bypasses the HTTP cache', () async {
    api
      ..on('GET /students/billing/plans', FakeResponse(prodPlans()))
      ..on('GET /students/billing/me', FakeResponse(meJson()));

    await dataSource.fetchPlans();
    await dataSource.fetchMySubscription();

    for (final request in api.requests) {
      expect(CacheOptions.fromExtra(request)?.policy, CachePolicy.noCache);
    }
  });
}
