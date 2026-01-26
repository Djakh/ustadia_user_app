import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_grammar_section/learn_grammar_section_lesson.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_component.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum LearnGrammarStage { lesson, quiz, result }

class LearnGrammarPage extends StatefulWidget {
  final LearnSectionModel sectionModel;

  const LearnGrammarPage({super.key, required this.sectionModel});

  @override
  State<LearnGrammarPage> createState() => LearnGrammarPageState();
}

class LearnGrammarPageState extends State<LearnGrammarPage> {
  final LearnSectionDetailBloc detailBloc = sl<LearnSectionDetailBloc>();
  LearnGrammarStage stage = LearnGrammarStage.lesson;
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
    setState(() => stage = LearnGrammarStage.quiz);
  }

  void finishQuiz(int correct) => setState(() {
        correctCount = correct;
        stage = LearnGrammarStage.result;
      });

  /// --- Widgets ---
  Widget get header => Column(children: [
        Text(widget.sectionModel.title, style: Style.body2w6(context)),
        const SizedBox(height: 2),
        Text(widget.sectionModel.sectionType.name.toUpperCase(),
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget body(BuildContext context, LearnSectionDetailState state) {
    final isLoading = state.status.isLoading || state.detail == null;
    if (stage == LearnGrammarStage.lesson)
      return LearnGrammarLesson(
          sectionModel: widget.sectionModel,
          changeStage: () => changeStage(state),
          isLoading: isLoading);
    if (stage == LearnGrammarStage.quiz)
      return LearnQuizComponent(questions: state.detail?.questions ?? [], onFinish: finishQuiz);
    if (stage == LearnGrammarStage.result) return const QuizResultComponent();
    return LearnGrammarLesson(
        sectionModel: widget.sectionModel,
        changeStage: () => changeStage(state),
        isLoading: isLoading);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          header: header,
          isHeader: stage != LearnGrammarStage.result,
          isScrollable: stage == LearnGrammarStage.quiz,
          child: BlocBuilder<LearnSectionDetailBloc, LearnSectionDetailState>(
              bloc: detailBloc, builder: (context, state) => body(context, state))));
}
