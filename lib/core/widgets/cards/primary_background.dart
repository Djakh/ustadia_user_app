import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class PrimaryBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  const PrimaryBackground({super.key, required this.child, this.padding});

  /// --- Widget ---

  Widget view(BuildContext context) => SafeArea(
      child: Container(
          margin: const EdgeInsets.all(8),
          padding: padding ?? const EdgeInsets.all(12),
          decoration:
              BoxDecoration(color: context.cs.secondaryContainer, borderRadius: Style.border24),
          child: child));

  @override
  Widget build(BuildContext context) => view(context);
}
