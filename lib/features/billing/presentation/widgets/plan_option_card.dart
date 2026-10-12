import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_amount.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_plan_model.dart';
import 'package:ustadia_user_app/features/billing/presentation/widgets/subscription_labels.dart';

class PlanOptionCard extends StatelessWidget {
  final BillingPlanModel plan;
  final bool isSelected;
  final bool isCurrent;
  final bool isEnabled;
  final VoidCallback onTap;

  const PlanOptionCard(
      {super.key,
      required this.plan,
      required this.isSelected,
      required this.isCurrent,
      required this.onTap,
      this.isEnabled = true});

  static const Duration animationDuration = Duration(milliseconds: 200);

  Widget radio(BuildContext context) => AnimatedContainer(
      duration: animationDuration,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isSelected ? context.cs.primary : Colors.transparent,
          border: Border.all(color: isSelected ? context.cs.primary : AppColors.gray300, width: 2)),
      child: isSelected ? const Icon(Icons.check_rounded, size: 16, color: AppColors.white) : null);

  Widget chip(BuildContext context, String label, {required Color color, required Color text}) =>
      Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(color: color, borderRadius: Style.border95),
          child: Text(label, style: Style.small2w5(context).copyWith(color: text, height: 1.2)));

  Widget titleRow(BuildContext context) =>
      Wrap(spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Text(plan.name, style: Style.bodyw7(context)),
        chip(context, SubscriptionLabels.duration(plan),
            color: AppColors.gray100, text: AppColors.gray700),
        if (isCurrent)
          chip(context, 'Current'.tr(), color: AppColors.greenE7, text: AppColors.green36),
      ]);

  Widget price(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(BillingAmount.group(plan.price),
            style: Style.body2w7(context)
                .copyWith(color: isSelected ? context.cs.primary : context.cs.onSurface)),
        Text(plan.currency.toUpperCase() == 'UZS' ? 'UZS'.tr() : plan.currency,
            style: Style.small2w4(context, color: TextColorRole.greyColor))
      ]);

  Widget feature(BuildContext context, String text) => Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.check_circle_rounded, size: 16, color: AppColors.primary)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: Style.small3w4(context)))
      ]));

  Widget view(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: const EdgeInsets.only(top: 2), child: radio(context)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          titleRow(context),
          if (plan.description != null) ...[
            const SizedBox(height: 4),
            Text(plan.description!, style: Style.small3w4(context, color: TextColorRole.greyColor)),
          ],
          ...plan.features.map((item) => feature(context, item)),
        ])),
        const SizedBox(width: 12),
        price(context)
      ]);

  @override
  Widget build(BuildContext context) => Semantics(
      button: true,
      selected: isSelected,
      enabled: isEnabled,
      child: Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: isEnabled ? onTap : null,
              borderRadius: Style.border20,
              child: AnimatedContainer(
                  duration: animationDuration,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.greenE7.withValues(alpha: 0.45)
                          : context.cs.surface,
                      borderRadius: Style.border20,
                      border: Border.all(
                          color: isSelected ? context.cs.primary : AppColors.gray200,
                          width: isSelected ? 2 : 1)),
                  child: view(context)))));
}
