import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/profile/data/models/settings_item_model.dart';

class SettingsListItem extends StatelessWidget {
  final SettingsItemModel item;
  final VoidCallback onTap;

  const SettingsListItem({
    super.key,
    required this.item,
    required this.onTap,
  });

  Color get iconBackground => item.isDestructive ? AppColors.redE2 : AppColors.greenE7;

  Expanded title(BuildContext context) => Expanded(
      child: Text(item.title,
          style: Style.bodyw4(context)
              .copyWith(color: item.isDestructive ? AppColors.error : context.cs.onSurface)));

  Widget arrowIcon() => SvgPicture.asset(
        AppImages.chevronRight,
        colorFilter:
            item.isDestructive ? const ColorFilter.mode(AppColors.error, BlendMode.srcIn) : null,
      );
  Widget view(BuildContext context) => Row(children: [
        SvgPicture.asset(item.iconAsset),
        const SizedBox(width: 14),
        title(context),
        arrowIcon()
      ]);

  Widget inkwell(BuildContext context) => InkWell(
      onTap: onTap,
      borderRadius: Style.border16,
      child: Ink(padding: const EdgeInsets.all(16), child: view(context)));

  @override
  Widget build(BuildContext context) =>
      Material(color: Colors.transparent, child: inkwell(context));
}
