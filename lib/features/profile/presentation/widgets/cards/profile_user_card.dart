import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cached_images/avatars/user_avatar.dart';

class ProfileUserCard extends StatelessWidget {
  const ProfileUserCard({super.key});

  Row xpWidget(BuildContext context) => Row(children: [
        Image.asset(AppImages.xpLightningOrange),
        const SizedBox(width: 2),
        Text('160 XP', style: Style.smallw6(context).copyWith(color: AppColors.orange033)),
        const SizedBox(width: 8),
        Text('Keep motivated.', style: Style.smallw6(context, color: TextColorRole.greyColor))
      ]);

  Column userInfo(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Sultanbek', style: Style.body3w7(context)),
        const SizedBox(height: 4),
        xpWidget(context)
      ]);

  Widget view(BuildContext context) => Row(children: [
        const UserAvatar(
          radius: 30,
          imageUrl:
              "https://plus.unsplash.com/premium_photo-1689565611422-b2156cc65e47?fm=jpg&q=60&w=3000&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxzZWFyY2h8OXx8bWFuJTIwYXZhdGFyfGVufDB8fDB8fHww",
        ),
        const SizedBox(width: 12),
        userInfo(context)
      ]);

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: context.cs.surface,
          borderRadius: Style.border20,
          boxShadow: const [
            BoxShadow(color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))
          ]),
      child: view(context));
}
