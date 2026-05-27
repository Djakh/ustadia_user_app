import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/practice/data/models/activity_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/cards/practice_item_tile_card.dart';
import 'package:ustadia_user_app/router.dart';

class PracticePage extends StatefulWidget {
  const PracticePage({super.key});

  @override
  State<PracticePage> createState() => PracticePageState();
}

class PracticePageState extends State<PracticePage> {
  final GlobalKey activityListKey = GlobalKey(debugLabel: 'practice_activity_list');
  final GlobalKey flashcardKey = GlobalKey(debugLabel: 'practice_flashcard');
  final GlobalKey wordMatchKey = GlobalKey(debugLabel: 'practice_word_match');
  final GlobalKey buildSentenceKey = GlobalKey(debugLabel: 'practice_build_sentence');
  final GlobalKey listenTapKey = GlobalKey(debugLabel: 'practice_listen_tap');
  final GlobalKey monkeyTypeKey = GlobalKey(debugLabel: 'practice_monkey_type');

  /// --- Data ---

  List<ActivityModel> get activities => [
        ActivityModel(
            title: 'Flashcard sprint'.tr(),
            description: 'Flip cards to review words'.tr(),
            image: AppImages.flashcardSprint,
            route: flashcardSprintRoute),
        ActivityModel(
            title: 'Word match'.tr(),
            description: 'Match words & meanings'.tr(),
            image: AppImages.worldMatch,
            route: wordMatchRoute),
        ActivityModel(
            title: 'Build the sentence'.tr(),
            description: 'Put words in order'.tr(),
            image: AppImages.buildTheSentence,
            route: buildSentenceRoute),
        // ActivityModel(
        //     title: 'Writing assessment'.tr(),
        //     description: 'Get AI feedback & score',
        //     image: AppImages.writingAssesment,
        //     route: writingAssessmentRoute),
        ActivityModel(
            title: 'Listen & Tap'.tr(),
            description: 'Train your ear with audio'.tr(),
            image: AppImages.listenTap,
            route: listenTapSetsRoute),
        ActivityModel(
            title: 'Monkey Type'.tr(),
            description: 'Train typing speed'.tr(),
            image: AppImages.monkeyType,
            route: monkeyTypeRoute),
        // ActivityModel(
        //     title: 'Vocabulary'.tr(),
        //     description: 'Choose right answer',
        //     image: AppImages.vocabulary,
        //     route: vocabularyRoute),
        // ActivityModel(
        //     title: 'Speed Mix'.tr(),
        //     description: 'A fast mix of tasks for 2 minutes',
        //     image: AppImages.speedMix,
        //     route: speedMixRoute),
      ];

  /// --- Methods ---

  void goBack(BuildContext context) => context.pop();

  /// --- Widgets ---

  GlobalKey? activityKey(ActivityModel activity) {
    if (activity.route == flashcardSprintRoute) return flashcardKey;
    if (activity.route == wordMatchRoute) return wordMatchKey;
    if (activity.route == buildSentenceRoute) return buildSentenceKey;
    if (activity.route == listenTapSetsRoute) return listenTapKey;
    if (activity.route == monkeyTypeRoute) return monkeyTypeKey;
    return null;
  }

  Widget activityList(BuildContext context) => ListView.separated(
      key: activityListKey,
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: activities.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => KeyedSubtree(
          key: activityKey(activities[index]),
          child: PracticeItemTileCard(activityModel: activities[index])));

  Widget body(BuildContext context) => PrimaryBackground(
      title: 'Practice'.tr(),
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
  Widget build(BuildContext context) => GuidedTutorialPage(
      pageId: TutorialPageIds.practice,
      steps: TutorialPresets.practice(
          listKey: activityListKey,
          flashcardKey: flashcardKey,
          wordMatchKey: wordMatchKey,
          buildSentenceKey: buildSentenceKey,
          listenTapKey: listenTapKey,
          monkeyTypeKey: monkeyTypeKey),
      child: Scaffold(
        backgroundColor: context.cs.surface,
        body: SafeArea(child: body(context)),
      ));
}
