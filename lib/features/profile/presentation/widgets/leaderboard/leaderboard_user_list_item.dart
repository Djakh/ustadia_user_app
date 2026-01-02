import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/profile/data/models/leaderboard_user_model.dart';

class LeaderboardUserListItem extends StatelessWidget {
  final LeaderboardUserModel user;

  const LeaderboardUserListItem({super.key, required this.user});

  TextStyle _rankStyle(BuildContext context) => user.isCurrentUser
      ? Style.bodyw5(context, color: TextColorRole.whiteColor)
      : Style.bodyw5(context, color: TextColorRole.greyColor);

  TextStyle _nameStyle(BuildContext context) => user.isCurrentUser
      ? Style.bodyw5(context, color: TextColorRole.whiteColor)
      : Style.bodyw5(context);

  TextStyle _xpStyle(BuildContext context) => Style.small3w5(context,
      color: user.isCurrentUser ? TextColorRole.whiteColor : TextColorRole.primaryColor);

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: user.isCurrentUser ? AppColors.primary : context.cs.surface,
          borderRadius: Style.border16,
        ),
        child: Row(children: [
          Text('#${user.rank}', style: _rankStyle(context)),
          const SizedBox(width: 12),
          Expanded(child: Text(user.name, style: _nameStyle(context))),
          Text('${user.xp} XP', style: _xpStyle(context)),
        ]),
      );
}
