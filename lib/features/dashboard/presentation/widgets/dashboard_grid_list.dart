import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/widgets/cards/dashboard_grid_card.dart';
import 'package:ustadia_user_app/router.dart';
import 'package:easy_localization/easy_localization.dart';

class DashboardQuickGridList extends StatelessWidget {
  final GlobalKey? mockExamKey;
  final GlobalKey? reelsKey;
  final GlobalKey? assignmentsKey;
  final GlobalKey? leaderboardKey;

  const DashboardQuickGridList(
      {super.key, this.mockExamKey, this.reelsKey, this.assignmentsKey, this.leaderboardKey});

  // exact design sizes
  static const double cardWidth = 174;
  static const double shortHeight = 118;
  static const double tallHeight = 140;

  /// --- Methods ---
  void goToMockExam(BuildContext context) => context.push(mockExamRoute);
  void goToAssignments(BuildContext context) => context.push(assignmentsRoute);
  void goToReels(BuildContext context) => context.push(reelsRoute);

  void goToLeadboard(BuildContext context) => context.push(leaderboardRoute);

  bool assignmentsEnabled(UserProfileModel? profile) {
    final teacherId = profile?.currentTeacher?.id;
    return teacherId != null && teacherId.isNotEmpty;
  }

  void onAssignmentsTap(BuildContext context, UserProfileModel? profile) {
    if (assignmentsEnabled(profile)) {
      goToAssignments(context);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('To access assignments, please choose a teacher'.tr())));
  }

  /// --- Widgets ---

  Widget lessonAndChat(BuildContext context) => Column(children: [
        DashboardGridCard(
            key: mockExamKey,
            title: 'Mock exam'.tr(),
            subtitle: 'IELTS mock tests'.tr(),
            cardColor: AppColors.orangeBE,
            height: 118,
            backImage: AppImages.lessonCardBack,
            onTap: () => goToMockExam(context)),
        const SizedBox(height: 12),
        DashboardGridCard(
            key: reelsKey,
            title: 'Reels'.tr(),
            subtitle: 'Watch lesson clips'.tr(),
            cardColor: AppColors.greenE0,
            height: 140,
            backImage: AppImages.chatCardBack,
            onTap: () => goToReels(context))
      ]);

  Widget chatAndLideBoard(BuildContext context, UserProfileModel? profile) => Column(children: [
        DashboardGridCard(
            key: assignmentsKey,
            title: 'Assignments'.tr(),
            subtitle: 'Consolidate the acquired knowledge'.tr(),
            cardColor: AppColors.purpleFF,
            height: 140,
            backImage: AppImages.practiceCardBack,
            onTap: () => onAssignmentsTap(context, profile),
            isEnabled: assignmentsEnabled(profile)),
        const SizedBox(height: 12),
        DashboardGridCard(
            key: leaderboardKey,
            title: 'Leaderboard'.tr(),
            subtitle: 'Top 10 this week'.tr(),
            cardColor: AppColors.blueFB,
            height: 118,
            backImage: AppImages.leaderboardCardBack,
            onTap: () => goToLeadboard(context))
      ]);

  @override
  Widget build(BuildContext context) => BlocBuilder<UserBloc, UserState>(builder: (context, state) {
        return Row(children: [
          Expanded(child: lessonAndChat(context)),
          const SizedBox(width: 10),
          Expanded(child: chatAndLideBoard(context, state.profile))
        ]);
      });
}
