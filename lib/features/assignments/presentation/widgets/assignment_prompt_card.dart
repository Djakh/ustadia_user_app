import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class AssignmentPromptCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const AssignmentPromptCard({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: Style.border32,
          border: Border.all(color: AppColors.gray100),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))
          ]),
      child: Column(children: [
        Text(title, textAlign: TextAlign.center, style: Style.headlinew7(context)),
        const SizedBox(height: 8),
        Text(subtitle, style: Style.small2w4(context, color: TextColorRole.greyColor))
      ]));
}
