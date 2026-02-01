import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/core/inherited_widgets/navigation_shell_scope.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/widgets/cards/dashboard_grid_card.dart';
import 'package:ustadia_user_app/router.dart';

class DashboardQuickGridList extends StatelessWidget {
  const DashboardQuickGridList({super.key});

  // exact design sizes
  static const double cardWidth = 174;
  static const double shortHeight = 118;
  static const double tallHeight = 140;

  /// --- Methods ---
  void goToPractice(BuildContext context) => NavigationShellScope.of(context).goBranch(2);
  void goToAssignments(BuildContext context) => context.push(assignmentsRoute);

  void goToChatWithAi(BuildContext context) => NavigationShellScope.of(context).goBranch(3);

  void goToLeadboard(BuildContext context) => context.push(leaderboardRoute);

  /// --- Widgets ---

  Widget lessonAndChat(BuildContext context) => Column(children: [
        DashboardGridCard(
            title: 'Practice',
            subtitle: 'Games & Quizzes',
            cardColor: AppColors.orangeBE,
            height: 118,
            backImage: AppImages.lessonCardBack,
            onTap: () => goToPractice(context)),
        const SizedBox(height: 12),
        DashboardGridCard(
            title: 'Chat with AI',
            subtitle: 'Voice practice',
            cardColor: AppColors.greenE0,
            height: 140,
            backImage: AppImages.chatCardBack,
            onTap: () => goToChatWithAi(context))
      ]);

  Widget chatAndLideBoard(BuildContext context) => Column(children: [
        DashboardGridCard(
            title: 'Assignments',
            subtitle: 'Consolidate the acquired knowledge',
            cardColor: AppColors.purpleFF,
            height: 140,
            backImage: AppImages.practiceCardBack,
            onTap: () => goToAssignments(context)),
        const SizedBox(height: 12),
        DashboardGridCard(
            title: 'Leaderboard',
            subtitle: 'Top 10 this week',
            cardColor: AppColors.blueFB,
            height: 118,
            backImage: AppImages.leaderboardCardBack,
            onTap: () => goToLeadboard(context))
      ]);

  @override
  Widget build(BuildContext context) => Row(children: [
        Expanded(child: lessonAndChat(context)),
        const SizedBox(width: 10),
        Expanded(child: chatAndLideBoard(context))
      ]);
}
