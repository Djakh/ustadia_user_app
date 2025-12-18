import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_step_header_data.dart';
import 'package:ustadia_user_app/features/intro_survey/widgets/intro_survey_chip.dart';
import 'package:ustadia_user_app/features/intro_survey/widgets/intro_survey_header_card.dart';
import 'package:ustadia_user_app/features/intro_survey/widgets/intro_survey_option_tile.dart';
import 'package:ustadia_user_app/features/intro_survey/widgets/steps/intro_survey_daily_goal_step.dart';
import 'package:ustadia_user_app/features/intro_survey/widgets/steps/intro_survey_english_level_step.dart';
import 'package:ustadia_user_app/features/intro_survey/widgets/steps/intro_survey_topics_step.dart';
import 'package:ustadia_user_app/router.dart';

class IntroSurveyPage extends StatefulWidget {
  const IntroSurveyPage({super.key});

  @override
  State<IntroSurveyPage> createState() => _IntroSurveyPageState();
}

class _IntroSurveyPageState extends State<IntroSurveyPage> {
  final _controller = PageController();
  int _pageIndex = 0;
  int _lastAllowedIndex = 0;

  final Set<String> _selectedTopics = {};
  int? _selectedEnglishLevelIndex;
  int? _selectedDailyGoalIndex;

  static const _totalSteps = 3;

  static const _headerData = <IntroSurveyStepHeaderData>[
    IntroSurveyStepHeaderData(
        title: 'What do you want to work on today?',
        subtitle: 'Choose a skill or ask the AI to pick a topic for you.'),
    IntroSurveyStepHeaderData(
        title: "What's your current\nEnglish level?",
        subtitle: "Be honest! We'll adjust the content to match your level."),
    IntroSurveyStepHeaderData(
        title: 'Set your daily goal',
        subtitle: "Be honest! We'll adjust the content to match your level."),
  ];

  static const _topicOptions = <IntroSurveyChipData>[
    IntroSurveyChipData(
      label: 'Career & Business',
      backgroundColor: AppColors.introTopicBusinessLight,
      selectedBackgroundColor: AppColors.introTopicBusinessSelected,
      textColor: AppColors.introTopicBusinessDark,
      selectedTextColor: AppColors.white,
    ),
    IntroSurveyChipData(
      label: 'Education & Studies',
      backgroundColor: AppColors.introTopicEducationLight,
      selectedBackgroundColor: AppColors.introTopicEducationSelected,
      textColor: AppColors.introTopicEducationDark,
      selectedTextColor: AppColors.white,
    ),
    IntroSurveyChipData(
      label: 'Travel & Tourism',
      backgroundColor: AppColors.introTopicTravelLight,
      selectedBackgroundColor: AppColors.introTopicTravelSelected,
      textColor: AppColors.introTopicTravelDark,
      selectedTextColor: AppColors.white,
    ),
    IntroSurveyChipData(
      label: 'Daily Communication',
      backgroundColor: AppColors.introTopicDailyLight,
      selectedBackgroundColor: AppColors.introTopicDailySelected,
      textColor: AppColors.introTopicDailyDark,
      selectedTextColor: AppColors.white,
    ),
    IntroSurveyChipData(
      label: 'Culture & Entertainment',
      backgroundColor: AppColors.introTopicCultureLight,
      selectedBackgroundColor: AppColors.introTopicCultureSelected,
      textColor: AppColors.introTopicCultureDark,
      selectedTextColor: AppColors.white,
    ),
    IntroSurveyChipData(
      label: 'Personal Growth',
      backgroundColor: AppColors.introTopicGrowthLight,
      selectedBackgroundColor: AppColors.introTopicGrowthSelected,
      textColor: AppColors.introTopicGrowthDark,
      selectedTextColor: AppColors.white,
    ),
  ];

  static const _englishLevelOptions = <IntroSurveyOptionData>[
    IntroSurveyOptionData(
      title: 'Just starting out',
      description: 'I know very little English and want to learn from scratch',
    ),
    IntroSurveyOptionData(
      title: 'Learning the basics',
      description: 'I can say hello, introduce myself and understand simple phrases',
    ),
    IntroSurveyOptionData(
      title: 'Getting comfortable',
      description:
          'I can have basic conversations about everyday topics and understand simple texts',
    ),
    IntroSurveyOptionData(
      title: 'Conversational speaker',
      description:
          'I can express ideas clearly, discuss various topics, and understand most conversations',
    ),
    IntroSurveyOptionData(
      title: 'Confident and fluent',
      description: 'I speak English fluently with few mistakes and can understand complex content',
    ),
    IntroSurveyOptionData(
      title: 'Near-native mastery',
      description:
          'I have mastered English and can communicate like a native speaker in all situations',
    ),
  ];

  static const _dailyGoalOptions = <IntroSurveyOptionData>[
    IntroSurveyOptionData(title: 'Casual', description: '5 minutes a day'),
    IntroSurveyOptionData(title: 'Regular', description: '10 minutes a day'),
    IntroSurveyOptionData(title: 'Serious', description: '20 minutes a day'),
  ];

  /// --- Life cycle ---

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// --- Methods ---

  bool canContinueFor(int stepIndex) => switch (stepIndex) {
        0 => _selectedTopics.isNotEmpty,
        1 => _selectedEnglishLevelIndex != null,
        2 => _selectedDailyGoalIndex != null,
        _ => false,
      };

  bool get _canContinue => canContinueFor(_pageIndex);

  void _goToNext() {
    if (!_canContinue) return;

    if (_pageIndex < 2) {
      _controller.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
      return;
    }

    context.go(loginRoute);
  }

  void _onPageChanged(int index) {
    final isForward = index > _lastAllowedIndex;
    if (isForward && !canContinueFor(_lastAllowedIndex)) {
      _controller.animateToPage(_lastAllowedIndex,
          duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
      return;
    }

    setState(() {
      _pageIndex = index;
      _lastAllowedIndex = index;
    });
  }

  void _toggleTopic(String label) {
    setState(() {
      if (_selectedTopics.contains(label)) {
        _selectedTopics.remove(label);
      } else {
        _selectedTopics.add(label);
      }
    });
  }

  /// --- Widgets ---

  IntroSurveyStepHeaderData get _currentHeader => _headerData[_pageIndex];

  Widget get _header => Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: IntroSurveyHeaderCard(
          stepIndex: _pageIndex,
          totalSteps: _totalSteps,
          title: _currentHeader.title,
          subtitle: _currentHeader.subtitle));

  Widget get _pageView => Expanded(
        child: PageView(
          controller: _controller,
          onPageChanged: _onPageChanged,
          physics: const PageScrollPhysics(),
          children: [
            IntroSurveyTopicsStep(
              topics: _topicOptions,
              selectedTopics: _selectedTopics,
              onToggleTopic: _toggleTopic,
            ),
            IntroSurveyEnglishLevelStep(
              options: _englishLevelOptions,
              selectedIndex: _selectedEnglishLevelIndex,
              onSelectIndex: (index) => setState(() => _selectedEnglishLevelIndex = index),
            ),
            IntroSurveyDailyGoalStep(
              options: _dailyGoalOptions,
              selectedIndex: _selectedDailyGoalIndex,
              onSelectIndex: (index) => setState(() => _selectedDailyGoalIndex = index),
            ),
          ],
        ),
      );

  Widget get _continueButton => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Button.primary(
          onTap: _goToNext,
          text: 'Continue',
          isAvialable: _canContinue,
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: context.cs.surface,
        body: SafeArea(
          child: Column(
            children: [
              _header,
              _pageView,
              SafeArea(top: false, child: _continueButton),
            ],
          ),
        ),
      );
}
