import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_grid.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_badge_model.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_statistics_model.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_stats_model.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/bottom_sheets/level_picker_sheet.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/cards/badge_item_card.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/cards/leaderboard_card.dart';
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
    statisticsStore.refreshIfNeeded();
  }

  /// --- Data ---

  List<ProfileStatsModel> stats(
      ProfileStatisticsModel? statistics, String languageCode, UserProfileModel? profile) {
    final canUpdateLevel = canChangeLevel(profile);
    final level = currentLevelText(statistics, languageCode, profile);
    final totalCompleted = statistics?.totalCompletedTasks.toString() ?? '-';
    final totalVocabulary = statistics?.totalVocabulary.toString() ?? '-';
    final breakdown = statistics?.breakdown;
    final breakdownValue = breakdown == null
        ? '-'
        : 'P-${breakdown.practiceCompleted}  A-${breakdown.assignmentCompleted}  L-${breakdown.lessonCompleted}';

    return [
      ProfileStatsModel(
          icon: AppImages.profileLevelCardIcon,
          title: 'Current level'.tr(),
          value: level,
          subtitle: canUpdateLevel ? 'Change level'.tr() : null),
      ProfileStatsModel(
          icon: AppImages.profileStreakCardIcon,
          title: 'Completed tasks'.tr(),
          value: totalCompleted),
      ProfileStatsModel(
          icon: AppImages.profileWordsCardIcon, title: 'Vocabulary'.tr(), value: totalVocabulary),
      ProfileStatsModel(
          icon: AppImages.profileTimeCardIcon, title: 'Breakdown'.tr(), value: breakdownValue)
    ];
  }

  List<ProfileBadgeModel> get badges => [
        ProfileBadgeModel(asset: AppImages.profileFirstLessonIcon, label: 'First lesson'.tr()),
        ProfileBadgeModel(asset: AppImages.profileDaysStreakIcon, label: '7 days streak'.tr()),
        ProfileBadgeModel(asset: AppImages.profile50WordsIcon, label: '50 words'.tr()),
        ProfileBadgeModel(asset: AppImages.profileEarlyBirdIcon, label: 'Early bird'.tr())
      ];

  /// --- Methods ---

  /// --- Widgets ---

  bool canChangeLevel(UserProfileModel? profile) {
    final currentTeacher = profile?.currentTeacher;
    if (currentTeacher == null) return true;
    return isBlankTeacherId(currentTeacher.id) && isBlankTeacherId(currentTeacher.teacherId);
  }

  bool isBlankTeacherId(String? value) {
    final normalized = value?.trim().toLowerCase();
    return normalized == null || normalized.isEmpty || normalized == 'null';
  }

  String currentLevelText(
      ProfileStatisticsModel? statistics, String languageCode, UserProfileModel? profile) {
    if (!canChangeLevel(profile)) {
      final teacherLevel = profile?.currentTeacher?.level?.nameForLanguage(languageCode).trim();
      if (teacherLevel != null && teacherLevel.isNotEmpty) return teacherLevel;
    }

    final levelName = statistics?.level.name.forLanguage(languageCode).trim();
    return levelName != null && levelName.isNotEmpty ? levelName : '-';
  }

  Future<void> showLevelPicker(UserProfileModel userModel) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LevelPickerSheet(userModel: userModel));

  void onLevelCardTap(UserProfileModel? profile) {
    if (profile != null && canChangeLevel(profile)) {
      showLevelPicker(profile);
      return;
    }
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('Level can be changed only in system lessons'.tr())));
  }

  Widget headerIcon(IconData icon, AlignmentGeometry alignment, Function() onPressed) => Align(
      alignment: alignment, child: IconButton(onPressed: onPressed, icon: Icon(icon, size: 22)));

  Widget header(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        headerIcon(
            Icons.notifications, Alignment.centerLeft, () => context.push(notificationsRoute)),
        Text('Profile'.tr(), style: Style.body2w6(context)),
        headerIcon(Icons.settings, Alignment.centerRight, () => context.push(settingsRoute))
      ]);

  Widget statsWidgetRow(ProfileStatsModel firstStatsModel, ProfileStatsModel secondStatsModel,
          {VoidCallback? onFirstTap}) =>
      Row(children: [
        ProfileStatCard(profileStatsModel: firstStatsModel, onTap: onFirstTap),
        const SizedBox(width: 12),
        ProfileStatCard(profileStatsModel: secondStatsModel)
      ]);

  Widget statsWidgetList(
      ProfileStatisticsModel? data, String languageCode, UserProfileModel? profile) {
    final items = stats(data, languageCode, profile);
    return Column(children: [
      statsWidgetRow(items[0], items[1], onFirstTap: () => onLevelCardTap(profile)),
      const SizedBox(height: 12),
      statsWidgetRow(items[2], items[3])
    ]);
  }

  Widget statsGrid(BuildContext context) => BlocBuilder<UserBloc, UserState>(
      buildWhen: (prev, next) =>
          prev.profile?.language != next.profile?.language ||
          prev.profile?.currentTeacher?.id != next.profile?.currentTeacher?.id ||
          prev.profile?.currentTeacher?.teacherId != next.profile?.currentTeacher?.teacherId ||
          prev.profile?.currentTeacher?.level?.id != next.profile?.currentTeacher?.level?.id ||
          prev.profile?.currentTeacher?.level?.fallbackName !=
              next.profile?.currentTeacher?.level?.fallbackName,
      builder: (context, userState) {
        final languageCode = userState.profile?.language ?? context.locale.languageCode;
        return ValueListenableBuilder<ProfileStatisticsModel?>(
            valueListenable: statisticsStore.statistics,
            builder: (context, data, _) => ValueListenableBuilder<bool>(
                valueListenable: statisticsStore.loading,
                builder: (context, isLoading, __) {
                  if (isLoading && data == null) {
                    return const ShimmerGrid(
                        itemCount: 4,
                        crossAxisCount: 2,
                        childAspectRatio: 1.5,
                        padding: EdgeInsets.zero,
                        borderRadius: BorderRadius.all(Radius.circular(20)));
                  }
                  return statsWidgetList(data, languageCode, userState.profile);
                }));
      });

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
        // Text('Badges'.tr(), style: Style.body2w7(context)),
        //  const SizedBox(height: 12),
        //  badgesItemList,
        //   const SizedBox(height: 24),
        const LeaderBoardCard(),
        const SizedBox(height: 74),
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PrimaryBackground(
          isScrollable: true, header: header(context), headerHorPadding: 0, child: view(context)));
}
