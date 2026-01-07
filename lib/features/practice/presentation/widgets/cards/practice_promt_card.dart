import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/boxes/primary_box.dart';

class PracticePromtCard extends StatelessWidget {
  final String prompt;
  final Function(String prompt) selectPrompt;
  const PracticePromtCard({super.key, required this.prompt, required this.selectPrompt});

  /// --- Widgets ---

  BoxDecoration boxDecoration() =>
      BoxDecoration(color: AppColors.white, borderRadius: Style.border20, boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
      ]);

  Widget view(BuildContext context) => PrimaryBox(
      onTap: () => selectPrompt(prompt),
      width: double.infinity,
      boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, 4))
      ],
      child: Text(prompt, style: Style.bodyw5(context)));

  @override
  Widget build(BuildContext context) => view(context);
}
