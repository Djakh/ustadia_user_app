import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class AssignmentAudioCard extends StatelessWidget {
  const AssignmentAudioCard({super.key});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: Style.border24,
          border: Border.all(color: AppColors.gray100),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))
          ]),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Row(children: [
          Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
              child: const Icon(Icons.volume_up, color: AppColors.white)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Audio lesson', style: Style.bodyw6(context)),
            Text('Tap to listen',
                style: Style.small2w4(context, color: TextColorRole.greyColor))
          ])
        ]),
        Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.gray50, borderRadius: BorderRadius.circular(20)),
            child: const Icon(Icons.play_arrow, color: AppColors.primary))
      ]));
}
