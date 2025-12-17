import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class PrimaryBackground extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;

  const PrimaryBackground({super.key, required this.child, this.padding});

  /// --- Methods ---

  void goBack(BuildContext context) => context.pop();

  /// --- Widget ---

  Widget backButton(BuildContext context) => Navigator.of(context).canPop()
      ? Material(
          color: Colors.transparent,
          child: InkWell(
              onTap: () =>goBack(context),
              borderRadius: BorderRadius.circular(24),
              child: Ink(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(color: context.cs.surface, shape: BoxShape.circle),
                  child: const Center(
                      child: Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.black)))))
      : const SizedBox();

  Widget view(BuildContext context) => SafeArea(
      child: Container(
          margin: const EdgeInsets.all(8),
          padding: padding ?? const EdgeInsets.all(12),
          decoration:
              BoxDecoration(color: context.cs.secondaryContainer, borderRadius: Style.border24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              backButton(context),
              Expanded(child: child),
            ],
          )));

  @override
  Widget build(BuildContext context) => view(context);
}
