import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';

class PrimaryDivider extends StatelessWidget {
  const PrimaryDivider({super.key});
  Widget get view => const Divider(height: 0, thickness: 0.3, color: AppColors.gray300);
  @override
  Widget build(BuildContext context) => view;
}
