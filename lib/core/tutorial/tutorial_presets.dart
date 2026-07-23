import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';

class TutorialPresets {
  const TutorialPresets._();

  static List<TutorialStepModel> dashboard({
    GlobalKey? profileKey,
    GlobalKey? meetsKey,
    GlobalKey? planKey,
    GlobalKey? gridKey,
    GlobalKey? mockExamKey,
    GlobalKey? reelsKey,
    GlobalKey? assignmentsKey,
    GlobalKey? leaderboardKey,
  }) =>
      [
        TutorialStepModel(
            title: 'Dashboard'.tr(),
            message:
                'This is your daily command center. Lessons, practice, meetings and progress all start from here.'
                    .tr(),
            icon: Icons.home_rounded,
            targetKey: profileKey),
        TutorialStepModel(
            title: 'Meets'.tr(),
            message:
                'Open your upcoming online classes here. If there is a meeting link, it opens in the right app or browser.'
                    .tr(),
            icon: Icons.video_call_rounded,
            targetKey: meetsKey),
        TutorialStepModel(
            title: 'Today plan'.tr(),
            message:
                'Your next lesson card keeps you moving. One tap and you continue from the right unit.'
                    .tr(),
            icon: Icons.event_note_rounded,
            targetKey: planKey),
        TutorialStepModel(
            title: 'Quick actions'.tr(),
            message:
                'This grid is the fastest way to open extra learning tools. Each card below has a separate purpose.'
                    .tr(),
            icon: Icons.dashboard_customize_rounded,
            targetKey: gridKey),
        TutorialStepModel(
            title: 'Mock exam'.tr(),
            message:
                'Mock exam opens IELTS-style tests. Use it when you want a full exam flow with sections, timing, and final band-style result.'
                    .tr(),
            icon: Icons.assignment_turned_in_rounded,
            targetKey: mockExamKey),
        TutorialStepModel(
            title: 'Reels'.tr(),
            message:
                'Reels opens short teacher posts and lesson clips. Swipe vertically, like helpful posts, and open comments when you want discussion.'
                    .tr(),
            icon: Icons.smart_display_rounded,
            targetKey: reelsKey),
        TutorialStepModel(
            title: 'Assignments'.tr(),
            message:
                'Assignments are tasks from your teacher. If this card is disabled, choose a teacher first in Settings.'
                    .tr(),
            icon: Icons.assignment_rounded,
            targetKey: assignmentsKey),
        TutorialStepModel(
            title: 'Leaderboard'.tr(),
            message:
                'Leaderboard shows weekly ranking and XP progress. It is useful for motivation and checking how active you are.'
                    .tr(),
            icon: Icons.emoji_events_rounded,
            targetKey: leaderboardKey),
        TutorialStepModel(
            title: 'Bottom tabs'.tr(),
            message:
                'Use the bottom bar to switch between Home, Lessons, Practice, Ask AI and Profile. It stays close to your thumb.'
                    .tr(),
            icon: Icons.touch_app_rounded),
      ];

  static List<TutorialStepModel> practice({
    GlobalKey? listKey,
    GlobalKey? flashcardKey,
    GlobalKey? wordMatchKey,
    GlobalKey? buildSentenceKey,
    GlobalKey? listenTapKey,
    GlobalKey? monkeyTypeKey,
  }) =>
      [
        TutorialStepModel(
            title: 'Practice'.tr(),
            message:
                'Practice is for short focused drills. Each card opens a different skill game, and completed rounds update your learning progress.'
                    .tr(),
            icon: Icons.extension_rounded,
            targetKey: listKey),
        TutorialStepModel(
            title: 'Flashcard sprint'.tr(),
            message:
                'Use this to review vocabulary quickly. Flip each card, decide if you know it, then use previous/next and the card list to revisit hard words.'
                    .tr(),
            icon: Icons.style_rounded,
            targetKey: flashcardKey),
        TutorialStepModel(
            title: 'Word match'.tr(),
            message:
                'Match each English word with its correct pair. Wrong matches shake back, correct pairs stay connected until the set is complete.'
                    .tr(),
            icon: Icons.compare_arrows_rounded,
            targetKey: wordMatchKey),
        TutorialStepModel(
            title: 'Build the sentence'.tr(),
            message:
                'Tap words in the correct order to build the sentence. If the order is wrong, reset and try again until the sentence is complete.'
                    .tr(),
            icon: Icons.sort_by_alpha_rounded,
            targetKey: buildSentenceKey),
        TutorialStepModel(
            title: 'Listen & Tap'.tr(),
            message:
                'Play the audio, listen carefully, then tap the word you hear. Submit checks the answer and Continue moves to the next audio.'
                    .tr(),
            icon: Icons.hearing_rounded,
            targetKey: listenTapKey),
        TutorialStepModel(
            title: 'Monkey Type'.tr(),
            message:
                'Type the shown text as accurately and quickly as possible. The app tracks WPM, accuracy, time, and lets you move between text items.'
                    .tr(),
            icon: Icons.keyboard_rounded,
            targetKey: monkeyTypeKey),
      ];

  static List<TutorialStepModel> genericPracticeSets({GlobalKey? listKey}) => [
        TutorialStepModel(
            title: 'Choose a set'.tr(),
            message:
                'Pick any set to start. Sets are grouped so you can train one skill without hunting through the whole app.'
                    .tr(),
            icon: Icons.list_alt_rounded,
            targetKey: listKey),
      ];

  static List<TutorialStepModel> genericPracticeSession({GlobalKey? contentKey}) => [
        TutorialStepModel(
            title: 'Practice round'.tr(),
            message:
                'Focus on the task, answer, then move on. Mistakes are allowed here; they are basically progress wearing a disguise.'
                    .tr(),
            icon: Icons.psychology_alt_rounded,
            targetKey: contentKey),
      ];

  static List<TutorialStepModel> flashcardPractice({
    GlobalKey? cardKey,
    GlobalKey? cardsButtonKey,
    GlobalKey? previousKey,
    GlobalKey? mainActionKey,
    GlobalKey? nextKey,
  }) =>
      [
        TutorialStepModel(
            title: 'Flashcard sprint'.tr(),
            message:
                'Read the front side first. Tap the card to flip it and see the meaning when you need a hint.'
                    .tr(),
            icon: Icons.style_rounded,
            targetKey: cardKey),
        TutorialStepModel(
            title: 'Card list'.tr(),
            message:
                'Open the card list anytime. In lessons it shows submitted, learning, and remaining cards; in practice it helps you revisit difficult words.'
                    .tr(),
            icon: Icons.format_list_numbered_rounded,
            targetKey: cardsButtonKey),
        TutorialStepModel(
            title: 'Previous card'.tr(),
            message:
                'Use this to return to the previous flashcard without leaving the sprint.'.tr(),
            icon: Icons.chevron_left_rounded,
            targetKey: previousKey),
        TutorialStepModel(
            title: 'Main action'.tr(),
            message:
                'If you know the word before flipping, press I know it. After the answer is revealed, this button moves you forward.'
                    .tr(),
            icon: Icons.check_circle_rounded,
            targetKey: mainActionKey),
        TutorialStepModel(
            title: 'Next card'.tr(),
            message:
                'Use this to move ahead. On the last card it finishes only after every required card is answered.'
                    .tr(),
            icon: Icons.chevron_right_rounded,
            targetKey: nextKey),
      ];

  static List<TutorialStepModel> wordMatchPractice({GlobalKey? cardsKey}) => [
        TutorialStepModel(
            title: 'Word match rules'.tr(),
            message:
                'Tap one card from the left group and one from the right group. The first tap selects a card; the second tap checks the pair.'
                    .tr(),
            icon: Icons.compare_arrows_rounded,
            targetKey: cardsKey),
        TutorialStepModel(
            title: 'Finish the set'.tr(),
            message:
                'Correct pairs stay on the board. Wrong pairs flash, return to normal, and count as attempts, so careful matching is better than guessing.'
                    .tr(),
            targetKey: cardsKey,
            icon: Icons.flag_rounded),
      ];

  static List<TutorialStepModel> buildSentencePractice({GlobalKey? contentKey}) => [
        TutorialStepModel(
            title: 'Build the sentence rules'.tr(),
            message:
                'Tap words in the order they should appear. The selected words form your sentence, and the app checks the final order.'
                    .tr(),
            icon: Icons.sort_by_alpha_rounded,
            targetKey: contentKey),
        TutorialStepModel(
            title: 'Fix mistakes'.tr(),
            message:
                'If a word is in the wrong place, tap it in the answer area to return it to the pool, then rebuild the sentence.'
                    .tr(),
            targetKey: contentKey,
            icon: Icons.undo_rounded),
      ];

  static List<TutorialStepModel> listenTapPractice({
    GlobalKey? progressKey,
    GlobalKey? audioKey,
    GlobalKey? optionsKey,
    GlobalKey? bottomPanelKey,
    GlobalKey? submitKey,
  }) =>
      [
        TutorialStepModel(
            title: 'Listening progress'.tr(),
            message:
                'This shows which audio item you are solving and how many items are in the set.'
                    .tr(),
            icon: Icons.timeline_rounded,
            targetKey: progressKey),
        TutorialStepModel(
            title: 'Play audio'.tr(),
            message:
                'Play the audio first. You can replay it before choosing an answer, which is useful for difficult pronunciation.'
                    .tr(),
            icon: Icons.play_circle_rounded,
            targetKey: audioKey),
        TutorialStepModel(
            title: 'Choose what you heard'.tr(),
            message:
                'Tap the option that matches the audio. Your choice is highlighted, and you can change it before submitting.'
                    .tr(),
            icon: Icons.touch_app_rounded,
            targetKey: optionsKey),
        TutorialStepModel(
            title: 'Feedback panel'.tr(),
            message:
                'This panel tells you what to do next. After Submit, it turns green or red and explains the result.'
                    .tr(),
            icon: Icons.info_rounded,
            targetKey: bottomPanelKey),
        TutorialStepModel(
            title: 'Submit and continue'.tr(),
            message:
                'Submit checks only the current audio item. After that, the button becomes Continue for the next one.'
                    .tr(),
            icon: Icons.check_circle_rounded,
            targetKey: submitKey),
        TutorialStepModel(
            title: 'Review listening answers'.tr(),
            message:
                'If your answer is wrong, the eye button can reveal the correct option so you can learn from it.'
                    .tr(),
            icon: Icons.visibility_rounded),
      ];

  static List<TutorialStepModel> monkeyTypePractice({
    GlobalKey? progressKey,
    GlobalKey? statsKey,
    GlobalKey? targetTextKey,
    GlobalKey? inputKey,
    GlobalKey? submitKey,
    GlobalKey? navigationKey,
  }) =>
      [
        TutorialStepModel(
            title: 'Text position'.tr(),
            message:
                'This shows which text item you are working on. Some practices contain several texts, so finish them one by one.'
                    .tr(),
            icon: Icons.format_list_numbered_rounded,
            targetKey: progressKey),
        TutorialStepModel(
            title: 'Typing metrics'.tr(),
            message:
                'WPM means words per minute. Accuracy shows how many typed characters match the target text. The timer starts with your first character.'
                    .tr(),
            icon: Icons.speed_rounded,
            targetKey: statsKey),
        TutorialStepModel(
            title: 'Target text'.tr(),
            message:
                'Copy this text exactly. Characters turn green when correct and red when they do not match.'
                    .tr(),
            icon: Icons.text_fields_rounded,
            targetKey: targetTextKey),
        TutorialStepModel(
            title: 'Typing field'.tr(),
            message:
                'Type here. The clear button inside the field resets this attempt without leaving the practice.'
                    .tr(),
            icon: Icons.keyboard_rounded,
            targetKey: inputKey),
        TutorialStepModel(
            title: 'Submit typing result'.tr(),
            message:
                'Submit sends WPM, accuracy, correct characters, total characters, and time to your progress.'
                    .tr(),
            icon: Icons.check_circle_rounded,
            targetKey: submitKey),
        TutorialStepModel(
            title: 'Text navigation'.tr(),
            message:
                'Use Previous and Next to move between text items. Moving to another text clears only the current typing draft.'
                    .tr(),
            icon: Icons.swap_horiz_rounded,
            targetKey: navigationKey),
      ];

  static List<TutorialStepModel> lessons({GlobalKey? listKey}) => [
        TutorialStepModel(
            title: 'Lessons'.tr(),
            message:
                'Lessons are your structured path. Open a lesson, choose a unit, then complete the sections inside it.'
                    .tr(),
            icon: Icons.menu_book_rounded,
            targetKey: listKey),
      ];

  static List<TutorialStepModel> lessonUnits({GlobalKey? listKey}) => [
        TutorialStepModel(
            title: 'Units'.tr(),
            message:
                'Units split a lesson into manageable parts. Locked items open as your teacher or course allows.'
                    .tr(),
            icon: Icons.view_agenda_rounded,
            targetKey: listKey),
      ];

  static List<TutorialStepModel> lessonSections({GlobalKey? listKey}) => [
        TutorialStepModel(
            title: 'Sections'.tr(),
            message:
                'Each section trains a specific skill: listening, reading, speaking, grammar, writing or vocabulary.'
                    .tr(),
            icon: Icons.segment_rounded,
            targetKey: listKey),
      ];

  static List<TutorialStepModel> section({String sectionType = 'lesson'}) {
    final introMessage = switch (sectionType) {
      'reading' =>
        'Read the passage before opening the quiz. Select or long-press English words and choose Translate from the menu when you need help.'
            .tr(),
      'grammar' =>
        'Study the grammar rules first. Select or long-press a word and choose Translate if you need help, then continue when the rule feels clear.'
            .tr(),
      'listening' =>
        'Start by playing the audio and reading any instructions. In the quiz, the same audio stays available above the answers.'
            .tr(),
      'speaking' =>
        'Read the prompt, then use the microphone button to record. The app listens, checks the answer, and moves through each speaking task.'
            .tr(),
      'writing' =>
        'Read the task prompt carefully, write your answer, and attach files only when the task asks for them.'
            .tr(),
      'article' =>
        'Review the article image first, then continue to answer its questions. Tap a linked area in the image to open its video.'
            .tr(),
      _ =>
        'Read or listen to the intro first, then continue to the quiz. Use question navigation when you want to come back later.'
            .tr(),
    };
    final steps = <TutorialStepModel>[
      TutorialStepModel(
          title: 'Section intro'.tr(), message: introMessage, icon: Icons.menu_book_rounded),
      TutorialStepModel(
          title: 'Translate words'.tr(),
          message:
              'Translation works across the app. Select or long-press an English word, tap Translate in the small menu, then switch Uzbek or Russian from the same menu or from the translation bubble.'
                  .tr(),
          icon: Icons.translate_rounded),
      TutorialStepModel(
          title: 'Start the task'.tr(),
          message:
              'When you are ready, press the main action button to begin. Completed sections open directly in review or result mode.'
                  .tr(),
          icon: Icons.play_arrow_rounded),
      TutorialStepModel(
          title: 'During the task'.tr(),
          message:
              'Use the in-task buttons instead of leaving the page: submit, continue, previous, next, helper panels, and lists all keep your progress in this section.'
                  .tr(),
          icon: Icons.touch_app_rounded),
    ];
    return steps;
  }

  static List<TutorialStepModel> sectionQuiz({
    required String questionType,
    String? sectionType,
    bool includeCommonSteps = true,
    bool includeEvidenceStep = false,
    GlobalKey? progressKey,
    GlobalKey? questionListKey,
    GlobalKey? questionKey,
    GlobalKey? answerKey,
    GlobalKey? bottomPanelKey,
    GlobalKey? submitKey,
    GlobalKey? previousKey,
    GlobalKey? nextKey,
    GlobalKey? panelActionKey,
  }) {
    final answerMessage = switch (questionType) {
      'true-false' ||
      'true/false' ||
      'true_false' ||
      'boolean' =>
        'This is a True or False question. Read the statement, compare it with the passage or rule, then choose the correct side.'
            .tr(),
      'single-choice' =>
        'This question accepts one answer only. Tap the best option, then submit when you are sure.'
            .tr(),
      'multiple-choice' =>
        'This question can have several correct options. Select every answer that fits before submitting.'
            .tr(),
      'fill-blank' =>
        'Fill every blank field. Empty blanks cannot be submitted, so check each input before you continue.'
            .tr(),
      'short-answer' =>
        'Type a short answer in your own words. Submit only when the text is complete and clear.'
            .tr(),
      _ =>
        'Tap one answer option. Your selection is highlighted before you submit, so you can change your mind.'
            .tr(),
    };
    final answerStep = TutorialStepModel(
        title: 'Answer area'.tr(),
        message: answerMessage,
        icon: Icons.touch_app_rounded,
        targetKey: answerKey);
    final evidenceStep = TutorialStepModel(
        title: 'Answer evidence'.tr(),
        message: sectionType == 'listening'
            ? 'For listening review, Show answer can open the answer evidence sheet. It may show the exact audio time range and the transcript text, with the answer part marked when available.'
                .tr()
            : 'For reading review, Show answer can open the passage with the answer evidence marked. Use the highlighted text to understand exactly where the correct answer came from.'
                .tr(),
        icon: Icons.find_in_page_rounded,
        mascotMood: TutorialMascotMood.smart,
        accentColor: AppColors.primary,
        accentBackgroundColor: AppColors.greenE7,
        targetKey: bottomPanelKey);
    if (!includeCommonSteps) return includeEvidenceStep ? [evidenceStep] : [answerStep];
    return [
      TutorialStepModel(
          title: 'Quiz progress'.tr(),
          message:
              'This bar shows where you are in the section. The text below tells the current question number and total questions.'
                  .tr(),
          icon: Icons.timeline_rounded,
          targetKey: progressKey),
      TutorialStepModel(
          title: 'Question list'.tr(),
          message:
              'Open this list anytime to jump between questions. Submitted questions are marked, and unfinished ones stay easy to find.'
                  .tr(),
          icon: Icons.fact_check_rounded,
          targetKey: questionListKey),
      TutorialStepModel(
          title: 'Question text'.tr(),
          message:
              'Read the question carefully before answering. For reading and grammar, use the helper button below to reopen the passage or rules.'
                  .tr(),
          icon: Icons.help_outline_rounded,
          targetKey: questionKey),
      answerStep,
      TutorialStepModel(
          title: 'Not answered panel'.tr(),
          message:
              'Before you submit, this white panel tells what is missing. If no answer is selected, Submit stays disabled; if an answer is ready, you can submit or move away and return later.'
                  .tr(),
          icon: Icons.info_rounded,
          mascotMood: TutorialMascotMood.tired,
          accentColor: AppColors.orange09,
          accentBackgroundColor: AppColors.orangeEB,
          targetKey: bottomPanelKey),
      TutorialStepModel(
          title: 'Correct answer panel'.tr(),
          message:
              'After a correct non-exam answer, the panel turns green. Continue moves to the next question, and Finish opens the result only when every question is submitted.'
                  .tr(),
          icon: Icons.check_circle_rounded,
          mascotMood: TutorialMascotMood.strong,
          accentColor: AppColors.primary,
          accentBackgroundColor: AppColors.greenE7,
          targetKey: bottomPanelKey),
      TutorialStepModel(
          title: 'Wrong answer panel'.tr(),
          message:
              'After an incorrect non-exam answer, the panel turns red. That means the answer was submitted but needs review, not that your progress was lost.'
                  .tr(),
          icon: Icons.error_outline_rounded,
          mascotMood: TutorialMascotMood.confused,
          accentColor: AppColors.error,
          accentBackgroundColor: AppColors.redE2,
          targetKey: bottomPanelKey),
      TutorialStepModel(
          title: 'Reveal answer'.tr(),
          message:
              'When review is allowed, the eye button appears on a wrong answer. Tap it to mark the correct option before continuing.'
                  .tr(),
          icon: Icons.visibility_rounded,
          mascotMood: TutorialMascotMood.smart,
          accentColor: AppColors.orange09,
          accentBackgroundColor: AppColors.orangeEB,
          targetKey: bottomPanelKey),
      if (includeEvidenceStep) evidenceStep,
      TutorialStepModel(
          title: 'Exam save state'.tr(),
          message:
              'In mock exams, answers are saved without showing green or red feedback. This keeps exam practice realistic until the final result.'
                  .tr(),
          icon: Icons.assignment_turned_in_rounded,
          mascotMood: TutorialMascotMood.strong,
          accentColor: AppColors.primary,
          accentBackgroundColor: AppColors.greenE7,
          targetKey: bottomPanelKey),
      if (panelActionKey != null)
        TutorialStepModel(
            title: 'Lesson helper'.tr(),
            message:
                'This button reopens the reading passage or grammar rules without leaving the quiz. Use it when the question depends on the text.'
                    .tr(),
            icon: Icons.menu_book_rounded,
            targetKey: panelActionKey),
      TutorialStepModel(
          title: 'Submit answer'.tr(),
          message:
              'Submit checks the current answer only. After it is submitted, this same button becomes Continue, or Finish when the whole quiz is ready for the result page.'
                  .tr(),
          icon: Icons.check_circle_rounded,
          targetKey: submitKey),
      TutorialStepModel(
          title: 'Result button'.tr(),
          message:
              'The result page opens only after every question is submitted. At that point the main button says Finish, so unfinished answers cannot be skipped by accident.'
                  .tr(),
          icon: Icons.emoji_events_rounded,
          mascotMood: TutorialMascotMood.strong,
          accentColor: AppColors.primary,
          accentBackgroundColor: AppColors.greenE7,
          targetKey: submitKey),
      TutorialStepModel(
          title: 'Previous question'.tr(),
          message:
              'Use the left button to go back. Your unsent draft is kept locally while you move between questions.'
                  .tr(),
          icon: Icons.chevron_left_rounded,
          targetKey: previousKey),
      TutorialStepModel(
          title: 'Next or finish'.tr(),
          message:
              'Use the right button to skip ahead or finish. If some questions are not submitted, the question list opens so you can complete them first.'
                  .tr(),
          icon: Icons.chevron_right_rounded,
          targetKey: nextKey),
    ];
  }

  static List<TutorialStepModel> assignments({GlobalKey? tabsKey, GlobalKey? listKey}) => [
        TutorialStepModel(
            title: 'Assignments'.tr(),
            message:
                'Teacher tasks live here. Active assignments need attention; completed ones stay in history.'
                    .tr(),
            icon: Icons.assignment_rounded,
            targetKey: tabsKey),
        TutorialStepModel(
            title: 'Assignment cards'.tr(),
            message:
                'Open a card to see its sections and submit the required work before the deadline.'
                    .tr(),
            icon: Icons.task_alt_rounded,
            targetKey: listKey),
      ];

  static List<TutorialStepModel> assignmentSections() => [
        TutorialStepModel(
            title: 'Assignment sections'.tr(),
            message:
                'Complete each section in order. Some sections are quizzes, others may ask for writing, audio or uploaded work.'
                    .tr(),
            icon: Icons.checklist_rounded),
      ];

  static List<TutorialStepModel> assignmentDetails() => [
        TutorialStepModel(
            title: 'Assignment details'.tr(),
            message:
                'Read the task carefully, answer or upload what is required, then submit when everything looks ready.'
                    .tr(),
            icon: Icons.assignment_turned_in_rounded),
      ];

  static List<TutorialStepModel> askAi({GlobalKey? topicsKey}) => [
        TutorialStepModel(
            title: 'Ask AI'.tr(),
            message:
                'Choose a topic and talk with the AI voice tutor. It is best for speaking practice, explanations and quick feedback.'
                    .tr(),
            icon: Icons.auto_awesome_rounded,
            targetKey: topicsKey),
      ];

  static List<TutorialStepModel> voiceAgent() => [
        TutorialStepModel(
            title: 'Voice agent'.tr(),
            message:
                'Use the microphone button to speak. The speaker/phone toggle controls where audio plays, like a real call.'
                    .tr(),
            icon: Icons.mic_rounded),
      ];

  static List<TutorialStepModel> profile({
    GlobalKey? userKey,
    GlobalKey? notificationsKey,
    GlobalKey? settingsKey,
    GlobalKey? statsKey,
    GlobalKey? levelKey,
    GlobalKey? completedTasksKey,
    GlobalKey? vocabularyKey,
    GlobalKey? breakdownKey,
    GlobalKey? leaderboardKey,
  }) =>
      [
        TutorialStepModel(
            title: 'Profile'.tr(),
            message:
                'This card shows your name, profile photo, and XP. Tap the avatar to open the profile picture in full view.'
                    .tr(),
            icon: Icons.person_rounded,
            targetKey: userKey),
        TutorialStepModel(
            title: 'Notifications'.tr(),
            message:
                'Open notifications to see important updates from lessons, assignments, teacher actions, and app messages.'
                    .tr(),
            icon: Icons.notifications_rounded,
            targetKey: notificationsKey),
        TutorialStepModel(
            title: 'Settings'.tr(),
            message:
                'Settings controls your account, app language, teacher selection, and logout. Use it when your learning setup changes.'
                    .tr(),
            icon: Icons.settings_rounded,
            targetKey: settingsKey),
        TutorialStepModel(
            title: 'Stats'.tr(),
            message:
                'These four cards summarize your learning. They update after lessons, practice rounds, assignments, and teacher changes.'
                    .tr(),
            icon: Icons.insights_rounded,
            targetKey: statsKey),
        TutorialStepModel(
            title: 'Current level'.tr(),
            message:
                'This shows your current study level. If you are using system lessons, tapping it lets you change level.'
                    .tr(),
            icon: Icons.stacked_line_chart_rounded,
            targetKey: levelKey),
        TutorialStepModel(
            title: 'Completed tasks'.tr(),
            message:
                'This counts finished learning work across the app, including lessons, practice, and assignments.'
                    .tr(),
            icon: Icons.task_alt_rounded,
            targetKey: completedTasksKey),
        TutorialStepModel(
            title: 'Vocabulary'.tr(),
            message:
                'This shows your vocabulary progress, especially words learned through flashcards and related exercises.'
                    .tr(),
            icon: Icons.translate_rounded,
            targetKey: vocabularyKey),
        TutorialStepModel(
            title: 'Breakdown'.tr(),
            message:
                'Breakdown separates your completed work by type: practice, assignments, and lessons. It helps you see what you train most.'
                    .tr(),
            icon: Icons.pie_chart_rounded,
            targetKey: breakdownKey),
        TutorialStepModel(
            title: 'Leaderboard'.tr(),
            message:
                'This card shows your weekly rank. Open the full leaderboard to compare XP and activity with other learners.'
                    .tr(),
            icon: Icons.emoji_events_rounded,
            targetKey: leaderboardKey),
      ];

  static List<TutorialStepModel> settings({GlobalKey? listKey}) => [
        TutorialStepModel(
            title: 'Settings'.tr(),
            message:
                'Manage account details, app language and teacher selection here. Logout is separated so it is harder to tap by accident.'
                    .tr(),
            icon: Icons.settings_rounded,
            targetKey: listKey),
      ];

  static List<TutorialStepModel> editAccount() => [
        TutorialStepModel(
            title: 'Account'.tr(),
            message:
                'Update your name and profile photo here. Keeping this clear helps teachers recognize your work.'
                    .tr(),
            icon: Icons.manage_accounts_rounded),
      ];

  static List<TutorialStepModel> leaderboard() => [
        TutorialStepModel(
            title: 'Leaderboard'.tr(),
            message:
                'This page ranks learners by progress. Use it for motivation, not stress. Points like calm learners.'
                    .tr(),
            icon: Icons.emoji_events_rounded),
      ];

  static List<TutorialStepModel> notifications() => [
        TutorialStepModel(
            title: 'Notifications'.tr(),
            message:
                'Important updates from lessons, assignments and the app appear here so you do not miss what changed.'
                    .tr(),
            icon: Icons.notifications_rounded),
      ];

  static List<TutorialStepModel> language({GlobalKey? listKey}) => [
        TutorialStepModel(
            title: 'Language'.tr(),
            message:
                'Pick the interface language. The app updates immediately and also saves it to your profile.'
                    .tr(),
            icon: Icons.language_rounded,
            targetKey: listKey),
      ];

  static List<TutorialStepModel> teacherPicker({GlobalKey? listKey}) => [
        TutorialStepModel(
            title: 'Choose teacher'.tr(),
            message:
                'Choose system lessons for the default course, or select your teacher to follow their class plan.'
                    .tr(),
            icon: Icons.people_rounded,
            targetKey: listKey),
      ];

  static List<TutorialStepModel> meets() => [
        TutorialStepModel(
            title: 'Meets'.tr(),
            message:
                'Upcoming meetings are shown separately from history. Tap the link to join through your browser or meeting app.'
                    .tr(),
            icon: Icons.video_call_rounded),
      ];

  static List<TutorialStepModel> reels() => [
        TutorialStepModel(
            title: 'Reels'.tr(),
            message:
                'Swipe vertically to watch short learning posts. Like, comment, or open the author profile from the reel.'
                    .tr(),
            icon: Icons.smart_display_rounded),
      ];
}
