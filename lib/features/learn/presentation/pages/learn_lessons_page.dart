import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/listviews/primary_list_view.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_lesson_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_lessons_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_lessons_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_lessons_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/learn_lesson_card.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class LearnLessonsPage extends StatefulWidget {
  const LearnLessonsPage({super.key});

  @override
  State<LearnLessonsPage> createState() => LearnLessonsPageState();
}

class LearnLessonsPageState extends State<LearnLessonsPage> {
  final LearnLessonsBloc lessonsBloc = sl<LearnLessonsBloc>();

  @override
  void initState() {
    super.initState();
    lessonsBloc.add(const LearnLessonsRequested());
  }

  @override
  void dispose() {
    lessonsBloc.close();
    super.dispose();
  }

  void openLesson(BuildContext context, LearnLessonModel lesson) =>
      context.push(learnUnitsRoute, extra: lesson);

  PrimaryListView lessonsList(BuildContext context, List<LearnLessonModel> lessons) =>
      PrimaryListView(
          items: lessons,
          padding: Style.paddingPrimary,
          shrinkWrap: true,
          separatorHeight: 12,
          itemBuilder: (item) =>
              LearnLessonCard(lessonModel: item, onTap: () => openLesson(context, item)));

  Widget get contentChecker =>
      BlocStatusView<LearnLessonsBloc, LearnLessonsState, List<LearnLessonModel>>(
        bloc: lessonsBloc,
        statusOf: (s) => s.status,
        errorOf: (s) => s.errorMessage,
        data: (s) => s.lessons,
        isEmpty: (units) => units.isEmpty,
        empty: const Center(child: Text('No lessons found')),
        builder: (context, lessons) => lessonsList(context, lessons),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(title: 'Lessons', isScrollable: false, child: contentChecker));
}
