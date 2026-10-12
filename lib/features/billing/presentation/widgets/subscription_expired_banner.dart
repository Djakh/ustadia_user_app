import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

/// Shown when the student was sent here by a `402 SUBSCRIPTION_EXPIRED`.
class SubscriptionExpiredBanner extends StatelessWidget {
  const SubscriptionExpiredBanner({super.key});

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: AppColors.redE2,
          borderRadius: Style.border20,
          border: Border.all(color: AppColors.redA9)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.error_outline_rounded, color: AppColors.error, size: 24),
        const SizedBox(width: 10),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Your subscription has expired'.tr(),
              style: Style.bodyw6(context).copyWith(color: AppColors.error)),
          const SizedBox(height: 2),
          Text('Choose a plan below to continue your lessons and practice.'.tr(),
              style: Style.small3w4(context).copyWith(color: AppColors.gray700))
        ]))
      ]));
}
