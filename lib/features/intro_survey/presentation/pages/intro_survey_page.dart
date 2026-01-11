import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_models.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_static_data.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_step_header_data.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/widgets/intro_survey_header_card.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/widgets/steps/intro_survey_daily_goal_step.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/widgets/steps/intro_survey_english_level_step.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/widgets/steps/intro_survey_topics_step.dart';
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
  static const _headers = IntroSurveyStaticData.headers;
  static const List<IntroSurveyTopicModel> _topics = IntroSurveyStaticData.topics;
  static const List<IntroSurveyOptionModel> _englishLevels = IntroSurveyStaticData.englishLevels;
  static const List<IntroSurveyOptionModel> _dailyGoals = IntroSurveyStaticData.dailyGoals;

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

  IntroSurveyStepHeaderData get _currentHeader => _headers[_pageIndex];

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
              topics: _topics, selectedTopics: _selectedTopics, onToggleTopic: _toggleTopic,
            ),
            IntroSurveyEnglishLevelStep(
              options: _englishLevels,
              selectedIndex: _selectedEnglishLevelIndex,
              onSelectIndex: (index) => setState(() => _selectedEnglishLevelIndex = index),
            ),
            IntroSurveyDailyGoalStep(
              options: _dailyGoals,
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
