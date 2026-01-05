import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/audio_card.dart';

class LearnListeningAudioView extends StatelessWidget {
  final Function() changeStage;
  const LearnListeningAudioView({super.key, required this.changeStage});

  /// --- Widgets ---

  Widget get view => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Spacer(),
        const AudioCard(),
        const Spacer(),
        Button.primary(onTap: changeStage, text: 'Continue')
      ]);

  @override
  Widget build(BuildContext context) => view;
}
