import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/practice/data/models/activity_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/cards/practice_item_tile_card.dart';
import 'package:ustadia_user_app/router.dart';

class PracticePage extends StatelessWidget {
  const PracticePage({super.key});

  /// --- Data ---

  List<ActivityModel> get activities => const [
        ActivityModel(
            title: 'Flashcard sprint',
            description: 'Flip cards to review words',
            image: AppImages.flashcardSprint,
            route: flashcardSprintRoute),
        ActivityModel(
            title: 'Word match',
            description: 'Match words & meanings',
            image: AppImages.worldMatch,
            route: wordMatchRoute),
        ActivityModel(
            title: 'Build the sentence',
            description: 'Put words in order',
            image: AppImages.buildTheSentence,
            route: buildSentenceRoute),
        // ActivityModel(
        //     title: 'Writing assessment',
        //     description: 'Get AI feedback & score',
        //     image: AppImages.writingAssesment,
        //     route: writingAssessmentRoute),
        ActivityModel(
            title: 'Listen & Tap',
            description: 'Train your ear with audio',
            image: AppImages.listenTap,
            route: listenTapSetsRoute),
        // ActivityModel(
        //     title: 'Vocabulary',
        //     description: 'Choose right answer',
        //     image: AppImages.vocabulary,
        //     route: vocabularyRoute),
        // ActivityModel(
        //     title: 'Speed Mix',
        //     description: 'A fast mix of tasks for 2 minutes',
        //     image: AppImages.speedMix,
        //     route: speedMixRoute),
      ];

  /// --- Methods ---

  void goBack(BuildContext context) => context.pop();

  /// --- Widgets ---

  Widget activityList(BuildContext context) => ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: activities.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => PracticeItemTileCard(activityModel: activities[index]));

  Widget body(BuildContext context) => PrimaryBackground(
      title: 'Practice',
      child: ListView(
        children: [
          // const SizedBox(height: 16),
          //  const PracticeDailyCard(),
          const SizedBox(height: 24),
          activityList(context),
//          const SizedBox(height: 80),
        ],
      ));

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.cs.surface,
        body: SafeArea(child: body(context)),
      );
}
