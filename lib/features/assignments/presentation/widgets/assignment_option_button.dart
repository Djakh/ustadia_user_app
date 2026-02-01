import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class AssignmentOptionButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color accentColor;

  const AssignmentOptionButton(
      {super.key, required this.label, required this.onTap, required this.accentColor});

  @override
  Widget build(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: Style.border20,
      child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: Style.border20,
              border: Border.all(color: accentColor.withValues(alpha: 0.18)),
              boxShadow: const [
                BoxShadow(color: AppColors.shadow, blurRadius: 6, offset: Offset(0, 2))
              ]),
          child: Text(label, textAlign: TextAlign.center, style: Style.bodyw6(context))));
}
