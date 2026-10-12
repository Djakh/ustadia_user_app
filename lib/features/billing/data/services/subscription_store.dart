import 'package:flutter/foundation.dart';
import 'package:ustadia_user_app/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_subscription_model.dart';

/// Current subscription shared by the profile card and the subscription page.
class SubscriptionStore {
  final BillingRemoteDataSource billingRemoteDataSource;
  final ValueNotifier<BillingSubscriptionModel?> subscription = ValueNotifier(null);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  Future<BillingSubscriptionModel>? _inFlight;
  bool isUpToDate = false;

  SubscriptionStore({required this.billingRemoteDataSource});

  /// Concurrent callers share one request.
  Future<BillingSubscriptionModel> refresh() {
    return _inFlight ??= _load().whenComplete(() => _inFlight = null);
  }

  Future<BillingSubscriptionModel> _load() async {
    loading.value = true;
    try {
      final value = await billingRemoteDataSource.fetchMySubscription();
      subscription.value = value;
      isUpToDate = true;
      return value;
    } finally {
      loading.value = false;
    }
  }

  Future<void> refreshIfNeeded() async {
    if (subscription.value != null && isUpToDate) return;
    try {
      await refresh();
    } catch (_) {
      // The card keeps its last value; the subscription page shows the error.
    }
  }

  void markStale() {
    isUpToDate = false;
  }
}
