import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/activity_indicator.dart';

enum ButtonType { primary, border, text }

class Button extends StatelessWidget {
  final ButtonType type;
  final VoidCallback onTap;
  final Widget? child;
  final String? text;
  final TextStyle? textStyle;
  final Color? color;

  final Color? borderColor;
  final Color? textColor;
  final int? height;
  final EdgeInsets? margin;
  final double? borderWidth;
  final bool isLoading;
  final bool isAvialable;

  const Button.primary({
    super.key,
    required this.onTap,
    this.child,
    this.text,
    this.textStyle,
    this.textColor,
    this.height,
    this.color,
    this.borderColor,
    this.margin,
    this.isLoading = false,
    this.isAvialable = true,
    this.borderWidth,
  }) : type = ButtonType.primary;

  const Button.border({
    super.key,
    required this.onTap,
    this.child,
    this.text,
    this.textStyle,
    this.textColor,
    this.height,
    this.color,
    this.borderColor,
    this.margin,
    this.isLoading = false,
    this.isAvialable = true,
    this.borderWidth,
  }) : type = ButtonType.border;

  const Button.text({
    super.key,
    required this.onTap,
    this.child,
    this.text,
    this.textStyle,
    this.textColor,
    this.height,
    this.color,
    this.borderColor,
    this.margin,
    this.isLoading = false,
    this.isAvialable = true,
    this.borderWidth,
  }) : type = ButtonType.text;

  /// --- Widgets ---

  Widget content(BuildContext context) {
    final defaultColor =
        textColor ?? (type == ButtonType.primary ? context.cs.onPrimary : context.cs.onSurface);

    return child ??
        Text(
          text ?? '',
          style: textStyle ?? Style.bodyw5(context).copyWith(color: defaultColor),
          overflow: TextOverflow.ellipsis,
        );
  }

  Widget primaryButton(BuildContext context) => ElevatedButton(
        onPressed: isAvialable && !isLoading ? onTap : null,
        style: ElevatedButton.styleFrom(
          minimumSize: Size(double.infinity, (height ?? 52).toDouble()),
          shape: RoundedRectangleBorder(borderRadius: Style.border32),
          backgroundColor: isAvialable ? (color ?? context.cs.primary) : context.cs.tertiary,
          foregroundColor: context.cs.onPrimary,
          elevation: 0,
        ),
        child: isLoading ? const ActivityIndicator() : content(context),
      );

  Widget borderButton(BuildContext context) => OutlinedButton(
        onPressed: isAvialable && !isLoading ? onTap : null,
        style: OutlinedButton.styleFrom(
          minimumSize: Size(double.infinity, (height ?? 52).toDouble()),
          shape: RoundedRectangleBorder(borderRadius: Style.border32),
          side: BorderSide(
            color: borderColor ?? context.cs.surface,
            width: borderWidth ?? 1,
          ),
          backgroundColor: isAvialable ? (color ?? AppColors.white) : AppColors.gray8D,
          foregroundColor: textColor ?? context.cs.primary,
        ),
        child: isLoading ? const ActivityIndicator() : content(context),
      );

  Widget textOnlyButton(BuildContext context) => TextButton(
        onPressed: isAvialable && !isLoading ? onTap : null,
        style: TextButton.styleFrom(
          minimumSize: Size(double.infinity, (height ?? 52).toDouble()),
          shape: RoundedRectangleBorder(borderRadius: Style.border32),
          foregroundColor: textColor ?? context.cs.primary,
          backgroundColor: color, // usually null/transparent
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading ? const ActivityIndicator() : content(context),
      );

  @override
  Widget build(BuildContext context) => Padding(
        padding: margin ?? EdgeInsets.zero,
        child: switch (type) {
          ButtonType.primary => primaryButton(context),
          ButtonType.border => borderButton(context),
          ButtonType.text => textOnlyButton(context),
        },
      );
}
