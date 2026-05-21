import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class SectionQuizPanelActionButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool isResultState;
  final Color panelColor;
  final String label;
  final IconData icon;

  const SectionQuizPanelActionButton({
    super.key,
    required this.onTap,
    required this.isResultState,
    required this.panelColor,
    required this.label,
    this.icon = Icons.menu_book_rounded,
  });

  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                  color: isResultState ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: isResultState
                          ? AppColors.white.withValues(alpha: 0.9)
                          : context.cs.outline.withValues(alpha: 0.2))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(icon, size: 14, color: isResultState ? panelColor : context.cs.primary),
                const SizedBox(width: 6),
                Text(label.tr(),
                    style: Style.small3w5(context)
                        .copyWith(color: isResultState ? panelColor : context.cs.primary))
              ]))));
}
