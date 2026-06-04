import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';

class AskAiControlIconButton extends StatefulWidget {
  final IconData iconData;
  final VoidCallback? onTap;
  final String? tooltipText;
  final Color backgroundColor;
  final Color iconColor;
  final double size;

  const AskAiControlIconButton(
      {super.key,
      required this.iconData,
      required this.onTap,
      this.tooltipText,
      this.backgroundColor = AppColors.gray700,
      this.iconColor = AppColors.white,
      this.size = 52});

  @override
  State<AskAiControlIconButton> createState() => AskAiControlIconButtonState();
}

class AskAiControlIconButtonState extends State<AskAiControlIconButton> {
  bool isPressed = false;

  void setPressed(bool value) {
    if (widget.onTap == null || isPressed == value) return;
    setState(() => isPressed = value);
  }

  Widget buttonView() => AnimatedOpacity(
      duration: const Duration(milliseconds: 180),
      opacity: widget.onTap == null ? 0.55 : 1,
      child: AnimatedScale(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOutCubic,
          scale: isPressed ? 0.94 : 1,
          child: GestureDetector(
              onTapDown: (_) => setPressed(true),
              onTapCancel: () => setPressed(false),
              onTapUp: (_) => setPressed(false),
              child: Material(
                  color: AppColors.transparent,
                  child: InkWell(
                      onTap: widget.onTap,
                      borderRadius: BorderRadius.circular(widget.size / 2),
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 260),
                          curve: Curves.easeOutCubic,
                          width: widget.size,
                          height: widget.size,
                          decoration: BoxDecoration(
                              color: widget.backgroundColor,
                              shape: BoxShape.circle,
                              border: Border.all(color: AppColors.white.withValues(alpha: 0.08)),
                              boxShadow: [
                                BoxShadow(
                                    color: widget.backgroundColor.withValues(alpha: 0.24),
                                    blurRadius: 18,
                                    spreadRadius: 1.2,
                                    offset: const Offset(0, 8))
                              ]),
                          child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              switchInCurve: Curves.easeOutBack,
                              switchOutCurve: Curves.easeInCubic,
                              transitionBuilder: (child, animation) => RotationTransition(
                                  turns: Tween<double>(begin: -0.12, end: 0).animate(animation),
                                  child: ScaleTransition(scale: animation, child: child)),
                              child: Icon(widget.iconData,
                                  key: ValueKey(widget.iconData),
                                  color: widget.iconColor,
                                  size: widget.size * 0.46))))))));

  @override
  Widget build(BuildContext context) {
    final child = buttonView();
    if (widget.tooltipText == null || widget.tooltipText!.isEmpty) return child;
    return Tooltip(message: widget.tooltipText!, child: child);
  }
}
