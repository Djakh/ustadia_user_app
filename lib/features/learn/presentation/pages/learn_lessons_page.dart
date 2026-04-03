import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/listviews/primary_list_view.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_lesson_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_lessons_bloc/learn_lessons_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_lessons_bloc/learn_lessons_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_lessons_bloc/learn_lessons_state.dart';
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
  bool shouldRefreshParent = false;

  @override
  void initState() {
    super.initState();
    if (lessonsBloc.state.lessons.isEmpty) {
      lessonsBloc.add(const LearnLessonsRequested());
    }
  }

  @override
  void dispose() => super.dispose();

  Future<void> openLesson(BuildContext context, LearnLessonModel lesson) async {
    final result = await context.push<bool?>(learnUnitsRoute, extra: lesson);
    if (!context.mounted) return;
    if (result == true) {
      shouldRefreshParent = true;
      lessonsBloc.add(const LearnLessonsRequested());
    }
  }

  PrimaryListView lessonsList(BuildContext context, List<LearnLessonModel> lessons) =>
      PrimaryListView(
          items: lessons,
          padding: Style.paddingPrimary,
          separatorHeight: 12,
          onRefresh: () async {
            lessonsBloc.add(const LearnLessonsRequested());
          },
          itemBuilder: (item) =>
              LearnLessonCard(lessonModel: item, onTap: () => openLesson(context, item)));

  Widget get contentChecker =>
      BlocStatusView<LearnLessonsBloc, LearnLessonsState, List<LearnLessonModel>>(
        bloc: lessonsBloc,
        statusOf: (s) => s.status,
        errorOf: (s) => s.errorMessage,
        data: (s) => s.lessons,
        isEmpty: (lessons) => lessons.isEmpty,
        keepDataOnLoading: false,
        empty: Center(child: Text('No lessons found'.tr())),
        loading: ShimmerList(
            itemCount: 5,
            itemHeight: 112,
            padding: Style.paddingPrimary,
            borderRadius: Style.border20),
        builder: (context, lessons) => lessonsList(context, lessons),
      );

  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: () async {
        if (!context.mounted) return false;
        context.pop(shouldRefreshParent ? true : null);
        return false;
      },
      child: Scaffold(
          backgroundColor: context.cs.surface,
          body: PrimaryBackground(
              title: 'Lessons'.tr(),
              isScrollable: false,
              onBack: () => context.pop(shouldRefreshParent ? true : null),
              child: contentChecker)));
}
