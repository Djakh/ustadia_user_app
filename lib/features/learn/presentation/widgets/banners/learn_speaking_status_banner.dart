import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class LearnSpeakingStatusBanner extends StatelessWidget {
  const LearnSpeakingStatusBanner({super.key});

  Widget view(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: context.cs.primary, borderRadius: Style.border20),
      child: Center(
          child: Text('Your respond is accepted'.tr(),
              style: Style.bodyw6(context, color: TextColorRole.whiteColor))));

  @override
  Widget build(BuildContext context) => view(context);
}
