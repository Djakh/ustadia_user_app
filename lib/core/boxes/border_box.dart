import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class PrimaryBox extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final BorderRadius? borderRadius;
  final bool isWithBorder;
  final BoxBorder? border;
  final bool isTappable;
  final Color? backgroundColor;
  final List<BoxShadow>? boxShadow;
  final double? width;
  final Function()? onTap;
  const PrimaryBox(
      {super.key,
      required this.child,
      this.padding,
      this.borderRadius,
      this.isWithBorder = true,
      this.border,
      this.isTappable = true,
      this.onTap,
      this.backgroundColor,
      this.boxShadow,  this.width});

  Widget view(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: isTappable ? onTap : null,
          borderRadius: borderRadius ?? Style.border20,
          child: Ink(
              width: width,
              padding: padding ?? const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: backgroundColor ?? context.cs.surface,
                  borderRadius: borderRadius ?? Style.border20,
                  border: isWithBorder ? Border.all(color: AppColors.grayF4, width: 1) : null,
                  boxShadow: boxShadow),
              child: child)));
  @override
  Widget build(BuildContext context) => view(context);
}
