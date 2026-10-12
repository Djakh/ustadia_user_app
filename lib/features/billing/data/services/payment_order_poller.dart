import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_order_model.dart';

enum PaymentOrderOutcome { success, cancelled, timeout, notFound, aborted }

/// The subscription is written by the Paylov webhook, which may land a few
/// seconds after the student is back in the app. The app never decides
/// "paid" on its own; it asks the server until the order is final.
class PaymentOrderPoller {
  final BillingRemoteDataSource billingRemoteDataSource;
  final Duration interval;
  final Duration timeout;
  final Future<void> Function(Duration duration) delay;

  PaymentOrderPoller(
      {required this.billingRemoteDataSource,
      this.interval = const Duration(seconds: 3),
      this.timeout = const Duration(minutes: 2),
      Future<void> Function(Duration duration)? delay})
      : delay = delay ?? Future<void>.delayed;

  int get defaultAttempts =>
      math.max(1, timeout.inMilliseconds ~/ math.max(1, interval.inMilliseconds));

  /// Checks right away, then every [interval] until [timeout]. Network hiccups
  /// and server errors are retried; a client error other than 404 is rethrown.
  Future<PaymentOrderOutcome> poll(String orderId,
      {int? maxAttempts, bool Function()? isAborted}) async {
    final attempts = math.max(1, maxAttempts ?? defaultAttempts);
    for (var attempt = 0; attempt < attempts; attempt++) {
      if (isAborted?.call() ?? false) return PaymentOrderOutcome.aborted;
      try {
        final order = await billingRemoteDataSource.fetchOrder(orderId);
        switch (order.state) {
          case BillingOrderState.success:
            return PaymentOrderOutcome.success;
          case BillingOrderState.cancelled:
            return PaymentOrderOutcome.cancelled;
          case BillingOrderState.pending:
            break;
        }
      } on DioException catch (error) {
        final statusCode = error.response?.statusCode;
        if (statusCode == 404) return PaymentOrderOutcome.notFound;
        if (statusCode != null && statusCode >= 400 && statusCode < 500) rethrow;
      }
      if (attempt < attempts - 1) await delay(interval);
    }
    return PaymentOrderOutcome.timeout;
  }
}
