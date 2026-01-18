import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_quiz_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_grammar_section/learn_grammar_section_lesson.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_component.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_result_component.dart';
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

  /// --- Getters ---
  
  List<LearnQuizModel> get fallbackQuizModels => LearnQuizModel.grammarSampleQuestions;

  List<LearnQuizModel> quizModelsFor(LearnSectionDetailState state) {
    final quizModels = state.detail?.quizModels ?? [];
    return quizModels.isNotEmpty ? quizModels : fallbackQuizModels;
  }

  /// --- Methods ---

  void changeStage() => setState(() {
        stage = LearnGrammarStage.quiz;
      });

  void finishQuiz(int correct) => setState(() {
        correctCount = correct;
        stage = LearnGrammarStage.result;
      });

  /// --- Widgets  ---

  /// --- Widgets ---

  Widget body(BuildContext context, List<LearnQuizModel> quizModels) {
    if (stage == LearnGrammarStage.lesson)
      return LearnGrammarLesson(sectionModel: widget.sectionModel, changeStage: changeStage);
    if (stage == LearnGrammarStage.quiz)
      return LearnQuizComponent(learnQuizModels: quizModels, onFinish: finishQuiz);
    if (stage == LearnGrammarStage.result)
      return LearnQuizResultComponent(correctCount: correctCount, quizLength: quizModels.length);
    return LearnGrammarLesson(sectionModel: widget.sectionModel, changeStage: changeStage);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: widget.sectionModel.title,
          isHeader: stage != LearnGrammarStage.result,
          isScrollable: stage == LearnGrammarStage.quiz,
          child: BlocBuilder<LearnSectionDetailBloc, LearnSectionDetailState>(
              bloc: detailBloc, builder: (context, state) => body(context, quizModelsFor(state)))));
}
