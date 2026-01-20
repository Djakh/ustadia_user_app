import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/audio_card.dart';

class LearnGrammarLesson extends StatelessWidget {
  final LearnSectionModel sectionModel;
  final Function() changeStage;
  final bool isLoading;
  const LearnGrammarLesson({
    super.key,
    required this.changeStage,
    required this.sectionModel,
    required this.isLoading,
  });

  /// --- Widgets ---

  Widget view(BuildContext context) => Column(children: [
        const SizedBox(height: 24),
        Text(sectionModel.content, textAlign: TextAlign.justify, style: Style.bodyw4(context)),
        const SizedBox(height: 16),
        AudioCard(sectionModel: sectionModel),
        const Spacer(),
        Button.primary(onTap: changeStage, text: 'Continue', isAvialable: !isLoading)
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
