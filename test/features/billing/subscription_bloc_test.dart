import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_failure.dart';
import 'package:ustadia_user_app/features/billing/data/services/payment_order_poller.dart';
import 'package:ustadia_user_app/features/billing/data/services/subscription_store.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_bloc/subscription_bloc.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_bloc/subscription_event.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_bloc/subscription_state.dart';

import 'billing_test_helpers.dart';

void main() {
  const plansRoute = 'GET /students/billing/plans';
  const meRoute = 'GET /students/billing/me';
  const purchaseRoute = 'POST /students/billing/purchase';
  const orderRoute = 'GET /payments/orders/$orderId';

  late FakeBillingApi api;
  late SubscriptionStore store;
  late SubscriptionBloc bloc;

  setUpAll(() => EasyLocalization.logger.enableLevels = []);

  setUp(() {
    api = FakeBillingApi()
      ..on(plansRoute, FakeResponse(prodPlans()))
      ..on(meRoute, FakeResponse(notSubscribedJson()))
      ..on(purchaseRoute, FakeResponse(purchaseJson(), statusCode: 201));
    final dataSource = BillingRemoteDataSource(dio: api.dio);
    store = SubscriptionStore(billingRemoteDataSource: dataSource);
    bloc = SubscriptionBloc(
        billingRemoteDataSource: dataSource,
        subscriptionStore: store,
        paymentOrderPoller:
            PaymentOrderPoller(billingRemoteDataSource: dataSource, delay: (_) async {}));
  });

  tearDown(() => bloc.close());

  Future<SubscriptionState> settle(bool Function(SubscriptionState state) test) =>
      test(bloc.state) ? Future.value(bloc.state) : bloc.stream.firstWhere(test);

  Future<void> load() async {
    bloc.add(const SubscriptionRequested());
    await settle((state) => state.status.isSuccess || state.status.isError);
  }

  Future<void> startCheckout() async {
    await load();
    bloc.add(const SubscriptionPurchaseRequested());
    await settle((state) => state.purchaseStatus == PurchaseStatus.awaitingCheckout);
  }

  group('loading', () {
    test('loads plans and the current subscription and preselects the first plan', () async {
      await load();

      expect(bloc.state.status, Status.success);
      expect(bloc.state.plans.map((plan) => plan.name), ['Standard', 'Plus', 'Max']);
      expect(bloc.state.subscription?.isSubscribed, isFalse);
      expect(bloc.state.selectedPlanId, standardPlanId);
      expect(store.subscription.value?.isSubscribed, isFalse);
    });

    test('preselects the current paid plan so it can be extended', () async {
      api.on(meRoute, FakeResponse(meJson(plan: prodPlans()[1])));

      await load();

      expect(bloc.state.selectedPlanId, plusPlanId);
    });

    test('shows an error when loading fails', () async {
      api.on(plansRoute, const FakeResponse({'message': 'Server error'}, statusCode: 500));

      await load();

      expect(bloc.state.status, Status.error);
      expect(bloc.state.errorMessage, 'Server error');
    });

    test('a silent refresh completes its completer even when nothing changed', () async {
      await load();
      final completer = Completer<void>();

      bloc.add(SubscriptionRequested(showLoading: false, completer: completer));

      await completer.future.timeout(const Duration(seconds: 1));
      expect(bloc.state.status, Status.success);
    });
  });

  group('purchase', () {
    test('creates an order for the selected plan and waits for checkout', () async {
      await load();
      bloc.add(const SubscriptionPlanSelected(plusPlanId));
      await settle((state) => state.selectedPlanId == plusPlanId);

      bloc.add(const SubscriptionPurchaseRequested());
      final state = await settle((s) => s.purchaseStatus == PurchaseStatus.awaitingCheckout);

      expect(api.requests.last.data, {'planId': plusPlanId});
      expect(state.purchase?.id, orderId);
    });

    test('a second tap while the order is being created is ignored', () async {
      await load();

      bloc
        ..add(const SubscriptionPurchaseRequested())
        ..add(const SubscriptionPurchaseRequested());
      await settle((state) => state.purchaseStatus == PurchaseStatus.awaitingCheckout);
      await Future<void>.delayed(Duration.zero);

      expect(api.count(purchaseRoute), 1);
    });

    test('plan changes are ignored while a purchase is in progress', () async {
      await startCheckout();

      bloc.add(const SubscriptionPlanSelected(plusPlanId));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.selectedPlanId, standardPlanId);
    });

    test('a lifetime student cannot start a purchase', () async {
      api.on(meRoute, FakeResponse(meJson(endsAt: null, daysLeft: null)));
      await load();

      bloc.add(const SubscriptionPurchaseRequested());
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.canPurchase, isFalse);
      expect(api.count(purchaseRoute), 0);
    });

    test('a removed plan shows a message and reloads the list', () async {
      await load();
      api.on(purchaseRoute, const FakeResponse({'message': 'Plan not found'}, statusCode: 404));

      bloc.add(const SubscriptionPurchaseRequested());
      final state = await settle((s) => s.purchaseStatus == PurchaseStatus.failure);
      await pumpEventQueue();

      expect(state.purchaseMessage, BillingFailure.planNotFoundMessage);
      expect(api.count(plansRoute), 2);
    });

    test('a checkout provider failure is reported', () async {
      await load();
      api.on(
          purchaseRoute,
          const FakeResponse({'message': 'Failed to create WLCM payment checkout'},
              statusCode: 500));

      bloc.add(const SubscriptionPurchaseRequested());
      final state = await settle((s) => s.purchaseStatus == PurchaseStatus.failure);

      expect(state.purchaseMessage, BillingFailure.checkoutUnavailableMessage);
    });

    test('a response without a usable checkout url is a failure', () async {
      await load();
      api.on(purchaseRoute, FakeResponse({...purchaseJson(), 'checkout_url': ''}));

      bloc.add(const SubscriptionPurchaseRequested());
      final state = await settle((s) => s.purchaseStatus == PurchaseStatus.failure);

      expect(state.purchaseMessage, BillingFailure.checkoutUnavailableMessage);
    });
  });

  group('after checkout', () {
    test('a confirmed payment refreshes the subscription from the server', () async {
      await startCheckout();
      api
        ..onSequence(orderRoute, [FakeResponse(orderJson('1')), FakeResponse(orderJson('SUCCESS'))])
        ..on(meRoute, FakeResponse(meJson()));

      final statuses = <PurchaseStatus>[];
      final subscription = bloc.stream.listen((state) => statuses.add(state.purchaseStatus));
      addTearDown(subscription.cancel);

      bloc.add(const SubscriptionCheckoutClosed(reachedReturnUrl: true));
      final state = await settle((s) => s.purchaseStatus == PurchaseStatus.success);

      expect(statuses, [PurchaseStatus.verifying, PurchaseStatus.success]);
      expect(state.subscription?.isSubscribed, isTrue);
      expect(store.subscription.value?.isSubscribed, isTrue);
      expect(api.count(orderRoute), 2);
    });

    test('a cancelled order is reported as cancelled', () async {
      await startCheckout();
      api.on(orderRoute, FakeResponse(orderJson('CANCELLED')));

      bloc.add(const SubscriptionCheckoutClosed(reachedReturnUrl: true));

      expect((await settle((s) => s.purchaseStatus == PurchaseStatus.cancelled)).purchaseStatus,
          PurchaseStatus.cancelled);
    });

    test('no final state within the window is reported as pending', () async {
      await startCheckout();
      api.on(orderRoute, FakeResponse(orderJson('1')));

      bloc.add(const SubscriptionCheckoutClosed(reachedReturnUrl: true));
      await settle((s) => s.purchaseStatus == PurchaseStatus.pending);

      expect(api.count(orderRoute), 40);
      expect(store.isUpToDate, isFalse);
    });

    test('closing checkout by hand checks the order once', () async {
      await startCheckout();
      api.on(orderRoute, FakeResponse(orderJson('1')));

      bloc.add(const SubscriptionCheckoutClosed(reachedReturnUrl: false));
      await settle((s) => s.purchaseStatus == PurchaseStatus.notCompleted);

      expect(api.count(orderRoute), 1);
    });

    test('closing checkout by hand still catches a payment that went through', () async {
      await startCheckout();
      api
        ..on(orderRoute, FakeResponse(orderJson('SUCCESS')))
        ..on(meRoute, FakeResponse(meJson()));

      bloc.add(const SubscriptionCheckoutClosed(reachedReturnUrl: false));

      expect((await settle((s) => s.purchaseStatus == PurchaseStatus.success)).purchaseStatus,
          PurchaseStatus.success);
    });

    test('an unknown order stops polling and re-checks the subscription', () async {
      await startCheckout();
      final meCallsBefore = api.count(meRoute);
      api.on(
          orderRoute, const FakeResponse({'message': 'Payment order not found'}, statusCode: 404));

      bloc.add(const SubscriptionCheckoutClosed(reachedReturnUrl: true));
      final state = await settle((s) => s.purchaseStatus == PurchaseStatus.pending);

      expect(state.purchaseMessage, BillingFailure.orderNotFoundMessage);
      expect(api.count(orderRoute), 1);
      expect(api.count(meRoute), meCallsBefore + 1);
    });

    test('acknowledging a result returns to idle and forgets the order', () async {
      await startCheckout();
      api.on(orderRoute, FakeResponse(orderJson('CANCELLED')));
      bloc.add(const SubscriptionCheckoutClosed(reachedReturnUrl: true));
      await settle((s) => s.purchaseStatus == PurchaseStatus.cancelled);

      bloc.add(const SubscriptionPurchaseAcknowledged());
      final state = await settle((s) => s.purchaseStatus == PurchaseStatus.idle);

      expect(state.purchase, isNull);
      expect(state.canStartPurchase, isTrue);
    });

    test('a checkout close without an open order is ignored', () async {
      await load();

      bloc.add(const SubscriptionCheckoutClosed(reachedReturnUrl: true));
      await Future<void>.delayed(Duration.zero);

      expect(bloc.state.purchaseStatus, PurchaseStatus.idle);
      expect(api.count(orderRoute), 0);
    });
  });
}
