import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/size_config.dart';

class LearnListeningQuizCard extends StatelessWidget {
  final String questionText;
  const LearnListeningQuizCard({super.key, required this.questionText});

  Widget view(BuildContext context) => Container(
      height: SizeConfig.screenHeight / 2.2,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border20),
      child: Center(child: Text(questionText, style: Style.body2w7(context))));

  @override
  Widget build(BuildContext context) => view(context);
}
