import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_quiz_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_grammar/learn_grammar_lesson.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_component.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_result_component.dart';

enum LearnGrammarStage { lesson, quiz, result }

class LearnGrammarPage extends StatefulWidget {
  final LearnSectionModel lesson;

  const LearnGrammarPage({super.key, required this.lesson});

  @override
  State<LearnGrammarPage> createState() => LearnGrammarPageState();
}

class LearnGrammarPageState extends State<LearnGrammarPage> {
  LearnGrammarStage stage = LearnGrammarStage.lesson;
  int correctCount = 0;

  /// --- Getters ---
  List<LearnQuizModel> get learnQuizModels => LearnQuizModel.grammarSampleQuestions;

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

  Widget get header => Column(children: [
        Text(widget.lesson.title, style: Style.body2w6(context)),
        const SizedBox(height: 2),
        Text('Grammar • Beginner', style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget get body {
    if (stage == LearnGrammarStage.lesson) return LearnGrammarLesson(changeStage: changeStage);
    if (stage == LearnGrammarStage.quiz)
      return LearnQuizComponent(learnQuizModels: learnQuizModels, onFinish: finishQuiz);
    if (stage == LearnGrammarStage.result)
      return LearnQuizResultComponent(
          correctCount: correctCount, quizLength: learnQuizModels.length);
    return LearnGrammarLesson(changeStage: changeStage);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          header: header,
          isHeader: stage != LearnGrammarStage.result,
          isScrollable: stage == LearnGrammarStage.quiz,
          child: body));
}
