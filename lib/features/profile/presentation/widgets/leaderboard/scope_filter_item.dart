import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/boxes/border_box.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class ScopeFilterItem extends StatelessWidget {
  final String title;
  final int index;
  final bool isSelected;
  final Function(int index) onTap;
  const ScopeFilterItem({
    super.key,
    required this.title,
    required this.index,
    required this.isSelected,
    required this.onTap,
  });

  Widget titleWidget(BuildContext context) => Text(title,
      style: Style.small2w5(context,
          color: isSelected ? TextColorRole.whiteColor : TextColorRole.greyColor));

  Widget view(BuildContext context) => PrimaryBox(
      onTap: () => onTap(index),
      borderRadius: Style.border95,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      backgroundColor: isSelected ? AppColors.primary : context.cs.surface,
      child: titleWidget(context));

  @override
  Widget build(BuildContext context) => view(context);
}
