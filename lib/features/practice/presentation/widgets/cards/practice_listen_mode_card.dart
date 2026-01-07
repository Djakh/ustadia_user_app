import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class PracticeListenModeCard extends StatelessWidget {
  final Function() selectMode;
  final String title;
  final String subtitle;

  const PracticeListenModeCard({
    super.key,
    required this.selectMode,
    required this.title,
    required this.subtitle,
  });

  BoxDecoration boxDecoration(BuildContext context) =>
      BoxDecoration(color: context.cs.surface, borderRadius: Style.border20, boxShadow: [
        BoxShadow(
            color: context.cs.surface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4))
      ]);

  Widget view(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: Style.body2w5(context)),
        const SizedBox(height: 4),
        Text(subtitle, style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  @override
  Widget build(BuildContext context) => PrimaryBox(
      onTap: selectMode,
      width: double.infinity,
      boxShadow: [
        BoxShadow(
            color: context.cs.surface.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4))
      ],
      child: view(context));
}
