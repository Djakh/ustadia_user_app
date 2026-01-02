import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_stats_model.dart';

class ProfileStatCard extends StatelessWidget {
  final ProfileStatsModel profileStatsModel;
  const ProfileStatCard({super.key, required this.profileStatsModel});

  Widget get image => Container(
      decoration: const BoxDecoration(color: AppColors.gray100, shape: BoxShape.circle),
      child: Image.asset(profileStatsModel.icon, width: 32, height: 32));

  Widget view(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 20),
        image,
        const SizedBox(height: 20),
        Text(profileStatsModel.title,
            style: Style.small3w5(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 4),
        Text(profileStatsModel.value, style: Style.small3w7(context))
      ]);

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: Style.border24,
          boxShadow: const [
            BoxShadow(color: AppColors.gray400, blurRadius: 0.4, offset: Offset(0, 1))
          ]),
      child: view(context));
}
