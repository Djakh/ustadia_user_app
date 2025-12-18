import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class IntroSurveyChipData {
  final String label;
  final Color backgroundColor;
  final Color selectedBackgroundColor;
  final Color textColor;
  final Color selectedTextColor;

  const IntroSurveyChipData({
    required this.label,
    required this.backgroundColor,
    required this.selectedBackgroundColor,
    required this.textColor,
    required this.selectedTextColor,
  });
}

class IntroSurveyChip extends StatelessWidget {
  final IntroSurveyChipData data;
  final bool selected;
  final VoidCallback onTap;

  const IntroSurveyChip({
    super.key,
    required this.data,
    required this.selected,
    required this.onTap,
  });

  /// --- Methods ---

  Color get background => selected ? data.selectedBackgroundColor : data.backgroundColor;
  Color get textColor => selected ? data.selectedTextColor : data.textColor;

  /// --- Widgets ---

  Widget label(BuildContext context) =>
      Text(data.label, style: Style.small2w5(context).copyWith(color: textColor));

  Widget view(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: onTap,
          borderRadius: Style.border95,
          child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(color: background, borderRadius: Style.border95),
              child: label(context))));

  @override
  Widget build(BuildContext context) => view(context);
}
