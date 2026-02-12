import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/avatars/user_avatar.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/widgets/cards/dashboard_strak_card.dart';
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

  @override
  void initState() {
    super.initState();
    if (userBloc.state.profile == null && userBloc.state.status != Status.loading) {
      userBloc.add(const UserProfileRequested());
    }
  }

  /// --- Widgets ---
  String fullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://backend.ustadia.findecor.io$url';
  }

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

  Column profileInfoTexts(String name) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Welcome back,'.tr(), style: Style.small2w5(context, color: TextColorRole.greyColor)),
        Text(name, style: Style.body3w7(context))
      ]);

  Widget profileHeader(UserState state) {
    final profile = state.profile;
    final name = profile == null ? 'User' : '${profile.firstName} ${profile.lastName}'.trim();
    final imageUrl = fullImageUrl(profile?.profilePictureUrl);
    return Row(children: [
      userAvatar(imageUrl),
      const SizedBox(width: 12),
      profileInfoTexts(name),
      const Spacer(),
      firePoint()
    ]);
  }

  Widget view(UserState state) => Column(
        children: [
          profileHeader(state),
          // const SizedBox(height: 24),
          // const DashboardCalendar(),
          const SizedBox(height: 24),
          const TodayPlanCard(),
          const SizedBox(height: 16),
          const DashboardQuickGridList(),
          const SizedBox(height: 18),
          const DashboardStrakCard(),
          const SizedBox(height: 80)
        ],
      );

  @override
  Widget build(BuildContext context) => BlocBuilder<UserBloc, UserState>(
      bloc: userBloc,
      builder: (context, state) => PrimaryBackground(
          isScrollable: true, backgroundColor: context.cs.surface, child: view(state)));
}
