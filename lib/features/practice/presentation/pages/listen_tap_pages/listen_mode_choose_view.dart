import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/listen_tap_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/cards/listen_mode_card.dart';

class ListenModeChooseView extends StatelessWidget {
  final Function(ListenTapMode value) selectMode;
  const ListenModeChooseView({super.key, required this.selectMode});

  Widget modeSelection(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        Text('Choose how to train', style: Style.bodyw6(context)),
        const SizedBox(height: 12),
        ListenModeCard(
            selectMode: () => selectMode(ListenTapMode.words),
            title: 'Single words',
            subtitle: 'Practice pronunciation nuance'),
        const SizedBox(height: 12),
        ListenModeCard(
            selectMode: () => selectMode(ListenTapMode.sentences),
            title: 'Short sentences',
            subtitle: 'Improve your comprehension speed'),
      ]);
  @override
  Widget build(BuildContext context) => modeSelection(context);
}
