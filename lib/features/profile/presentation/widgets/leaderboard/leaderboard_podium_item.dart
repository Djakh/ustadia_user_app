import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/avatars/user_avatar.dart';
import 'package:ustadia_user_app/features/profile/data/models/leaderboard_podium_model.dart';

class LeaderboardPodiumItem extends StatelessWidget {
  final LeaderboardPodiumModel podium;

  final double avatarRadius;

  const LeaderboardPodiumItem({
    super.key,
    required this.podium,
    this.avatarRadius = 28,
  });

  Widget xpChip(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: AppColors.orange033, borderRadius: Style.border95),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.asset(AppImages.xpLightningWhite),
        const SizedBox(width: 4),
        Text('{xp} XP'.tr(namedArgs: {'xp': '${podium.user.xp}'}),
            style: Style.smallw6(context, color: TextColorRole.whiteColor))
      ]));

  Widget podiumImage() => SvgPicture.asset(podium.placeAsset);

  Column view(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          UserAvatar(radius: avatarRadius, imageUrl: podium.user.avatarUrl),
          const SizedBox(height: 8),
          Text(podium.user.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Style.small3w4(context)),
          const SizedBox(height: 4),
          xpChip(context),
          const SizedBox(height: 8),
          podiumImage(),
        ],
      );

  @override
  Widget build(BuildContext context) => SizedBox(width: double.infinity, child: view(context));
}
