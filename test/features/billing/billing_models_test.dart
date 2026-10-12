import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_amount.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_failure.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_history_item_model.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_order_model.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_plan_model.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_subscription_model.dart';
import 'package:ustadia_user_app/features/billing/presentation/widgets/subscription_labels.dart';

import 'billing_test_helpers.dart';

DioException billingError(int statusCode, Object? data,
        {String path = '/students/billing/purchase'}) =>
    DioException(
        requestOptions: RequestOptions(path: path),
        type: DioExceptionType.badResponse,
        response: Response<dynamic>(
            requestOptions: RequestOptions(path: path), statusCode: statusCode, data: data));

void main() {
  setUpAll(() => EasyLocalization.logger.enableLevels = []);

  group('BillingPlanModel', () {
    test('parses the documented plan and keeps price as a string', () {
      final plan = BillingPlanModel.fromJson(planJson());

      expect(plan.id, standardPlanId);
      expect(plan.name, 'Standard');
      expect(plan.description, '1 oylik obuna');
      expect(plan.price, '36000');
      expect(plan.currency, 'UZS');
      expect(plan.durationDays, 30);
      expect(plan.isLifetimePlan, isFalse);
      expect(plan.features, isEmpty);
    });

    test('treats is_lifetime or a null duration as lifetime', () {
      expect(BillingPlanModel.fromJson(planJson(durationDays: null)).isLifetimePlan, isTrue);
      expect(
          BillingPlanModel.fromJson(planJson(durationDays: null, isLifetime: true)).isLifetimePlan,
          isTrue);
    });

    test('drops blank description and features', () {
      final plan = BillingPlanModel.fromJson(
          planJson(description: '  ', features: ['Speaking club', '', '  ']));

      expect(plan.description, isNull);
      expect(plan.features, ['Speaking club']);
    });
  });

  group('BillingSubscriptionModel', () {
    test('parses an active subscription', () {
      final me = BillingSubscriptionModel.fromJson(meJson());

      expect(me.isSubscribed, isTrue);
      expect(me.isTrial, isFalse);
      expect(me.status, 'active');
      expect(me.plan?.name, 'Standard');
      expect(me.daysLeft, 60);
      expect(me.endsAt, DateTime.parse('2026-12-08T09:16:12.819Z').toLocal());
      expect(me.isLifetime, isFalse);
      expect(me.canPurchase, isTrue);
    });

    test('a null daysLeft on a subscribed student is lifetime and hides buying', () {
      final me = BillingSubscriptionModel.fromJson(meJson(endsAt: null, daysLeft: null));

      expect(me.isLifetime, isTrue);
      expect(me.canPurchase, isFalse);
    });

    test('an unsubscribed student is not lifetime', () {
      final me = BillingSubscriptionModel.fromJson(notSubscribedJson());

      expect(me.isSubscribed, isFalse);
      expect(me.plan, isNull);
      expect(me.daysLeft, 0);
      expect(me.isLifetime, isFalse);
      expect(me.canPurchase, isTrue);
    });
  });

  group('orders', () {
    test('purchase response exposes order id and checkout urls', () {
      final purchase = BillingPurchaseModel.fromJson(purchaseJson());

      expect(purchase.id, orderId);
      expect(purchase.checkoutUrl, 'https://my.paylov.uz/checkout/abc');
      expect(purchase.returnUrl, 'https://students.ustadia.com/plans/return');
    });

    test('only SUCCESS and CANCELLED are final order states', () {
      expect(BillingOrderModel.fromJson(orderJson('SUCCESS')).state, BillingOrderState.success);
      expect(BillingOrderModel.fromJson(orderJson('CANCELLED')).state, BillingOrderState.cancelled);
      expect(BillingOrderModel.fromJson(orderJson('0')).state, BillingOrderState.pending);
      expect(BillingOrderModel.fromJson(orderJson('1')).state, BillingOrderState.pending);
      expect(BillingOrderModel.fromJson(const {'id': orderId, 'state': 2}).state,
          BillingOrderState.pending);
    });
  });

  group('BillingHistoryItemModel', () {
    test('parses a paid row and detects a queued plan', () {
      final item = BillingHistoryItemModel.fromJson(const {
        'id': '5448a0fd-723d-46d7-83b9-843f8693118b',
        'planName': 'Standard',
        'status': 'active',
        'source': 'payment',
        'paidAmount': '1000',
        'currency': 'UZS',
        'startsAt': '2026-11-08T09:16:12.819Z',
        'endsAt': '2026-12-08T09:16:12.819Z',
        'createdAt': '2026-10-09T09:46:54.041Z',
      });

      expect(item.status, BillingHistoryStatus.active);
      expect(item.isPaid, isTrue);
      expect(item.paidAmount, '1000');
      expect(item.isQueued(DateTime.parse('2026-10-10T00:00:00Z')), isTrue);
      expect(item.isQueued(DateTime.parse('2026-11-10T00:00:00Z')), isFalse);
    });

    test('maps trial, expired and canceled statuses', () {
      BillingHistoryStatus status(String raw) =>
          BillingHistoryItemModel.fromJson({'status': raw}).status;

      expect(status('trial'), BillingHistoryStatus.trial);
      expect(status('expired'), BillingHistoryStatus.expired);
      expect(status('canceled'), BillingHistoryStatus.canceled);
      expect(status('something'), BillingHistoryStatus.unknown);
    });
  });

  group('BillingAmount', () {
    test('groups whole sums without float conversion', () {
      expect(BillingAmount.group('36000'), '36 000');
      expect(BillingAmount.group('590000'), '590 000');
      expect(BillingAmount.group('1000'), '1 000');
      expect(BillingAmount.group('999'), '999');
      expect(BillingAmount.group('12345678901234567890'), '12 345 678 901 234 567 890');
    });

    test('keeps meaningful fractions and leaves unknown input untouched', () {
      expect(BillingAmount.group('1500000.50'), '1 500 000.50');
      expect(BillingAmount.group('36000.00'), '36 000');
      expect(BillingAmount.group('abc'), 'abc');
    });
  });

  group('BillingFailure', () {
    test('maps documented billing errors', () {
      expect(BillingFailure.fromDio(billingError(400, {'code': 'ALREADY_LIFETIME'})).type,
          BillingFailureType.alreadyLifetime);
      expect(BillingFailure.fromDio(billingError(400, {'code': 'PROVIDER_DISABLED'})).type,
          BillingFailureType.providerDisabled);
      expect(BillingFailure.fromDio(billingError(404, {'message': 'Plan not found'})).type,
          BillingFailureType.planNotFound);
      expect(
          BillingFailure.fromDio(billingError(404, {'message': 'Payment order not found'},
                  path: '/payments/orders/x'))
              .type,
          BillingFailureType.orderNotFound);
      expect(
          BillingFailure.fromDio(
              billingError(500, {'message': 'Failed to create WLCM payment checkout'})).message,
          BillingFailure.checkoutUnavailableMessage);
    });

    test('falls back to the backend message for other errors', () {
      final failure = BillingFailure.fromDio(billingError(400, {
        'message': ['planId must be a UUID']
      }));

      expect(failure.type, BillingFailureType.other);
      expect(failure.message, '[planId must be a UUID]');
    });
  });

  group('SubscriptionLabels', () {
    BillingPlanModel plan(int? days) => BillingPlanModel.fromJson(planJson(durationDays: days));

    test('describes plan durations', () {
      expect(SubscriptionLabels.duration(plan(30)), '1 month');
      expect(SubscriptionLabels.duration(plan(180)), '6 months');
      expect(SubscriptionLabels.duration(plan(365)), '1 year');
      expect(SubscriptionLabels.duration(plan(730)), '2 years');
      expect(SubscriptionLabels.duration(plan(7)), '7 days');
      expect(SubscriptionLabels.duration(plan(null)), 'Lifetime');
    });

    test('status view data follows the subscription kind', () {
      SubscriptionTone tone(Map<String, dynamic> json) =>
          SubscriptionStatusViewData.from(BillingSubscriptionModel.fromJson(json)).tone;

      expect(tone(meJson()), SubscriptionTone.active);
      expect(tone(meJson(isTrial: true, daysLeft: 5)), SubscriptionTone.trial);
      expect(tone(meJson(endsAt: null, daysLeft: null)), SubscriptionTone.lifetime);
      expect(tone(notSubscribedJson()), SubscriptionTone.inactive);
    });
  });
}
