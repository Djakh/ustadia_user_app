import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/result_pages/quiz_result_component.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_listening_section/learn_listening_section_lesson.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_component.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum LearnListeningStage { lesson, quiz, result }

class LearnListeningPage extends StatefulWidget {
  final LearnSectionModel sectionModel;

  const LearnListeningPage({super.key, required this.sectionModel});

  @override
  State<LearnListeningPage> createState() => LearnListeningPageState();
}

class LearnListeningPageState extends State<LearnListeningPage> {
  final LearnSectionDetailBloc detailBloc = sl<LearnSectionDetailBloc>();
  LearnListeningStage stage = LearnListeningStage.lesson;
  int correctCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.sectionModel.id.isNotEmpty) {
      detailBloc.add(LearnSectionDetailRequested(sectionId: widget.sectionModel.id));
    }
  }

  @override
  void dispose() {
    detailBloc.close();
    super.dispose();
  }

  /// --- Methods ---

  void changeStage(LearnSectionDetailState state) {
    if (state.status.isLoading || state.detail == null) return;
    setState(() => stage = LearnListeningStage.quiz);
  }

  void finishQuiz(int correct) => setState(() {
        correctCount = correct;
        stage = LearnListeningStage.result;
      });

  /// --- Widgets  ---

  /// --- Widgets ---
  Widget get header => Column(children: [
        Text(widget.sectionModel.title, style: Style.body2w6(context)),
        const SizedBox(height: 2),
        Text(widget.sectionModel.sectionType.name.toUpperCase(),
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget body(BuildContext context, LearnSectionDetailState state) {
    final isLoading = state.status.isLoading || state.detail == null;
    if (stage == LearnListeningStage.lesson)
      return LearnListeningLesson(
          sectionModel: widget.sectionModel,
          changeStage: () => changeStage(state),
          isLoading: isLoading);
    if (stage == LearnListeningStage.quiz)
      return LearnQuizComponent(questions: state.detail?.questions ?? [], onFinish: finishQuiz);
    if (stage == LearnListeningStage.result) return const QuizResultComponent();
    return LearnListeningLesson(
        sectionModel: widget.sectionModel,
        changeStage: () => changeStage(state),
        isLoading: isLoading);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          header: header,
          isHeader: stage != LearnListeningStage.result,
          isScrollable: stage == LearnListeningStage.quiz,
          child: BlocBuilder<LearnSectionDetailBloc, LearnSectionDetailState>(
              bloc: detailBloc, builder: (context, state) => body(context, state))));
}
