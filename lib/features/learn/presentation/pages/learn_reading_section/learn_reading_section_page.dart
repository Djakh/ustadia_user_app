import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_quiz_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_reading_section/learn_reading_section_lesson.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_component.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_result_component.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum LearnReadingStage { lesson, quiz, result }

class LearnReadingPage extends StatefulWidget {
  final LearnSectionModel lesson;

  const LearnReadingPage({super.key, required this.lesson});

  @override
  State<LearnReadingPage> createState() => LearnReadingPageState();
}

class LearnReadingPageState extends State<LearnReadingPage> {
  final LearnSectionDetailBloc detailBloc = sl<LearnSectionDetailBloc>();
  LearnReadingStage stage = LearnReadingStage.lesson;
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
  List<LearnQuizModel> get fallbackQuizModels => LearnQuizModel.readingSampleQuestions;

  List<LearnQuizModel> quizModelsFor(LearnSectionDetailState state) {
    final quizModels = state.detail?.quizModels ?? [];
    return quizModels.isNotEmpty ? quizModels : fallbackQuizModels;
  }

  /// --- Methods ---

  void changeStage() => setState(() {
        stage = LearnReadingStage.quiz;
      });

  void finishQuiz(int correct) => setState(() {
        correctCount = correct;
        stage = LearnReadingStage.result;
      });

  /// --- Widgets  ---

  /// --- Widgets ---

  Widget get header => Column(children: [
        Text(widget.lesson.title, style: Style.body2w6(context)),
        const SizedBox(height: 2),
        Text('Reading • Beginner', style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget body(BuildContext context, List<LearnQuizModel> quizModels) {
    if (stage == LearnReadingStage.lesson) return LearnReadingLesson(changeStage: changeStage);
    if (stage == LearnReadingStage.quiz)
      return LearnQuizComponent(learnQuizModels: quizModels, onFinish: finishQuiz);
    if (stage == LearnReadingStage.result)
      return LearnQuizResultComponent(correctCount: correctCount, quizLength: quizModels.length);
    return LearnReadingLesson(changeStage: changeStage);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          header: header,
          isHeader: stage != LearnReadingStage.result,
          isScrollable: stage == LearnReadingStage.quiz,
          child: BlocBuilder<LearnSectionDetailBloc, LearnSectionDetailState>(
              bloc: detailBloc,
              builder: (context, state) => body(context, quizModelsFor(state)))));
}
