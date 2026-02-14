import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_question_model.dart';

class QuestionsCard extends StatelessWidget {
  final SectionQuestionModel currentQuestion;
  const QuestionsCard({super.key, required this.currentQuestion});

  Widget view(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border20),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Text(currentQuestion.title, style: Style.body2w7(context), textAlign: TextAlign.center),
          if (currentQuestion.description != null) ...[
            const SizedBox(height: 8),
            Text(currentQuestion.description!,
                style: Style.bodyw4(context), textAlign: TextAlign.center)
          ],
          const SizedBox(height: 24),
        ],
      ));

  @override
  Widget build(BuildContext context) => view(context);
}
