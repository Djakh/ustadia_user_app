import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_state.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_quiz_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_listening_section/learn_listening_section_lesson.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_component.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_result_component.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum LearnListeningStage { lesson, quiz, result }

class LearnListeningPage extends StatefulWidget {
  final LearnSectionModel lesson;

  const LearnListeningPage({super.key, required this.lesson});

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
    if (widget.lesson.id.isNotEmpty) {
      detailBloc.add(LearnSectionDetailRequested(sectionId: widget.lesson.id));
    }
  }

  @override
  void dispose() {
    detailBloc.close();
    super.dispose();
  }

  /// --- Getters ---
  List<LearnQuizModel> get fallbackQuizModels => LearnQuizModel.listeningSampleQuestions;

  List<LearnQuizModel> quizModelsFor(LearnSectionDetailState state) {
    final quizModels = state.detail?.quizModels ?? [];
    return quizModels.isNotEmpty ? quizModels : fallbackQuizModels;
  }

  /// --- Methods ---

  void changeStage() => setState(() {
        stage = LearnListeningStage.quiz;
      });

  void finishQuiz(int correct) => setState(() {
        correctCount = correct;
        stage = LearnListeningStage.result;
      });

  /// --- Widgets  ---

  /// --- Widgets ---
  Widget get header => Column(children: [
        Text(widget.lesson.title, style: Style.body2w6(context)),
        const SizedBox(height: 2),
        Text('Listening • Beginner', style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget body(BuildContext context, List<LearnQuizModel> quizModels) {
    if (stage == LearnListeningStage.lesson) return LearnListeningLesson(changeStage: changeStage);
    if (stage == LearnListeningStage.quiz)
      return LearnQuizComponent(learnQuizModels: quizModels, onFinish: finishQuiz);
    if (stage == LearnListeningStage.result)
      return LearnQuizResultComponent(correctCount: correctCount, quizLength: quizModels.length);
    return LearnListeningLesson(changeStage: changeStage);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          header: header,
          isHeader: stage != LearnListeningStage.result,
          isScrollable: stage == LearnListeningStage.quiz,
          child: BlocBuilder<LearnSectionDetailBloc, LearnSectionDetailState>(
              bloc: detailBloc,
              builder: (context, state) => body(context, quizModelsFor(state)))));
}
