import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/network/api_url_resolver.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/avatars/user_avatar.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/widgets/cards/today_plan_card.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/widgets/dashboard_grid_list.dart';
import 'package:ustadia_user_app/features/profile/presentation/pages/profile_image_view_page.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final UserBloc userBloc = sl<UserBloc>();
  final GlobalKey profileHeaderKey = GlobalKey(debugLabel: 'dashboard_profile_header');
  final GlobalKey meetsKey = GlobalKey(debugLabel: 'dashboard_meets');
  final GlobalKey planKey = GlobalKey(debugLabel: 'dashboard_plan');
  final GlobalKey gridKey = GlobalKey(debugLabel: 'dashboard_grid');
  final GlobalKey mockExamKey = GlobalKey(debugLabel: 'dashboard_mock_exam');
  final GlobalKey reelsKey = GlobalKey(debugLabel: 'dashboard_reels');
  final GlobalKey assignmentsKey = GlobalKey(debugLabel: 'dashboard_assignments');
  final GlobalKey leaderboardKey = GlobalKey(debugLabel: 'dashboard_leaderboard');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (userBloc.state.profile == null && userBloc.state.status != Status.loading) {
        userBloc.add(
            UserProfileRequested(preferredLanguage: Localizations.localeOf(context).languageCode));
      }
    });
  }

  String fullImageUrl(String? url) {
    return resolveApiAssetUrl(
      url,
      baseUrl: sl<AuthRemoteDataSource>().dio.options.baseUrl,
    );
  }

  void goToMeets() => context.push(meetsRoute);

  /// --- Widgets ---
  Widget userAvatar(String? imageUrl) => GestureDetector(
      onTap: imageUrl == null || imageUrl.isEmpty
          ? null
          : () => context.push(profileImageViewRoute,
              extra: ProfileImageViewParams(imageUrl: imageUrl)),
      child:
          UserAvatar(radius: 24, imageUrl: imageUrl == null || imageUrl.isEmpty ? null : imageUrl));

  Container firePoint() => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
          color: AppColors.orange9200.withValues(alpha: 0.10), borderRadius: Style.border16),
      child: Row(children: [
        Image.asset(AppImages.firePoint),
        const SizedBox(width: 2),
        Text('+5', style: Style.small2w4(context).copyWith(color: AppColors.orange9200))
      ]));

  Widget meetsButton() => InkWell(
      key: meetsKey,
      onTap: goToMeets,
      borderRadius: Style.border16,
      child: Ink(
          padding: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
              color: AppColors.greenE7,
              borderRadius: Style.border16,
              border: Border.all(color: AppColors.greenC6)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.video_call_rounded, color: AppColors.green36, size: 20),
            const SizedBox(width: 6),
            FittedBox(
                fit: BoxFit.fill,
                child: Text('Meets'.tr(),
                    style: Style.small2w5(context).copyWith(color: AppColors.green36)))
          ])));

  Row welcomeBackAndMeetings() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Welcome back,'.tr(), style: Style.small2w5(context, color: TextColorRole.greyColor)),
        meetsButton()
      ]);

  Column profileInfoTexts(String name) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [welcomeBackAndMeetings(), Text(name, style: Style.body3w7(context))]);

  Widget profileHeader(UserState state) {
    final profile = state.profile;
    final name = profile == null ? 'User' : '${profile.firstName} ${profile.lastName}'.trim();
    final imageUrl = fullImageUrl(profile?.profilePictureUrl);
    return Row(key: profileHeaderKey, children: [
      userAvatar(imageUrl),
      const SizedBox(width: 12),
      Expanded(child: profileInfoTexts(name)),
      // firePoint()
    ]);
  }

  Widget view(UserState state) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          profileHeader(state),

          // const SizedBox(height: 24),
          // const DashboardCalendar(),
          const SizedBox(height: 16),
          KeyedSubtree(key: planKey, child: const TodayPlanCard()),
          const SizedBox(height: 16),
          KeyedSubtree(
              key: gridKey,
              child: DashboardQuickGridList(
                  mockExamKey: mockExamKey,
                  reelsKey: reelsKey,
                  assignmentsKey: assignmentsKey,
                  leaderboardKey: leaderboardKey)),
          const SizedBox(height: 18),
          //   const DashboardStrakCard(),
          const SizedBox(height: 80)
        ],
      );

  @override
  Widget build(BuildContext context) => BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, state) => GuidedTutorialPage(
          pageId: TutorialPageIds.dashboard,
          steps: TutorialPresets.dashboard(
              profileKey: profileHeaderKey,
              meetsKey: meetsKey,
              planKey: planKey,
              gridKey: gridKey,
              mockExamKey: mockExamKey,
              reelsKey: reelsKey,
              assignmentsKey: assignmentsKey,
              leaderboardKey: leaderboardKey),
          child: PrimaryBackground(
              isScrollable: true, backgroundColor: context.cs.surface, child: view(state))));
}
