import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class AssignmentUploadCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;

  const AssignmentUploadCard(
      {super.key,
      required this.icon,
      required this.label,
      required this.backgroundColor,
      required this.iconColor});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: Style.border32,
          border: Border.all(color: AppColors.gray100)),
      child: Column(children: [
        Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(color: AppColors.white, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor)),
        const SizedBox(height: 10),
        Text(label, style: Style.small2w5(context))
      ]));
}
