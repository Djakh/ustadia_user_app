import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/listviews/primary_list_view.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_lesson_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/learn_lesson_card.dart';
import 'package:ustadia_user_app/router.dart';

class LearnLessonsPage extends StatelessWidget {
  final LearnUnitModel unit;

  const LearnLessonsPage({super.key, required this.unit});

  List<LearnLessonModel> get lessons => LearnLessonModel.sampleLessons;

  void onLessonTap(BuildContext context, LearnLessonModel lesson) {
    if (lesson.lessonType == LearnLessonType.listening)
      context.push(learnListeningRoute, extra: lesson);
    if (lesson.lessonType == LearnLessonType.reading)
      context.push(learnReadingRoute, extra: lesson);
    if (lesson.lessonType == LearnLessonType.grammar)
      context.push(learnGrammarRoute, extra: lesson);
    if (lesson.lessonType == LearnLessonType.flashcardSprint)
      context.push(flashcardSprintRoute, extra: lesson);
    if (lesson.lessonType == LearnLessonType.writing)
      context.push(learnWritingRoute, extra: lesson);
  }

  PrimaryListView lessonsList(BuildContext context) => PrimaryListView(
      items: lessons,
      shrinkWrap: true,
      separatorHeight: 12,
      itemBuilder: (item) =>
          LearnLessonCard(lesson: item, onTap: () => onLessonTap(context, item)));

  Widget body(BuildContext context) => Column(
      children: [const SizedBox(height: 12), lessonsList(context), const SizedBox(height: 24)]);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(title: 'Learn', isScrollable: true, child: body(context)));
}
