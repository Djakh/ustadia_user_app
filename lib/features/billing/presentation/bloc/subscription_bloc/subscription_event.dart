import 'dart:async';

import 'package:equatable/equatable.dart';

abstract class SubscriptionEvent extends Equatable {
  const SubscriptionEvent();

  @override
  List<Object?> get props => [];
}

/// Loads plans and the current subscription.
class SubscriptionRequested extends SubscriptionEvent {
  final bool showLoading;

  /// Completed when loading ends, so pull-to-refresh can stop its spinner.
  final Completer<void>? completer;

  const SubscriptionRequested({this.showLoading = true, this.completer});

  @override
  List<Object?> get props => [showLoading];
}

class SubscriptionPlanSelected extends SubscriptionEvent {
  final String planId;

  const SubscriptionPlanSelected(this.planId);

  @override
  List<Object?> get props => [planId];
}

/// Creates a new order for the selected plan.
class SubscriptionPurchaseRequested extends SubscriptionEvent {
  const SubscriptionPurchaseRequested();
}

/// The checkout WebView is gone. [reachedReturnUrl] is true when Paylov sent
/// the student back; false when the student closed it themselves.
class SubscriptionCheckoutClosed extends SubscriptionEvent {
  final bool reachedReturnUrl;

  const SubscriptionCheckoutClosed({required this.reachedReturnUrl});

  @override
  List<Object?> get props => [reachedReturnUrl];
}

/// The UI has shown the purchase result; go back to idle.
class SubscriptionPurchaseAcknowledged extends SubscriptionEvent {
  const SubscriptionPurchaseAcknowledged();
}
