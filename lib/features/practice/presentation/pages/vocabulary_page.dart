import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/size_config.dart';

class VocabularyQuestion {
  final String category;
  final String prompt;
  final List<String> options;
  final int answerIndex;

  const VocabularyQuestion(
      {required this.category,
      required this.prompt,
      required this.options,
      required this.answerIndex});
}

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  int questionIndex = 0;
  int? selectedIndex;
  bool answered = false;

  /// --- Getters ---

  List<VocabularyQuestion> get questions => const [
        VocabularyQuestion(
            category: 'Vocabulary',
            prompt: 'Synonym for “Fast”',
            options: ['Quick', 'Slow', 'Calm'],
            answerIndex: 0),
        VocabularyQuestion(
            category: 'Vocabulary',
            prompt: 'Synonym for “Happy”',
            options: ['Sad', 'Joyful', 'Angry'],
            answerIndex: 1),
        VocabularyQuestion(
            category: 'Vocabulary',
            prompt: 'Synonym for “Smart”',
            options: ['Bright', 'Lazy', 'Dull'],
            answerIndex: 0),
      ];

  VocabularyQuestion get current => questions[questionIndex];

  double get progress => (questionIndex + 1) / questions.length;

  bool get isCorrect => selectedIndex != null && selectedIndex == current.answerIndex;

  String getNumberInVocabulary(int number) {
    switch (number) {
      case 0:
        return 'First';
      case 1:
        return 'Second';
      case 2:
        return 'Third';

      default:
        return '';
    }
  }

  /// --- Methods ---

  void onSelect(int index) {
    if (answered) return;
    setState(() {
      selectedIndex = index;
      answered = true;
    });
  }

  void onNext() {
    if (questionIndex == questions.length - 1) {
      setState(() {
        questionIndex = 0;
        selectedIndex = null;
        answered = false;
      });
      return;
    }
    setState(() {
      questionIndex++;
      selectedIndex = null;
      answered = false;
    });
  }

  /// --- Widgets ---

  Color optionColor(int index) {
    if (!answered) return context.cs.surface;
    if (index == current.answerIndex) return context.cs.primary;
    if (selectedIndex == index && !isCorrect) return context.cs.error;
    return context.cs.surface;
  }

  Color optionTextColor(int index) {
    final fill = optionColor(index);
    if (fill == context.cs.primary || fill == context.cs.error) return context.cs.onPrimary;
    return context.cs.onSurface;
  }

  Widget optionButton(int index) => Button.primary(
      onTap: () => onSelect(index),
      color: optionColor(index),
      text: current.options[index],
      textColor: optionTextColor(index));

  List<Widget> get optionsList => List.generate(
      current.options.length,
      (index) =>
          Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: optionButton(index)));

  Widget get indicator => PageIndicator(
      currentIndex: questionIndex,
      total: questions.length,
      activeColor: context.cs.primary,
      inactiveColor: context.cs.onTertiary.withAlpha(89),
      isExpanded: true);

  Widget get currentListening => Text(
        "${getNumberInVocabulary(questionIndex)} vocabulary",
        style: Style.small2w4(context, color: TextColorRole.greyColor),
      );

  Widget get totalListeningWidget => Text(
        "Total: ${questions.length} vocabularies",
        style: Style.small2w4(context),
      );

  Widget get vocabularyQuestionsInfo => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [currentListening, totalListeningWidget],
      );

  Column promptCardBody() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(current.category, style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 12),
        Text(current.prompt, style: Style.headline5w7(context))
      ]);

  Widget get promptCard => Container(
      height: SizeConfig.screenHeight / 2.2,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border20),
      child: promptCardBody());

  Widget get nextButton =>
      answered ? Button.primary(onTap: onNext, text: 'Next') : const SizedBox(height: 52);

  Widget get view => PrimaryBackground(
        title: 'Vocabulary',
        isScrollable: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),
            indicator,
            const SizedBox(height: 4),
            vocabularyQuestionsInfo,
            const SizedBox(height: 24),
            promptCard,
            const SizedBox(height: 24),
            Text('Answer as many as you can!',
                style: Style.small3w4(context, color: TextColorRole.greyColor)),
            const SizedBox(height: 12),
            ...optionsList,
            const SizedBox(height: 10),
            nextButton
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: context.cs.surface, body: view);
}
