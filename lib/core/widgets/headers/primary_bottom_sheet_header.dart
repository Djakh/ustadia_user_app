import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class PrimaryBottomSheetHeader extends StatelessWidget {
  final String title;
  const PrimaryBottomSheetHeader({super.key, required this.title});

  Container lineBox(BuildContext context) => Container(
      width: 48,
      height: 4,
      decoration: BoxDecoration(
          color: context.cs.onSurface.withValues(alpha: 0.2), borderRadius: Style.border4));

  Widget view(BuildContext context) => Column(children: [
        lineBox(context),
        const SizedBox(height: 12),
        Text(title, style: Style.body2w6(context)),
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
