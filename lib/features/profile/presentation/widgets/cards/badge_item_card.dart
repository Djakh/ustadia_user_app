import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_badge_model.dart';

class BadgeItemCard extends StatelessWidget {
  final ProfileBadgeModel profileBadgeModel;
  const BadgeItemCard({super.key, required this.profileBadgeModel});

  Container get image => Container(
      width: 64,
      height: 64,
      decoration: const BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Color(0x12000000), blurRadius: 8, offset: Offset(0, 4))]),
      child:
          Padding(padding: const EdgeInsets.all(10), child: Image.asset(profileBadgeModel.asset)));

  Widget view(BuildContext context) => Column(children: [
        image,
        const SizedBox(height: 8),
        Text(profileBadgeModel.label,
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
