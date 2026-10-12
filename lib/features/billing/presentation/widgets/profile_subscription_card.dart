import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_box.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_subscription_model.dart';
import 'package:ustadia_user_app/features/billing/data/services/subscription_store.dart';
import 'package:ustadia_user_app/features/billing/presentation/widgets/subscription_labels.dart';
import 'package:ustadia_user_app/router.dart';

/// Compact subscription status on the profile tab; opens the subscription page.
class ProfileSubscriptionCard extends StatelessWidget {
  final SubscriptionStore subscriptionStore;

  const ProfileSubscriptionCard({super.key, required this.subscriptionStore});

  Future<void> openSubscription(BuildContext context) async {
    await context.push(subscriptionRoute);
    subscriptionStore.markStale();
    await subscriptionStore.refreshIfNeeded();
  }

  Widget leadingIcon(SubscriptionStatusViewData? data) => Container(
      width: 44,
      height: 44,
      decoration:
          BoxDecoration(color: data?.background ?? AppColors.greenE7, shape: BoxShape.circle),
      child: Icon(data?.icon ?? Icons.workspace_premium_rounded,
          color: data?.accent ?? AppColors.green36, size: 24));

  Widget actionPill(BuildContext context, String label) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(color: context.cs.primary, borderRadius: Style.border95),
      child: Text(label, style: Style.small3w5(context, color: TextColorRole.whiteColor)));

  Widget view(BuildContext context, BillingSubscriptionModel? subscription) {
    final data = subscription == null ? null : SubscriptionStatusViewData.from(subscription);
    return Row(children: [
      leadingIcon(data),
      const SizedBox(width: 12),
      Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(data?.title ?? 'Subscription'.tr(),
            maxLines: 1, overflow: TextOverflow.ellipsis, style: Style.bodyw6(context)),
        const SizedBox(height: 2),
        Text(data?.subtitle ?? 'See plans and your current status'.tr(),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Style.small2w4(context, color: TextColorRole.greyColor))
      ])),
      const SizedBox(width: 8),
      actionPill(context, data?.actionLabel ?? 'Plans'.tr())
    ]);
  }

  /// Shadow sits outside the Material so the ink clip does not cut it off.
  Widget card(BuildContext context, BillingSubscriptionModel? subscription) => DecoratedBox(
      decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: Style.border20,
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))
          ]),
      child: Material(
          color: Colors.transparent,
          borderRadius: Style.border20,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
              onTap: () => openSubscription(context),
              child:
                  Padding(padding: const EdgeInsets.all(16), child: view(context, subscription)))));

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<BillingSubscriptionModel?>(
      valueListenable: subscriptionStore.subscription,
      builder: (context, subscription, _) => ValueListenableBuilder<bool>(
          valueListenable: subscriptionStore.loading,
          builder: (context, isLoading, __) {
            if (isLoading && subscription == null) {
              return Shimmer(child: ShimmerBox(height: 76, borderRadius: Style.border20));
            }
            return card(context, subscription);
          }));
}
