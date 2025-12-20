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
        backgroundColor: AppColors.purpleFF,
        selectedBackgroundColor: AppColors.purpleD6,
        textColor: AppColors.purpleD6),
    IntroSurveyTopicModel(
        label: 'Education & Studies',
        backgroundColor: AppColors.greenE9,
        selectedBackgroundColor: AppColors.green55,
        textColor: AppColors.green3B),
    IntroSurveyTopicModel(
        label: 'Travel & Tourism',
        backgroundColor: AppColors.orangeE6,
        selectedBackgroundColor: AppColors.orange00,
        textColor: AppColors.orange5A),
    IntroSurveyTopicModel(
        label: 'Daily Communication',
        backgroundColor: AppColors.blueFF,
        selectedBackgroundColor: AppColors.blueB3,
        textColor: AppColors.blueD3),
    IntroSurveyTopicModel(
        label: 'Culture & Entertainment',
        backgroundColor: AppColors.greenD8,
        selectedBackgroundColor: AppColors.green00,
        textColor: AppColors.green7C),
    IntroSurveyTopicModel(
        label: 'Personal Growth',
        backgroundColor: AppColors.pinkF7,
        selectedBackgroundColor: AppColors.pinkB7,
        textColor: AppColors.pink72),
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
        description:
            'I can have basic conversations about everyday topics and understand simple texts'),
    IntroSurveyOptionModel(
        title: 'Conversational speaker',
        description:
            'I can express ideas clearly, discuss various topics, and understand most conversations'),
    IntroSurveyOptionModel(
        title: 'Confident and fluent',
        description:
            'I speak English fluently with few mistakes and can understand complex content'),
    IntroSurveyOptionModel(
        title: 'Near-native mastery',
        description:
            'I have mastered English and can communicate like a native speaker in all situations'),
  ];

  static const dailyGoals = <IntroSurveyOptionModel>[
    IntroSurveyOptionModel(title: 'Casual', description: '5 minutes a day'),
    IntroSurveyOptionModel(title: 'Regular', description: '10 minutes a day'),
    IntroSurveyOptionModel(title: 'Serious', description: '20 minutes a day'),
  ];
}
