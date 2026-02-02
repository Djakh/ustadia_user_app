import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_badge_model.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_statistics_model.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_stats_model.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/cards/badge_item_card.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/cards/profile_stats_card.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/cards/profile_user_card.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => ProfilePageState();
}

class ProfilePageState extends State<ProfilePage> {
  final ProfileStatisticsStore statisticsStore = sl<ProfileStatisticsStore>();

  @override
  void initState() {
    super.initState();
    statisticsStore.refresh();
  }

  /// --- Data ---

  List<ProfileStatsModel> stats(ProfileStatisticsModel? statistics) {
    final level = statistics?.level.isNotEmpty == true ? statistics!.level : '-';
    final totalCompleted = statistics?.totalCompletedTasks.toString() ?? '-';
    final totalVocabulary = statistics?.totalVocabulary.toString() ?? '-';
    final breakdown = statistics?.breakdown;
    final breakdownValue = breakdown == null
        ? '-'
        : 'P-${breakdown.practiceCompleted}  A-${breakdown.assignmentCompleted}  L-${breakdown.lessonCompleted}';

    return [
      ProfileStatsModel(icon: AppImages.profileLevelCardIcon, title: 'Current level', value: level),
      ProfileStatsModel(
          icon: AppImages.profileStreakCardIcon, title: 'Completed tasks', value: totalCompleted),
      ProfileStatsModel(
          icon: AppImages.profileWordsCardIcon, title: 'Vocabulary', value: totalVocabulary),
      ProfileStatsModel(
          icon: AppImages.profileTimeCardIcon, title: 'Breakdown', value: breakdownValue)
    ];
  }

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
  Widget statsWidgetRow(ProfileStatsModel firstStatsModel, ProfileStatsModel secondStatsModel) =>
      Row(children: [
        ProfileStatCard(profileStatsModel: firstStatsModel),
        const SizedBox(width: 12),
        ProfileStatCard(profileStatsModel: secondStatsModel)
      ]);

  Widget statsWidgetList(ProfileStatisticsModel? data) => Column(children: [
        statsWidgetRow(stats(data)[0], stats(data)[1]),
        const SizedBox(height: 12),
        statsWidgetRow(stats(data)[2], stats(data)[3])
      ]);

  Widget statsGrid(BuildContext context) => ValueListenableBuilder<ProfileStatisticsModel?>(
      valueListenable: statisticsStore.statistics,
      builder: (context, data, _) => statsWidgetList(data));

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
        // Text('Badges', style: Style.body2w7(context)),
        //  const SizedBox(height: 12),
        //  badgesItemList,
        //   const SizedBox(height: 24),
        //  const LeaderBoardCard(),
        const SizedBox(height: 74),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PrimaryBackground(isScrollable: true, header: header(context), child: view(context)));
}
