import 'dart:math' as math;

/// Opens the paywall when the backend answers `402 SUBSCRIPTION_EXPIRED`.
///
/// One screen usually fires several requests at once, so the paywall is opened
/// only once per burst: never while it is already visible, never on auth pages
/// (they replace the whole stack) and not again right after the student closed it.
class SubscriptionExpiredHandler {
  final void Function() openPaywall;
  final String Function() currentPath;
  final Set<String> ignoredPaths;
  final Duration reopenCooldown;
  final Duration pendingTimeout;
  final DateTime Function() clock;

  int visiblePaywalls = 0;
  DateTime? pendingSince;
  DateTime? lastClosedAt;

  SubscriptionExpiredHandler(
      {required this.openPaywall,
      required this.currentPath,
      this.ignoredPaths = const {},
      this.reopenCooldown = const Duration(seconds: 5),
      this.pendingTimeout = const Duration(seconds: 3),
      DateTime Function()? clock})
      : clock = clock ?? DateTime.now;

  bool get isPaywallVisible => visiblePaywalls > 0;

  bool get isOpening {
    final since = pendingSince;
    return since != null && clock().difference(since) < pendingTimeout;
  }

  bool get isCoolingDown {
    final closedAt = lastClosedAt;
    return closedAt != null && clock().difference(closedAt) < reopenCooldown;
  }

  void handle() {
    if (isPaywallVisible || isOpening || isCoolingDown) return;
    if (ignoredPaths.contains(currentPath())) return;
    pendingSince = clock();
    openPaywall();
  }

  /// Called by the subscription page itself, so a page opened by the student
  /// also blocks a second automatic one.
  void paywallShown() {
    visiblePaywalls++;
    pendingSince = null;
  }

  void paywallHidden() {
    visiblePaywalls = math.max(0, visiblePaywalls - 1);
    if (visiblePaywalls == 0) lastClosedAt = clock();
  }

  /// After a successful purchase nothing should hold the next paywall back.
  void reset() {
    pendingSince = null;
    lastClosedAt = null;
  }
}
