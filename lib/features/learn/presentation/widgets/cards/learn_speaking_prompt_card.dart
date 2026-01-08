import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';

class LearnSpeakingPromptCard extends StatelessWidget {
  final String prompt;

  const LearnSpeakingPromptCard({super.key, required this.prompt});

  Widget view(BuildContext context) => Container(
      height: 216,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border20),
      child:
          Center(child: Text(prompt, style: Style.body3w7(context), textAlign: TextAlign.center)));

  @override
  Widget build(BuildContext context) => view(context);
}
