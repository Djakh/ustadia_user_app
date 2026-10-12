import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/core/services/subscription_expired_handler.dart';
import 'package:ustadia_user_app/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:ustadia_user_app/features/billing/data/services/payment_order_poller.dart';
import 'package:ustadia_user_app/features/billing/data/services/subscription_store.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_bloc/subscription_bloc.dart';
import 'package:ustadia_user_app/features/billing/presentation/pages/subscription_page.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

import 'billing_test_helpers.dart';

/// The real checkout is a platform WebView; this stands in for Paylov.
class _FakeCheckoutPage extends StatelessWidget {
  const _FakeCheckoutPage();

  @override
  Widget build(BuildContext context) => Scaffold(
          body: Column(children: [
        TextButton(onPressed: () => context.pop(true), child: const Text('paylov-return')),
        TextButton(onPressed: () => context.pop(false), child: const Text('paylov-close')),
      ]));
}

void main() {
  const meRoute = 'GET /students/billing/me';
  const orderRoute = 'GET /payments/orders/$orderId';
  late FakeBillingApi api;
  late SubscriptionExpiredHandler handler;

  setUpAll(() => EasyLocalization.logger.enableLevels = []);

  setUp(() {
    api = FakeBillingApi()
      ..on('GET /students/billing/plans', FakeResponse(prodPlans()))
      ..on(meRoute, FakeResponse(notSubscribedJson()))
      ..on('POST /students/billing/purchase', FakeResponse(purchaseJson(), statusCode: 201));
    handler = SubscriptionExpiredHandler(openPaywall: () {}, currentPath: () => '/');
    final dataSource = BillingRemoteDataSource(dio: api.dio);
    final store = SubscriptionStore(billingRemoteDataSource: dataSource);
    sl
      ..registerSingleton<SubscriptionExpiredHandler>(handler)
      ..registerFactory(() => SubscriptionBloc(
          billingRemoteDataSource: dataSource,
          subscriptionStore: store,
          paymentOrderPoller:
              PaymentOrderPoller(billingRemoteDataSource: dataSource, delay: (_) async {})));
  });

  tearDown(() => sl.reset());

  Future<GoRouter> pumpPage(WidgetTester tester,
      {SubscriptionPageParams params = const SubscriptionPageParams()}) async {
    tester.view.physicalSize = const Size(430, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final router = GoRouter(initialLocation: '/', routes: [
      GoRoute(
          path: '/',
          builder: (context, _) => Scaffold(
              body: TextButton(
                  onPressed: () => context.push(subscriptionRoute, extra: params),
                  child: const Text('open-subscription')))),
      GoRoute(
          path: subscriptionRoute,
          builder: (_, state) => SubscriptionPage(params: state.extra as SubscriptionPageParams),
          routes: [
            GoRoute(path: subscriptionCheckoutPath, builder: (_, __) => const _FakeCheckoutPage()),
          ]),
    ]);
    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.tap(find.text('open-subscription'));
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('lists plans with grouped prices and pays for the selected one', (tester) async {
    await pumpPage(tester);

    expect(find.text('No active subscription'), findsOneWidget);
    expect(find.text('Standard'), findsOneWidget);
    expect(find.text('36 000'), findsOneWidget);
    expect(find.text('Pay 36 000 UZS'), findsOneWidget);

    await tester.tap(find.text('Plus'));
    await tester.pumpAndSettle();

    expect(find.text('Pay 200 000 UZS'), findsOneWidget);
  });

  testWidgets('a paid order shows the activated sheet and the new subscription', (tester) async {
    await pumpPage(tester);
    api
      ..on(orderRoute, FakeResponse(orderJson('SUCCESS')))
      ..on(meRoute, FakeResponse(meJson()));

    await tester.tap(find.text('Pay 36 000 UZS'));
    await tester.pumpAndSettle();
    expect(find.text('paylov-return'), findsOneWidget);
    expect(api.requests.where((r) => r.method == 'POST').single.data, {'planId': standardPlanId});

    await tester.tap(find.text('paylov-return'));
    await tester.pumpAndSettle();

    expect(find.text('Plan activated'), findsOneWidget);
    expect(find.text('Standard is active until 08.12.2026.'), findsOneWidget);

    await tester.tap(find.text('Continue learning'));
    await tester.pumpAndSettle();

    expect(find.text('Plan activated'), findsNothing);
    expect(find.text('Current plan'), findsOneWidget);
    expect(find.text('Current'), findsOneWidget);
  });

  testWidgets('a cancelled order shows the cancelled sheet', (tester) async {
    await pumpPage(tester);
    api.on(orderRoute, FakeResponse(orderJson('CANCELLED')));

    await tester.tap(find.text('Pay 36 000 UZS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('paylov-return'));
    await tester.pumpAndSettle();

    expect(find.text('Payment cancelled'), findsOneWidget);
  });

  testWidgets('closing checkout without paying checks once and says so', (tester) async {
    await pumpPage(tester);
    api.on(orderRoute, FakeResponse(orderJson('1')));

    await tester.tap(find.text('Pay 36 000 UZS'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('paylov-close'));
    await tester.pumpAndSettle();

    expect(api.count(orderRoute), 1);
    expect(find.text('Payment was not completed'), findsOneWidget);
    expect(find.text('Pay 36 000 UZS'), findsOneWidget);
  });

  testWidgets('a lifetime student sees no purchase button', (tester) async {
    api.on(meRoute, FakeResponse(meJson(plan: prodPlans()[2], endsAt: null, daysLeft: null)));

    await pumpPage(tester);

    expect(find.text('Lifetime access'), findsOneWidget);
    expect(find.text('You have lifetime access. There is nothing else to buy.'), findsOneWidget);
    expect(find.textContaining('Pay '), findsNothing);
  });

  testWidgets('the 402 paywall explains the expiry and registers itself', (tester) async {
    final router = await pumpPage(tester, params: const SubscriptionPageParams(isExpired: true));

    expect(find.text('Your subscription has expired'), findsOneWidget);
    expect(handler.isPaywallVisible, isTrue);

    router.pop();
    await tester.pumpAndSettle();

    expect(handler.isPaywallVisible, isFalse);
    expect(handler.isCoolingDown, isTrue);
  });

  testWidgets('a load error offers a reload', (tester) async {
    api.on('GET /students/billing/plans',
        const FakeResponse({'message': 'Server error'}, statusCode: 500));

    await pumpPage(tester);

    expect(find.text('Server error'), findsOneWidget);

    api.on('GET /students/billing/plans', FakeResponse(prodPlans()));
    await tester.tap(find.text('Reload'));
    await tester.pumpAndSettle();

    expect(find.text('Standard'), findsOneWidget);
  });
}
