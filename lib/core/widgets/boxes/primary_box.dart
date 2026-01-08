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
  final BoxShape shape;
  final VoidCallback? onTap;

  const PrimaryBox({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.isWithBorder = true,
    this.border,
    this.isTappable = true,
    this.onTap,
    this.backgroundColor,
    this.boxShadow,
    this.width,
    this.shape = BoxShape.rectangle,
  });

  bool get isCircle => shape == BoxShape.circle;

  ShapeBorder get tapShape => isCircle
      ? const CircleBorder()
      : RoundedRectangleBorder(borderRadius: borderRadius ?? Style.border20);

  BorderRadius get radius => borderRadius ?? Style.border20;

  BoxDecoration decoration(BuildContext context) => BoxDecoration(
        shape: shape,
        color: backgroundColor ?? context.cs.surface,
        borderRadius: isCircle ? null : radius,
        border: border ?? (isWithBorder ? Border.all(color: AppColors.grayF4, width: 1) : null),
        boxShadow: boxShadow,
      );

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        shape: tapShape,
        clipBehavior: Clip.antiAlias, 
        child: InkWell(
          onTap: isTappable ? onTap : null,
          customBorder: tapShape, 
          child: Ink(
            width: width,
            padding: padding ?? const EdgeInsets.all(16),
            decoration: decoration(context),
            child: child,
          ),
        ),
      );
}
