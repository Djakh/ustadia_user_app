import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';

class PracticeFlashcardSprintResultStats {
  final int known;
  final int learning;
  final int total;

  const PracticeFlashcardSprintResultStats(
      {required this.known, required this.learning, required this.total});
}

class PracticeFlashcardSprintResultView extends StatelessWidget {
  final PracticeFlashcardSprintResultStats? stats;

  const PracticeFlashcardSprintResultView({
    super.key,
    this.stats,
  });

  int get total => stats?.total ?? 0;
  int get known => stats?.known ?? 0;
  int get learning => stats?.learning ?? 0;

  void goBack(BuildContext context) => context.pop(true);

  Widget emoji() => Image.asset(AppImages.clap, width: 160, height: 160);

  Widget statBox(BuildContext context, String label, int value) => Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: Style.border20, boxShadow: [
        BoxShadow(
            color: Colors.black.withValues(alpha: 0.05), blurRadius: 12, offset: const Offset(0, 6))
      ]),
      child: Column(children: [
        Text('$value', style: Style.body3w7(context)),
        Text(label, style: Style.bodyw5(context, color: TextColorRole.greyColor))
      ]));

  Widget statsRow(BuildContext context) => Row(children: [
        Expanded(child: statBox(context, 'Known', known)),
        const SizedBox(width: 8),
        Expanded(child: statBox(context, 'Learning', learning)),
      ]);

  Widget view(BuildContext context) => PrimaryBackground(
      title: 'Flashcard sprint',
      isHeader: false,
      child: Column(children: [
        const Spacer(),
        emoji(),
        const SizedBox(height: 12),
        Text('Nice job', style: Style.body3w7(context)),
        const SizedBox(height: 6),
        Text('You reviewed $total words',
            style: Style.bodyw4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 24),
        statsRow(context),
        const Spacer(),
        Button.primary(onTap: () => goBack(context), text: 'Back to topic')
      ]));

  @override
  Widget build(BuildContext context) => view(context);
}
