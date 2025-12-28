import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/practice/cubit/next_practice_bloc.dart';
import 'package:ustadia_user_app/features/practice/data/models/vocabulary_question.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/vocabulary_content.dart';

class VocabularyPage extends StatefulWidget {
  const VocabularyPage({super.key});

  @override
  State<VocabularyPage> createState() => _VocabularyPageState();
}

class _VocabularyPageState extends State<VocabularyPage> {
  int questionIndex = 0;

  /// --- Data ---

  List<VocabularyModel> get vocabularyModels => const [
        VocabularyModel(
            category: 'Vocabulary',
            prompt: 'Synonym for “Fast”',
            options: ['Quick', 'Slow', 'Calm'],
            answerIndex: 0),
        VocabularyModel(
            category: 'Vocabulary',
            prompt: 'Synonym for “Happy”',
            options: ['Sad', 'Joyful', 'Angry'],
            answerIndex: 1),
        VocabularyModel(
            category: 'Vocabulary',
            prompt: 'Synonym for “Smart”',
            options: ['Bright', 'Lazy', 'Dull'],
            answerIndex: 0),
      ];

  VocabularyModel get currentVocabularyModel => vocabularyModels[questionIndex];

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    context.read<NextPracticeBloc>().setCurrentTaskCompleted(false);
  }

  /// --- Methods ---

  String ordinalLabel(int index) {
    switch (index) {
      case 0:
        return 'First';
      case 1:
        return 'Second';
      case 2:
        return 'Third';
      default:
        return '${index + 1}th';
    }
  }

  void onNext() {
    setState(() {
      if (questionIndex == vocabularyModels.length - 1) {
        questionIndex = 0;
      } else {
        questionIndex++;
      }
    });
    context.read<NextPracticeBloc>().setCurrentTaskCompleted(false);
  }

  /// --- Widgets ---

  Widget indicator(BuildContext context) => PageIndicator(
      currentIndex: questionIndex,
      total: vocabularyModels.length,
      activeColor: context.cs.primary,
      inactiveColor: context.cs.onTertiary.withValues(alpha: 0.3),
      isExpanded: true);

  Widget info(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${ordinalLabel(questionIndex)} word',
            style: Style.small2w4(context, color: TextColorRole.greyColor)),
        Text('Total: ${vocabularyModels.length} words',
            style: Style.small2w4(context, color: TextColorRole.greyColor))
      ]);

  Widget nextButton(BuildContext context, bool isEnabled) =>
      Button.primary(onTap: onNext, text: 'Next', isAvialable: isEnabled);

  Widget view(BuildContext context, NextPracticeState state) =>
      Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const SizedBox(height: 16),
        indicator(context),
        const SizedBox(height: 4),
        info(context),
        const SizedBox(height: 24),
        VocabularyContent(vocabularyModel: currentVocabularyModel),
        const SizedBox(height: 10),
        nextButton(context, state.isCurrentTaskCompleted)
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: BlocBuilder<NextPracticeBloc, NextPracticeState>(
          builder: (context, state) => PrimaryBackground(
              title: 'Vocabulary',
              isScrollable: true,
              child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: view(context, state)))));
}
