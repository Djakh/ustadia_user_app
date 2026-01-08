import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class LearnSpeakingStatusBanner extends StatelessWidget {
  final bool isSuccess;

  const LearnSpeakingStatusBanner({super.key, required this.isSuccess});

  String get statusText => isSuccess ? 'Great pronunciation!' : 'Not quite. Keep trying!';

  Color bannerColor(BuildContext context) => isSuccess ? context.cs.primary : context.cs.error;

  Widget view(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: bannerColor(context), borderRadius: Style.border20),
      child: Center(
          child: Text(statusText, style: Style.bodyw6(context, color: TextColorRole.whiteColor))));

  @override
  Widget build(BuildContext context) => view(context);
}
