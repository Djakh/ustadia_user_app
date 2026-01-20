import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class DashboardStrakCard extends StatelessWidget {
  const DashboardStrakCard({super.key});

  Widget view(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.orangeEB,
          borderRadius: Style.border20,
          border: Border.all(color: AppColors.orangeD4)),
      child: Row(children: [
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('You have learned for 1 days in a row.',
              style: Style.bodyw7(context).copyWith(color: AppColors.orange549)),
          const SizedBox(height: 4),
          Text('Nice work. Keep it going.',
              style: Style.small3w5(context).copyWith(color: AppColors.orange549))
        ])),
        Image.asset(AppImages.strakFire),
      ]));

  @override
  Widget build(BuildContext context) => view(context);
}
