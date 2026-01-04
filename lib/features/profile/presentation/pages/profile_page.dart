import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_badge_model.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_stats_model.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/cards/badge_item_card.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/cards/leaderboard_card.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/cards/profile_stats_card.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/cards/profile_user_card.dart';
import 'package:ustadia_user_app/router.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  /// --- Data ---

  List<ProfileStatsModel> get stats => const [
        ProfileStatsModel(
            icon: AppImages.profileLevelCardIcon, title: 'Current level', value: 'Advanced'),
        ProfileStatsModel(icon: AppImages.profileStreakCardIcon, title: 'Streak', value: '1 days'),
        ProfileStatsModel(
            icon: AppImages.profileWordsCardIcon, title: 'Words learned', value: '42'),
        ProfileStatsModel(icon: AppImages.profileTimeCardIcon, title: 'Time', value: '125 minutes'),
      ];

  List<ProfileBadgeModel> get badges => [
        ProfileBadgeModel(asset: AppImages.profileFirstLessonIcon, label: 'First lesson'),
        ProfileBadgeModel(asset: AppImages.profileDaysStreakIcon, label: '7 days streak'),
        ProfileBadgeModel(asset: AppImages.profile50WordsIcon, label: '50 words'),
        ProfileBadgeModel(asset: AppImages.profileEarlyBirdIcon, label: 'Early bird')
      ];

  /// --- Methods ---

  /// --- Widgets ---
  Widget headerIcon(IconData icon, AlignmentGeometry alignment, Function() onPressed) => Align(
      alignment: alignment, child: IconButton(onPressed: onPressed, icon: Icon(icon, size: 22)));

  Widget header(BuildContext context) => IntrinsicHeight(
          child: Stack(alignment: Alignment.center, children: [
        headerIcon(
            Icons.notifications, Alignment.centerLeft, () => context.push(notificationsRoute)),
        Text('Profile', style: Style.body2w6(context)),
        headerIcon(Icons.settings, Alignment.centerRight, () => context.push(settingsRoute))
      ]));

  Widget statsGrid(BuildContext context) => GridView.builder(
      itemCount: stats.length,
      padding: EdgeInsets.zero,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 1.34, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemBuilder: (_, i) => ProfileStatCard(profileStatsModel: stats[i]));

  Widget get badgesItemList => SizedBox(
        height: 94,
        child: ListView.separated(
            itemCount: badges.length,
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (_, index) => BadgeItemCard(profileBadgeModel: badges[index])),
      );

  Widget view(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 12),
        const ProfileUserCard(),
        const SizedBox(height: 24),
        statsGrid(context),
        const SizedBox(height: 24),
        Text('Badges', style: Style.body2w7(context)),
        const SizedBox(height: 12),
        badgesItemList,
        const SizedBox(height: 24),
        const LeaderBoardCard(),
        const SizedBox(height: 74),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PrimaryBackground(isScrollable: true, header: header(context), child: view(context)));
}
