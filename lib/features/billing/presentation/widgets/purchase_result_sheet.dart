import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_subscription_model.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_bloc/subscription_state.dart';
import 'package:ustadia_user_app/features/billing/presentation/widgets/subscription_labels.dart';

/// Final word on a payment: activated, cancelled, or still waiting for the bank.
class PurchaseResultSheet extends StatelessWidget {
  final PurchaseStatus status;
  final BillingSubscriptionModel? subscription;
  final String? message;

  const PurchaseResultSheet({super.key, required this.status, this.subscription, this.message});

  static Future<void> show(BuildContext context,
          {required PurchaseStatus status,
          BillingSubscriptionModel? subscription,
          String? message}) =>
      showModalBottomSheet<void>(
          context: context,
          useRootNavigator: true,
          backgroundColor: context.cs.surface,
          shape: RoundedRectangleBorder(borderRadius: Style.borderVer24),
          builder: (_) =>
              PurchaseResultSheet(status: status, subscription: subscription, message: message));

  IconData get icon => switch (status) {
        PurchaseStatus.success => Icons.check_rounded,
        PurchaseStatus.cancelled => Icons.close_rounded,
        _ => Icons.schedule_rounded,
      };

  Color get accent => switch (status) {
        PurchaseStatus.success => AppColors.primary,
        PurchaseStatus.cancelled => AppColors.error,
        _ => AppColors.orange9200,
      };

  Color get background => switch (status) {
        PurchaseStatus.success => AppColors.greenE7,
        PurchaseStatus.cancelled => AppColors.redE2,
        _ => AppColors.orangeEB,
      };

  String get title => switch (status) {
        PurchaseStatus.success => 'Plan activated'.tr(),
        PurchaseStatus.cancelled => 'Payment cancelled'.tr(),
        _ => 'Payment is being processed'.tr(),
      };

  String get subtitle {
    if (message != null && message!.trim().isNotEmpty) return message!.tr();
    switch (status) {
      case PurchaseStatus.success:
        final subscription = this.subscription;
        final planName = subscription?.plan?.name ?? '';
        final endsAt = subscription?.endsAt;
        if (subscription?.isLifetime ?? false) {
          return '{plan} is active with lifetime access.'.tr(namedArgs: {'plan': planName});
        }
        if (endsAt != null && planName.isNotEmpty) {
          return '{plan} is active until {date}.'
              .tr(namedArgs: {'plan': planName, 'date': SubscriptionLabels.date(endsAt)});
        }
        return 'Your subscription is active. Enjoy learning!'.tr();
      case PurchaseStatus.cancelled:
        return 'No money was charged. You can try again anytime.'.tr();
      default:
        return 'The payment has not arrived yet. Please check again in a few minutes.'.tr();
    }
  }

  String get actionText =>
      status == PurchaseStatus.success ? 'Continue learning'.tr() : 'Got it'.tr();

  Widget statusIcon() => Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Center(
          child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
              child: Icon(icon, color: AppColors.white, size: 28))));

  @override
  Widget build(BuildContext context) => SafeArea(
      child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: AppColors.gray200, borderRadius: Style.border4)),
            const SizedBox(height: 24),
            statusIcon(),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: Style.body3w7(context)),
            const SizedBox(height: 8),
            Text(subtitle,
                textAlign: TextAlign.center,
                style: Style.small3w4(context, color: TextColorRole.greyColor)),
            const SizedBox(height: 24),
            Button.primary(onTap: () => Navigator.of(context).pop(), text: actionText)
          ])));
}
