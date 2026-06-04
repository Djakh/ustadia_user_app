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
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: Style.border16,
                  border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
                  boxShadow: [
                    BoxShadow(
                        color: AppColors.black.withValues(alpha: 0.14),
                        blurRadius: 14,
                        offset: const Offset(0, 6))
                  ]),
              child: Text(timerText,
                  style: Style.small2w5(context, color: TextColorRole.whiteColor)))));

  @override
  Widget build(BuildContext context) => AppBar(
      backgroundColor: AppColors.secondary.withValues(alpha: 0.96),
      elevation: 0,
      leading: Padding(
          padding: const EdgeInsets.only(left: 4),
          child: IconButton(
              onPressed: onBack,
              icon: const Icon(Icons.arrow_back_rounded, color: AppColors.white))),
      title: Text(title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Style.body2w6(context, color: TextColorRole.whiteColor)),
      actions: hasTimeLimit ? [timerChip(context)] : null);
}
