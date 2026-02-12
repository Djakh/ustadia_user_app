import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/router.dart';

class LeaderBoardCard extends StatelessWidget {
  const LeaderBoardCard({super.key});

  Widget leaderboardTitleAndSub(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Leaderboard'.tr(), style: Style.body3w7(context)),
        Text('See how you compare this week.'.tr(),
            style: Style.bodyw4(context, color: TextColorRole.greyColor)),
      ]);

  Row leaderboardTitleAndSubAndCub(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        leaderboardTitleAndSub(context),
        Image.asset(AppImages.profileCupIcon, width: 48, height: 48)
      ]);

  Container rankBox(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.grayFB, borderRadius: Style.border16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Your rank this week: #12'.tr(), style: Style.bodyw5(context)),
        const SizedBox(height: 2),
        Text('You finished 8 lessons.'.tr(),
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]));

  Widget leadboardButton(BuildContext context) =>
      Button.primary(onTap: () => context.push(leaderboardRoute), text: 'View full leaderboard'.tr());

  Widget view(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        leaderboardTitleAndSubAndCub(context),
        const SizedBox(height: 20),
        rankBox(context),
        const SizedBox(height: 20),
        leadboardButton(context)
      ]);

  @override
  Widget build(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: Style.border24,
          boxShadow: const [
            BoxShadow(color: AppColors.gray400, blurRadius: 0.4, offset: Offset(0, 1))
          ]),
      child: view(context));
}
