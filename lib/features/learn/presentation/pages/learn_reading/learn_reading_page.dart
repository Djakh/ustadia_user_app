import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_lesson_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_quiz_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_reading/learn_reading_lesson.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_component.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_result_component.dart';

enum LearnReadingStage { lesson, quiz, result }

class LearnReadingPage extends StatefulWidget {
  final LearnLessonModel lesson;

  const LearnReadingPage({super.key, required this.lesson});

  @override
  State<LearnReadingPage> createState() => LearnReadingPageState();
}

class LearnReadingPageState extends State<LearnReadingPage> {
  LearnReadingStage stage = LearnReadingStage.lesson;
  int correctCount = 0;

  /// --- Getters ---
  List<LearnQuizModel> get learnQuizModels => LearnQuizModel.readingSampleQuestions;

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

  Widget get body {
    if (stage == LearnReadingStage.lesson) return LearnReadingLesson(changeStage: changeStage);
    if (stage == LearnReadingStage.quiz)
      return LearnQuizComponent(learnQuizModels: learnQuizModels, onFinish: finishQuiz);
    if (stage == LearnReadingStage.result)
      return LearnQuizResultComponent(
          correctCount: correctCount, quizLength: learnQuizModels.length);
    return LearnReadingLesson(changeStage: changeStage);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          header: header,
          isHeader: stage != LearnReadingStage.result,
          isScrollable: stage == LearnReadingStage.quiz,
          child: body));
}
