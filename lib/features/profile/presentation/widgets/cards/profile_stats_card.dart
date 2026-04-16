import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_stats_model.dart';

class ProfileStatCard extends StatelessWidget {
  final ProfileStatsModel profileStatsModel;
  final VoidCallback? onTap;
  const ProfileStatCard({super.key, required this.profileStatsModel, this.onTap});

  Widget get image => Container(
      decoration: const BoxDecoration(color: AppColors.gray100, shape: BoxShape.circle),
      child: Image.asset(profileStatsModel.icon, width: 32, height: 32));

  Widget view(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            image,
            const SizedBox(height: 12),
            Text(profileStatsModel.title,
                style: Style.small3w5(context, color: TextColorRole.greyColor)),
            const SizedBox(height: 4),
            Text(profileStatsModel.value, style: Style.small3w7(context)),
            if (profileStatsModel.subtitle != null &&
                profileStatsModel.subtitle!.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(profileStatsModel.subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Style.small3w5(context,
                      color: onTap != null ? TextColorRole.primaryColor : TextColorRole.greyColor))
            ]
          ]);

  @override
  Widget build(BuildContext context) => Expanded(
        child: Material(
            color: Colors.transparent,
            child: InkWell(
                onTap: onTap,
                borderRadius: Style.border24,
                child: Ink(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    height: 140,
                    decoration: BoxDecoration(
                        color: context.cs.surface,
                        borderRadius: Style.border24,
                        boxShadow: const [
                          BoxShadow(color: AppColors.gray400, blurRadius: 0.4, offset: Offset(0, 1))
                        ]),
                    child: view(context)))),
      );
}
