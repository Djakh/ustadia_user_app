import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/practice/data/models/flashcard_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/cards/flashcard_view.dart';

class FlashcardSprintPage extends StatefulWidget {
  const FlashcardSprintPage({super.key});

  @override
  State<FlashcardSprintPage> createState() => _FlashcardSprintPageState();
}

class _FlashcardSprintPageState extends State<FlashcardSprintPage> {
  int index = 0;
  bool showMeaning = false;

  List<FlashcardModel> get cards => const [
        FlashcardModel(
            word: 'Resilient', meaning: 'Able to recover quickly from difficult conditions.'),
        FlashcardModel(word: 'Eloquent', meaning: 'Speaking fluently, vividly, and persuasively.'),
        FlashcardModel(word: 'Tenacious', meaning: 'Keeping a firm hold; not giving up easily.'),
        FlashcardModel(
            word: 'Meticulous',
            meaning: 'Showing great attention to detail; very careful and precise.'),
        FlashcardModel(word: 'Ingenuity', meaning: 'Cleverness, originality, and inventiveness.')
      ];

  FlashcardModel get current => cards[index];
  String get progress => 'Card ${index + 1}/${cards.length}';

  void toggleFace() => setState(() => showMeaning = !showMeaning);

  void onKnowIt() => _nextCard(resetFace: true);

  void onStudyAgain() => setState(() {
        showMeaning = false;
        index = 0;
      });

  void _nextCard({required bool resetFace}) {
    setState(() {
      if (resetFace) showMeaning = false;
      index = (index + 1) % cards.length;
    });
  }

  /// --- Widgets ---

  Widget get header => Column(children: [
        Text('Flashcard sprint', style: Style.body3w7(context)),
        const SizedBox(height: 4),
        Text(progress, style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget get card =>
      FlashcardView(flashcard: current, showMeaning: showMeaning, onToggle: toggleFace);

  Widget controls(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(child: Button.border(onTap: onKnowIt, text: "I know it")),
        const SizedBox(width: 12),
        Expanded(child: Button.border(onTap: onStudyAgain, text: "Study again")),
      ]));

  Widget get view => PrimaryBackground(
      header: header,
      child: Column(children: [
        const SizedBox(height: 12),
        card,
        const SizedBox(height: 20),
        controls(context)
      ]));

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: context.cs.surface, body: view);
}
