import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';

class AskAiControlIconButton extends StatelessWidget {
  final IconData iconData;
  final VoidCallback? onTap;
  final String? tooltipText;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  const AskAiControlIconButton(
      {super.key,
      required this.iconData,
      required this.onTap,
      this.tooltipText,
      this.backgroundColor = AppColors.gray700,
      this.iconColor = AppColors.white,
      this.size = 52});

  Widget buttonView() => AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: onTap == null ? 0.55 : 1,
      child: Material(
          color: AppColors.transparent,
          child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(size / 2),
              child: Ink(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(color: backgroundColor, shape: BoxShape.circle),
                  child: Icon(iconData, color: iconColor, size: size * 0.46)))));

  @override
  Widget build(BuildContext context) {
    final child = buttonView();
    if (tooltipText == null || tooltipText!.isEmpty) return child;
    return Tooltip(message: tooltipText!, child: child);
  }
}
