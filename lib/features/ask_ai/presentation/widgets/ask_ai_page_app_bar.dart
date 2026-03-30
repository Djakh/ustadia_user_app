import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class AskAiPageAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final bool hasTimeLimit;
  final String timerText;
  final VoidCallback onBack;

  const AskAiPageAppBar(
      {super.key,
      required this.title,
      required this.hasTimeLimit,
      required this.timerText,
      required this.onBack});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  Widget timerChip(BuildContext context) => Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
          child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12), borderRadius: Style.border12),
              child: Text(timerText,
                  style: Style.small2w5(context, color: TextColorRole.whiteColor)))));

  @override
  Widget build(BuildContext context) => AppBar(
      backgroundColor: AppColors.secondary,
      elevation: 0,
      leading:
          IconButton(onPressed: onBack, icon: const Icon(Icons.arrow_back, color: AppColors.white)),
      title: Text(title, style: Style.body2w6(context, color: TextColorRole.whiteColor)),
      actions: hasTimeLimit ? [timerChip(context)] : null);
}
