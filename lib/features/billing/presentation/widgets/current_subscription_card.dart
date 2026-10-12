import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_subscription_model.dart';
import 'package:ustadia_user_app/features/billing/presentation/widgets/subscription_labels.dart';

/// Hero card at the top of the subscription page.
class CurrentSubscriptionCard extends StatelessWidget {
  final BillingSubscriptionModel subscription;

  const CurrentSubscriptionCard({super.key, required this.subscription});

  /// Share of the period that is still left; only for dated, known-length plans.
  double? remainingShare() {
    final startsAt = subscription.startsAt;
    final endsAt = subscription.endsAt;
    if (!subscription.isSubscribed || startsAt == null || endsAt == null) return null;
    final total = endsAt.difference(startsAt).inMinutes;
    if (total <= 0) return null;
    final left = endsAt.difference(DateTime.now()).inMinutes;
    return (left / total).clamp(0.0, 1.0);
  }

  Widget statusIcon(SubscriptionStatusViewData data) => Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(color: data.background, shape: BoxShape.circle),
      child: Icon(data.icon, color: data.accent, size: 26));

  Widget badge(BuildContext context, SubscriptionStatusViewData data) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: data.background, borderRadius: Style.border95),
      child: Text(data.badge, style: Style.small2w5(context).copyWith(color: data.accent)));

  Widget header(BuildContext context, SubscriptionStatusViewData data) => Row(children: [
        statusIcon(data),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Current plan'.tr(), style: Style.small2w5(context, color: TextColorRole.greyColor)),
          const SizedBox(height: 2),
          Text(data.title,
              maxLines: 1, overflow: TextOverflow.ellipsis, style: Style.body2w7(context)),
        ])),
        const SizedBox(width: 8),
        badge(context, data)
      ]);

  Widget progress(BuildContext context, SubscriptionStatusViewData data, double share) => ClipRRect(
      borderRadius: Style.border95,
      child: LinearProgressIndicator(
          value: share, minHeight: 6, color: data.accent, backgroundColor: AppColors.gray100));

  @override
  Widget build(BuildContext context) {
    final data = SubscriptionStatusViewData.from(subscription);
    final share = remainingShare();
    return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: context.cs.surface,
            borderRadius: Style.border24,
            boxShadow: const [
              BoxShadow(color: AppColors.gray400, blurRadius: 0.4, offset: Offset(0, 1))
            ]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          header(context, data),
          const SizedBox(height: 14),
          if (share != null) ...[progress(context, data, share), const SizedBox(height: 10)],
          Text(data.subtitle, style: Style.small3w5(context, color: TextColorRole.greyColor))
        ]));
  }
}
