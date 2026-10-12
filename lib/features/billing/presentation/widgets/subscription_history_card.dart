import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_amount.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_history_item_model.dart';
import 'package:ustadia_user_app/features/billing/presentation/widgets/subscription_labels.dart';

class SubscriptionHistoryCard extends StatelessWidget {
  final BillingHistoryItemModel item;
  final DateTime now;

  const SubscriptionHistoryCard({super.key, required this.item, required this.now});

  (String, Color, Color) get statusStyle {
    if (item.isQueued(now)) return ('Queued'.tr(), AppColors.blueD3, AppColors.blueFF);
    return switch (item.status) {
      BillingHistoryStatus.active => ('Active'.tr(), AppColors.green36, AppColors.greenE7),
      BillingHistoryStatus.trial => ('Trial'.tr(), AppColors.orange5A, AppColors.orangeEB),
      BillingHistoryStatus.expired => ('Expired'.tr(), AppColors.gray700, AppColors.gray100),
      BillingHistoryStatus.canceled => ('Replaced'.tr(), AppColors.gray700, AppColors.gray100),
      BillingHistoryStatus.unknown => ('-', AppColors.gray700, AppColors.gray100),
    };
  }

  String get period {
    final startsAt = item.startsAt;
    final endsAt = item.endsAt;
    if (startsAt == null) return '-';
    if (endsAt == null) {
      return '{date} · lifetime'.tr(namedArgs: {'date': SubscriptionLabels.date(startsAt)});
    }
    return '${SubscriptionLabels.date(startsAt)} – ${SubscriptionLabels.date(endsAt)}';
  }

  String get amount {
    final paidAmount = item.paidAmount;
    if (!item.isPaid || paidAmount == null) return 'Free'.tr();
    return BillingAmount.format(paidAmount, currency: item.currency);
  }

  Widget statusChip(BuildContext context) {
    final (label, text, background) = statusStyle;
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(color: background, borderRadius: Style.border95),
        child: Text(label, style: Style.small2w5(context).copyWith(color: text)));
  }

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border20),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(item.planName.isEmpty ? 'Subscription'.tr() : item.planName,
                  maxLines: 1, overflow: TextOverflow.ellipsis, style: Style.bodyw7(context))),
          const SizedBox(width: 8),
          statusChip(context)
        ]),
        const SizedBox(height: 10),
        Row(children: [
          const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.gray8D),
          const SizedBox(width: 6),
          Expanded(
              child: Text(period, style: Style.small3w4(context, color: TextColorRole.greyColor))),
          Text(amount, style: Style.small3w7(context))
        ])
      ]));
}
