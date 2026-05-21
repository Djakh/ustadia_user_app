import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';

class SectionNavigationCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isAvailable;
  final double? height;
  final double? width;
  const SectionNavigationCircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    required this.isAvailable,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: isAvailable ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
              width: width ?? 68,
              height: height ?? 36,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: isAvailable ? AppColors.white : AppColors.gray100,
                  border: Border.all(color: isAvailable ? AppColors.gray200 : AppColors.gray100)),
              child: Center(
                  child: Icon(icon,
                      size: 26, color: isAvailable ? AppColors.gray700 : AppColors.gray400)))));
}
