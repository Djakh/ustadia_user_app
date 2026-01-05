import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/avatars/user_avatar.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/dashboard/widgets/cards/dashboard_strak_card.dart';
import 'package:ustadia_user_app/features/dashboard/widgets/cards/today_plan_card.dart';
import 'package:ustadia_user_app/features/dashboard/widgets/dashboard_calendar.dart';
import 'package:ustadia_user_app/features/dashboard/widgets/dashboard_grid_list.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  /// --- Widgets ---
  Widget get userAvatar => const UserAvatar(
        radius: 24,
        imageUrl:
            "https://plus.unsplash.com/premium_photo-1689565611422-b2156cc65e47?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8bWFuJTIwYXZhdGFyfGVufDB8fDB8fHww",
      );

  Container firePoint() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.orange9200.withValues(alpha: 0.10), borderRadius: Style.border16),
      child: Row(children: [
        Image.asset(AppImages.firePoint),
        const SizedBox(width: 2),
        Text('+5', style: Style.small2w4(context).copyWith(color: AppColors.orange9200))
      ]));

  Column profileInfoTexts() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back,', style: Style.small2w5(context, color: TextColorRole.greyColor)),
        Text('Jamik', style: Style.body3w7(context))
      ]);

  Widget get profileHeader => Row(children: [
        userAvatar,
        const SizedBox(width: 12),
        profileInfoTexts(),
        const Spacer(),
        firePoint()
      ]);

  Widget get view => Column(
        children: [
          profileHeader,
          const SizedBox(height: 24),
          const DashboardCalendar(),
          const SizedBox(height: 24),
          const TodayPlanCard(),
          const SizedBox(height: 16),
          const DashboardQuickGridList(),
          const SizedBox(height: 18),
          const DashboardStrakCard(),
          const SizedBox(height: 80),
        ],
      );

  @override
  Widget build(BuildContext context) =>
      PrimaryBackground(isScrollable: true, backgroundColor: context.cs.surface, child: view);
}
