import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/audio_card.dart';

class LearnListeningLesson extends StatelessWidget {
  final LearnSectionModel sectionModel;
  final Function() changeStage;
  final bool isLoading;
  const LearnListeningLesson({
    super.key,
    required this.changeStage,
    required this.sectionModel,
    required this.isLoading,
  });

  /// --- Widgets ---

  Widget get view => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Spacer(),
        AudioCard(sectionModel: sectionModel),
        const Spacer(),
        Button.primary(onTap: changeStage, text: 'Continue', isAvialable: !isLoading)
      ]);

  @override
  Widget build(BuildContext context) => view;
}
