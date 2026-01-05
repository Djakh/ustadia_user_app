import 'package:ustadia_user_app/assets/constants/images.dart';

enum LearnLessonProgressState { completed, inProgress, locked }

class LearnLessonModel {
  final int lessonNumber;
  final String title;
  final String subtitle;
  final String iconAsset;
  final LearnLessonProgressState progressState;

  const LearnLessonModel({
    required this.lessonNumber,
    required this.title,
    required this.subtitle,
    required this.iconAsset,
    required this.progressState
  });

  static const List<LearnLessonModel> sampleLessons = [
    LearnLessonModel(
      lessonNumber: 1,
      title: 'Lesson 1',
      subtitle: 'Short texts & stories',
      iconAsset: AppImages.learnHeadphones,
      progressState: LearnLessonProgressState.completed
    ),
    LearnLessonModel(
      lessonNumber: 2,
      title: 'Lesson 2',
      subtitle: 'Audio & video clips',
      iconAsset: AppImages.learnNotebook,
      progressState: LearnLessonProgressState.completed
    ),
    LearnLessonModel(
      lessonNumber: 3,
      title: 'Lesson 3',
      subtitle: 'Writing tasks & feedback',
      iconAsset: AppImages.learnPen,
      progressState: LearnLessonProgressState.completed
    ),
    LearnLessonModel(
      lessonNumber: 4,
      title: 'Lesson 4',
      subtitle: 'Guided prompts',
      iconAsset: AppImages.learnMicrophone,
      progressState: LearnLessonProgressState.completed
    )
  ];
}
