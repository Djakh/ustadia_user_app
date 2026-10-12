import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/services/subscription_expired_handler.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_amount.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_order_model.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_plan_model.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_bloc/subscription_bloc.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_bloc/subscription_event.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_bloc/subscription_state.dart';
import 'package:ustadia_user_app/features/billing/presentation/widgets/current_subscription_card.dart';
import 'package:ustadia_user_app/features/billing/presentation/widgets/plan_option_card.dart';
import 'package:ustadia_user_app/features/billing/presentation/widgets/purchase_result_sheet.dart';
import 'package:ustadia_user_app/features/billing/presentation/widgets/subscription_expired_banner.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class SubscriptionPageParams {
  /// Opened automatically because the backend answered `402 SUBSCRIPTION_EXPIRED`.
  final bool isExpired;

  const SubscriptionPageParams({this.isExpired = false});
}

class SubscriptionPage extends StatefulWidget {
  final SubscriptionPageParams params;

  const SubscriptionPage({super.key, this.params = const SubscriptionPageParams()});

  @override
  State<SubscriptionPage> createState() => SubscriptionPageState();
}

class SubscriptionPageState extends State<SubscriptionPage> {
  final SubscriptionBloc subscriptionBloc = sl<SubscriptionBloc>();
  final SubscriptionExpiredHandler? expiredHandler =
      sl.isRegistered<SubscriptionExpiredHandler>() ? sl<SubscriptionExpiredHandler>() : null;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    expiredHandler?.paywallShown();
    subscriptionBloc.add(const SubscriptionRequested());
  }

  @override
  void dispose() {
    expiredHandler?.paywallHidden();
    subscriptionBloc.close();
    super.dispose();
  }

  /// --- Methods ---

  Future<void> reload() {
    final completer = Completer<void>();
    subscriptionBloc.add(SubscriptionRequested(showLoading: false, completer: completer));
    return completer.future;
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message.tr())));
  }

  Future<void> openCheckout(BillingPurchaseModel purchase) async {
    final reachedReturnUrl = await context.push<bool>(subscriptionCheckoutRoute, extra: purchase);
    if (!mounted) return;
    subscriptionBloc.add(SubscriptionCheckoutClosed(reachedReturnUrl: reachedReturnUrl == true));
  }

  Future<void> showResult(SubscriptionState state) async {
    await PurchaseResultSheet.show(context,
        status: state.purchaseStatus,
        subscription: state.subscription,
        message: state.purchaseMessage);
    if (!mounted) return;
    subscriptionBloc.add(const SubscriptionPurchaseAcknowledged());
    if (state.purchaseStatus == PurchaseStatus.success) await onPurchaseSucceeded();
  }

  /// Screens that failed with 402 keep their error state, so after paying from
  /// the paywall the app reloads from the splash, like after a teacher swap.
  Future<void> onPurchaseSucceeded() async {
    expiredHandler?.reset();
    if (!widget.params.isExpired) return;
    await resetTeacherScopedData();
    if (mounted) context.go(splashRoute);
  }

  void purchaseListener(BuildContext context, SubscriptionState state) {
    switch (state.purchaseStatus) {
      case PurchaseStatus.awaitingCheckout:
        final purchase = state.purchase;
        if (purchase != null) openCheckout(purchase);
      case PurchaseStatus.success || PurchaseStatus.cancelled || PurchaseStatus.pending:
        showResult(state);
      case PurchaseStatus.notCompleted:
        showMessage('Payment was not completed');
        subscriptionBloc.add(const SubscriptionPurchaseAcknowledged());
      case PurchaseStatus.failure:
        showMessage(state.purchaseMessage ?? 'Request failed. Please try again.');
        subscriptionBloc.add(const SubscriptionPurchaseAcknowledged());
      case PurchaseStatus.idle || PurchaseStatus.creatingOrder || PurchaseStatus.verifying:
        break;
    }
  }

  /// --- Widgets ---

  Widget sectionTitle(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Choose a plan'.tr(), style: Style.body2w7(context)),
        const SizedBox(height: 2),
        Text('A new plan starts right after your current one ends — no days are lost.'.tr(),
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget lifetimeNotice(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: AppColors.greenE7, borderRadius: Style.border20),
      child: Row(children: [
        const Icon(Icons.verified_rounded, color: AppColors.green36),
        const SizedBox(width: 10),
        Expanded(
            child: Text('You have lifetime access. There is nothing else to buy.'.tr(),
                style: Style.small3w5(context).copyWith(color: AppColors.green36)))
      ]));

  Widget planCard(SubscriptionState state, BillingPlanModel plan) {
    final subscription = state.subscription;
    final isCurrent = (subscription?.isSubscribed ?? false) &&
        !(subscription?.isTrial ?? false) &&
        subscription?.plan?.id == plan.id;
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: PlanOptionCard(
            plan: plan,
            isSelected: state.canPurchase && plan.id == state.selectedPlanId,
            isCurrent: isCurrent,
            isEnabled: state.canPurchase && !state.purchaseStatus.isBusy,
            onTap: () => subscriptionBloc.add(SubscriptionPlanSelected(plan.id))));
  }

  Widget historyLink(BuildContext context) => Center(
      child: TextButton.icon(
          onPressed: () => context.push(subscriptionHistoryRoute),
          icon: const Icon(Icons.history_rounded, size: 20),
          label: Text('Subscription history'.tr(), style: Style.small3w5(context)),
          style: TextButton.styleFrom(foregroundColor: context.cs.primary)));

  Widget content(BuildContext context, SubscriptionState state) {
    final subscription = state.subscription;
    final showExpired = widget.params.isExpired && !(subscription?.isSubscribed ?? false);
    return RefreshIndicator(
        onRefresh: reload,
        color: context.cs.primary,
        child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 16, bottom: 16),
            children: [
              if (showExpired) ...[const SubscriptionExpiredBanner(), const SizedBox(height: 12)],
              if (subscription != null) ...[
                CurrentSubscriptionCard(subscription: subscription),
                const SizedBox(height: 20)
              ],
              if (!state.canPurchase)
                lifetimeNotice(context)
              else if (state.plans.isEmpty)
                emptyPlans(context)
              else ...[
                sectionTitle(context),
                const SizedBox(height: 12),
                ...state.plans.map((plan) => planCard(state, plan)),
              ],
              const SizedBox(height: 4),
              historyLink(context)
            ]));
  }

  Widget emptyPlans(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text('No plans are available right now. Please check back later.'.tr(),
          textAlign: TextAlign.center,
          style: Style.small3w4(context, color: TextColorRole.greyColor)));

  Widget verifyingPanel(BuildContext context) => Row(children: [
        SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3, color: context.cs.primary)),
        const SizedBox(width: 14),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Confirming your payment…'.tr(), style: Style.bodyw6(context)),
          const SizedBox(height: 2),
          Text('This can take up to 2 minutes. Please keep this screen open.'.tr(),
              style: Style.small2w4(context, color: TextColorRole.greyColor))
        ]))
      ]);

  Widget payButton(BuildContext context, SubscriptionState state) {
    final plan = state.selectedPlan;
    final price = plan == null ? '' : BillingAmount.format(plan.price, currency: plan.currency);
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Button.primary(
          onTap: () => subscriptionBloc.add(const SubscriptionPurchaseRequested()),
          // Kept "available" while busy so the loader stays on the green button.
          isLoading: state.purchaseStatus.isBusy,
          isAvialable: state.canStartPurchase || state.purchaseStatus.isBusy,
          text: plan == null
              ? 'Continue to payment'.tr()
              : 'Pay {price}'.tr(namedArgs: {'price': price})),
      const SizedBox(height: 10),
      Text.rich(
          TextSpan(children: [
            const WidgetSpan(
                alignment: PlaceholderAlignment.middle,
                child: Padding(
                    padding: EdgeInsets.only(right: 6),
                    child: Icon(Icons.lock_rounded, size: 14, color: AppColors.gray8D))),
            TextSpan(text: 'Secure payment via Paylov. A payment system fee may be added.'.tr())
          ]),
          textAlign: TextAlign.center,
          style: Style.small2w4(context, color: TextColorRole.greyColor))
    ]);
  }

  Widget bottomPanel(BuildContext context, SubscriptionState state) {
    if (!state.status.isSuccess || !state.canPurchase || state.plans.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
        margin: const EdgeInsets.only(top: 4),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: context.cs.surface,
            borderRadius: Style.border24,
            boxShadow: const [
              BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -2))
            ]),
        child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: state.purchaseStatus == PurchaseStatus.verifying
                ? verifyingPanel(context)
                : payButton(context, state)));
  }

  Widget errorView(String message) => Center(
      child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message.tr(),
                textAlign: TextAlign.center,
                style: Style.small3w4(context, color: TextColorRole.greyColor)),
            const SizedBox(height: 8),
            Button.text(
                onTap: () => subscriptionBloc.add(const SubscriptionRequested()),
                text: 'Reload'.tr())
          ])));

  Widget body(BuildContext context) =>
      BlocStatusView<SubscriptionBloc, SubscriptionState, SubscriptionState>(
          bloc: subscriptionBloc,
          statusOf: (state) => state.status,
          errorOf: (state) => state.errorMessage,
          data: (state) => state,
          isEmpty: (_) => false,
          listenWhen: (previous, current) => previous.purchaseStatus != current.purchaseStatus,
          listener: purchaseListener,
          loading: ShimmerList(
              itemCount: 4,
              itemHeight: 96,
              padding: const EdgeInsets.only(top: 16),
              borderRadius: Style.border20),
          errorBuilder: errorView,
          builder: (context, state) => Column(
              children: [Expanded(child: content(context, state)), bottomPanel(context, state)]));

  @override
  Widget build(BuildContext context) => Scaffold(
      body:
          PrimaryBackground(title: 'Subscription'.tr(), isScrollable: false, child: body(context)));
}
