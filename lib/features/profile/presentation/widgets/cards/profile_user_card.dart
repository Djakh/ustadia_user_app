import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/avatars/user_avatar.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/features/profile/presentation/pages/profile_image_view_page.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class ProfileUserCard extends StatelessWidget {
  const ProfileUserCard({super.key});

  String fullImageUrl(String? url) {
    if (url == null || url.isEmpty) return '';
    if (url.startsWith('http')) return url;
    return 'https://backend.ustadia.findecor.io$url';
  }

  Row xpWidget(BuildContext context, String xp) => Row(children: [
        Image.asset(AppImages.xpLightningOrange),
        const SizedBox(width: 2),
        Text('{xp} XP'.tr(namedArgs: {'xp': '$xp'}),
            style: Style.smallw6(context).copyWith(color: AppColors.orange033)),
        const SizedBox(width: 8),
        Text('Keep motivated.'.tr(), style: Style.smallw6(context, color: TextColorRole.greyColor))
      ]);

  Column userInfo(BuildContext context, String name, String xp) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, style: Style.body3w7(context)),
        const SizedBox(height: 4),
        xpWidget(context, xp)
      ]);

  Widget view(BuildContext context, UserState state) {
    final profile = state.profile;
    final name = profile == null
        ? 'User'
        : '${profile.firstName} ${profile.lastName}'.trim();
    final xp = profile?.xp ?? '0';
    final imageUrl = fullImageUrl(profile?.profilePictureUrl);
    return Row(children: [
      GestureDetector(
          onTap: imageUrl.isEmpty
              ? null
              : () => context.push(profileImageViewRoute,
                  extra: ProfileImageViewParams(imageUrl: imageUrl)),
          child: UserAvatar(radius: 30, imageUrl: imageUrl.isEmpty ? null : imageUrl)),
      const SizedBox(width: 12),
      userInfo(context, name, xp)
    ]);
  }

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: Style.border20,
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))
          ]),
      child: BlocBuilder<UserBloc, UserState>(
          bloc: sl<UserBloc>(), builder: (context, state) => view(context, state)));
}
