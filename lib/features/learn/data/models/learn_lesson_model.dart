import 'package:ustadia_user_app/assets/constants/images.dart';

enum LearnLessonProgressState { completed, inProgress, locked }

enum LearnLessonType { listening, reading, writing, speaking, grammar, flashcardSprint }

class LearnLessonModel {
  final int lessonNumber;
  final String title;
  final String subtitle;
  final String iconAsset;
  final LearnLessonProgressState progressState;
  final LearnLessonType lessonType;

  const LearnLessonModel(
      {required this.lessonNumber,
      required this.title,
      required this.subtitle,
      required this.iconAsset,
      required this.progressState,
      required this.lessonType});

  static const List<LearnLessonModel> sampleLessons = [
    LearnLessonModel(
        lessonNumber: 1,
        title: 'Lesson 1',
        subtitle: 'Short texts & stories',
        iconAsset: AppImages.learnHeadphones,
        progressState: LearnLessonProgressState.completed,
        lessonType: LearnLessonType.listening),
    LearnLessonModel(
        lessonNumber: 2,
        title: 'Lesson 2',
        subtitle: 'Audio & video clips',
        iconAsset: AppImages.learnNotebook,
        progressState: LearnLessonProgressState.completed,
        lessonType: LearnLessonType.reading),
    LearnLessonModel(
        lessonNumber: 3,
        title: 'Lesson 3',
        subtitle: 'Writing tasks & feedback',
        iconAsset: AppImages.learnPen,
        progressState: LearnLessonProgressState.completed,
        lessonType: LearnLessonType.writing),
    LearnLessonModel(
        lessonNumber: 4,
        title: 'Lesson 4',
        subtitle: 'Guided prompts',
        iconAsset: AppImages.learnMicrophone,
        progressState: LearnLessonProgressState.completed,
        lessonType: LearnLessonType.speaking),
    LearnLessonModel(
        lessonNumber: 5,
        title: 'Lesson 5',
        subtitle: 'Checking grammar',
        iconAsset: AppImages.learnGrammar,
        progressState: LearnLessonProgressState.completed,
        lessonType: LearnLessonType.grammar),
    LearnLessonModel(
        lessonNumber: 6,
        title: 'Lesson 6',
        subtitle: 'Learn new words',
        iconAsset: AppImages.flashcardSprint,
        progressState: LearnLessonProgressState.completed,
        lessonType: LearnLessonType.flashcardSprint)
  ];
}
