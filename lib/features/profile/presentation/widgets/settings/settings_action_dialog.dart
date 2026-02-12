import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';

class SettingsActionDialog extends StatelessWidget {
  final String iconAsset;
  final String title;
  final String subtitle;
  final String actionText;
  final VoidCallback onConfirm;

  const SettingsActionDialog({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.subtitle,
    required this.actionText,
    required this.onConfirm,
  });

  /// --- Methods ---

  void cancel(BuildContext context) => context.pop();

  /// --- Widgets ---

  Button confirmButton(BuildContext context) => Button.primary(
      onTap: onConfirm, text: actionText, color: AppColors.error, textColor: context.cs.onPrimary);

  Column view(BuildContext context) => Column(mainAxisSize: MainAxisSize.min, children: [
        SvgPicture.asset(iconAsset),
        const SizedBox(height: 16),
        Text(title, style: Style.body2w7(context)),
        const SizedBox(height: 8),
        Text(subtitle, style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 24),
        confirmButton(context),
        const SizedBox(height: 12),
        Button.border(onTap: () => cancel(context), text: 'Cancel'.tr())
      ]);

  @override
  Widget build(BuildContext context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 32),
      shape: RoundedRectangleBorder(borderRadius: Style.border24),
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), child: view(context)));
}
