import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_models.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_step_header_data.dart';

class IntroSurveyStaticData {
  static const headers = <IntroSurveyStepHeaderData>[
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

  static const topics = <IntroSurveyTopicModel>[
    IntroSurveyTopicModel(
        label: 'Career & Business',
        backgroundColor: AppColors.introTopicBusinessLight,
        selectedBackgroundColor: AppColors.introTopicBusinessSelected,
        textColor: AppColors.introTopicBusinessDark,
        selectedTextColor: AppColors.white),
    IntroSurveyTopicModel(
        label: 'Education & Studies',
        backgroundColor: AppColors.introTopicEducationLight,
        selectedBackgroundColor: AppColors.introTopicEducationSelected,
        textColor: AppColors.introTopicEducationDark,
        selectedTextColor: AppColors.white),
    IntroSurveyTopicModel(
        label: 'Travel & Tourism',
        backgroundColor: AppColors.introTopicTravelLight,
        selectedBackgroundColor: AppColors.introTopicTravelSelected,
        textColor: AppColors.introTopicTravelDark,
        selectedTextColor: AppColors.white),
    IntroSurveyTopicModel(
        label: 'Daily Communication',
        backgroundColor: AppColors.introTopicDailyLight,
        selectedBackgroundColor: AppColors.introTopicDailySelected,
        textColor: AppColors.introTopicDailyDark,
        selectedTextColor: AppColors.white),
    IntroSurveyTopicModel(
        label: 'Culture & Entertainment',
        backgroundColor: AppColors.introTopicCultureLight,
        selectedBackgroundColor: AppColors.introTopicCultureSelected,
        textColor: AppColors.introTopicCultureDark,
        selectedTextColor: AppColors.white),
    IntroSurveyTopicModel(
        label: 'Personal Growth',
        backgroundColor: AppColors.introTopicGrowthLight,
        selectedBackgroundColor: AppColors.introTopicGrowthSelected,
        textColor: AppColors.introTopicGrowthDark,
        selectedTextColor: AppColors.white),
  ];

  static const englishLevels = <IntroSurveyOptionModel>[
    IntroSurveyOptionModel(
        title: 'Just starting out',
        description: 'I know very little English and want to learn from scratch'),
    IntroSurveyOptionModel(
        title: 'Learning the basics',
        description: 'I can say hello, introduce myself and understand simple phrases'),
    IntroSurveyOptionModel(
        title: 'Getting comfortable',
        description: 'I can have basic conversations about everyday topics and understand simple texts'),
    IntroSurveyOptionModel(
        title: 'Conversational speaker',
        description: 'I can express ideas clearly, discuss various topics, and understand most conversations'),
    IntroSurveyOptionModel(
        title: 'Confident and fluent',
        description: 'I speak English fluently with few mistakes and can understand complex content'),
    IntroSurveyOptionModel(
        title: 'Near-native mastery',
        description: 'I have mastered English and can communicate like a native speaker in all situations'),
  ];

  static const dailyGoals = <IntroSurveyOptionModel>[
    IntroSurveyOptionModel(title: 'Casual', description: '5 minutes a day'),
    IntroSurveyOptionModel(title: 'Regular', description: '10 minutes a day'),
    IntroSurveyOptionModel(title: 'Serious', description: '20 minutes a day'),
  ];
}

