import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/profile/data/models/settings_language_model.dart';

class SettingsLanguageItem extends StatelessWidget {
  final SettingsLanguageModel item;

  final bool isSelected;
  final Function(String key) onTap;
  const SettingsLanguageItem(
      {super.key, required this.item, required this.isSelected, required this.onTap});

  Widget trailingIcon() => Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? AppColors.primary : AppColors.gray300,
        size: 24,
      );

  Widget view(BuildContext context) => Row(children: [
        SvgPicture.asset(item.iconAsset),
        const SizedBox(width: 12),
        Expanded(child: Text(item.title, style: Style.bodyw4(context))),
        trailingIcon(),
      ]);

  Widget inkwell(BuildContext context) => InkWell(
      onTap: () => onTap(item.key),
      borderRadius: Style.border16,
      child: Ink(padding: const EdgeInsets.all(16), child: view(context)));

  @override
  Widget build(BuildContext context) =>
      Material(color: Colors.transparent, child: inkwell(context));
}
