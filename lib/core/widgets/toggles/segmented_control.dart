import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class SegmentedControl extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const SegmentedControl(
      {super.key, required this.labels, required this.selectedIndex, required this.onChanged});

  /// --- Getters ---
  bool isSelected(int index) => index == selectedIndex;

  /// --- Widgets ---

  Widget title(String label, bool isSelected) => Builder(
      builder: (context) => Center(
          child: Text(label,
              style: Style.small2w5(context)
                  .copyWith(color: isSelected ? context.cs.onSurface : AppColors.gray8D))));

  Widget _segment(String label, int index) => Expanded(
      child: GestureDetector(
          onTap: () => onChanged(index),
          child: Container(
              height: 38,
              decoration: BoxDecoration(
                  color: isSelected(index) ? AppColors.surface : AppColors.transparent,
                  borderRadius: Style.border12,
                  boxShadow: isSelected(index)
                      ? [
                          const BoxShadow(
                              color: Color(0x0F000000), blurRadius: 10, offset: Offset(0, 4))
                        ]
                      : null),
              child: title(label, isSelected(index)))));

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(color: AppColors.grayEE, borderRadius: Style.border16),
        child: Row(
          children: List.generate(labels.length, (index) => _segment(labels[index], index)),
        ),
      );
}
