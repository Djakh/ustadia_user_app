import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_answer_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_question_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/next_task_bloc/next_task_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/cards/listening_quiz_card.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_state.dart';
import 'package:ustadia_user_app/injection_container.dart';

class SectionQuizComponent extends StatefulWidget {
  final List<SectionQuestionModel> questions;
  final ValueChanged<int> onFinish;
  const SectionQuizComponent({super.key, required this.questions, required this.onFinish});

  @override
  State<SectionQuizComponent> createState() => _SectionQuizComponentState();
}

class _SectionQuizComponentState extends State<SectionQuizComponent> {
  late List<SectionQuestionModel> questions;
  final QuestionAnswerBloc answerBloc = sl<QuestionAnswerBloc>();
  int questionIndex = 0;
  int correctCount = 0;

  int? selectedIndex;

  /// --- Life cycle ---

  @override
  void initState() {
    questions = widget.questions;
    context.read<NextTaskBloc>().setCurrentTaskCompleted(false);

    super.initState();
  }

  @override
  void dispose() {
    answerBloc.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SectionQuizComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questions != widget.questions) {
      questions = widget.questions;
      questionIndex = 0;
      correctCount = 0;
      selectedIndex = null;
      context.read<NextTaskBloc>().setCurrentTaskCompleted(false);
    }
  }

  /// --- Getters ---
  SectionQuestionModel get currentQuestion => questions[questionIndex];
  List<SectionAnswerModel> get currentAnswers => currentQuestion.answers ?? [];

  /// --- Methods ---

  void onSelectAnswerOption(int index) {
    final bloc = context.read<NextTaskBloc>();
    if (bloc.state.isCurrentTaskCompleted) return;
    if (answerBloc.state.status.isLoading) return;
    if (currentAnswers.isEmpty) return;
    selectedIndex = index;
    bool isAnswerCorrect = currentAnswers[index].isCorrect;
    answerBloc.add(QuestionAnswerSubmitted(
        sectionId: currentQuestion.sectionId,
        questionId: currentQuestion.id,
        answerId: currentAnswers[index].id,
        assignmentId: currentQuestion.assignmentId,
        source: currentQuestion.source));
    bloc.setCurrentTaskCompleted(true, isAnswerCorrect: isAnswerCorrect);
    if (isAnswerCorrect) correctCount++;
  }

  void continueAfterAnswer() {
    context.read<NextTaskBloc>().setCurrentTaskCompleted(false);

    if (questionIndex == questions.length - 1) return widget.onFinish(correctCount);

    questionIndex++;
    selectedIndex = null;

    setState(() {});
  }

  /// --- Widgets ---

  Widget get indicator =>
      PageIndicator(currentIndex: questionIndex, total: questions.length, isExpanded: true);

  Row get progressHeaderInfo => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${questionIndex + 1} Question',
            style: Style.small2w4(context, color: TextColorRole.greyColor)),
        Text('Total ${questions.length} Questions', style: Style.small2w4(context))
      ]);

  Widget get progressHeader =>
      Column(children: [indicator, const SizedBox(height: 4), progressHeaderInfo]);

  /// --- Widgets ---

  Color optionColor(BuildContext context, int index) {
    if (selectedIndex == null) return context.cs.surface;
    if (currentAnswers.isNotEmpty && currentAnswers[index].isCorrect) return context.cs.primary;
    if (selectedIndex == index && (currentAnswers.isEmpty || !currentAnswers[index].isCorrect)) {
      return context.cs.error;
    }
    return context.cs.surface;
  }

  Color optionTextColor(BuildContext context, int index) {
    final fill = optionColor(context, index);
    if (fill == context.cs.primary || fill == context.cs.error) return context.cs.onPrimary;
    return context.cs.onSurface;
  }

  Button optionItem(int index) => Button.primary(
      onTap: () => onSelectAnswerOption(index),
      color: optionColor(context, index),
      textColor: optionTextColor(context, index),
      text: currentAnswers[index].answerText);

  List<Widget> get optionsList => List.generate(
      currentAnswers.length,
      (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: optionItem(index),
          ));

  Widget continueButton(NextTaskState state, QuestionAnswerState answerState) => Button.primary(
      onTap: continueAfterAnswer,
      text: 'Continue',
      isAvialable: state.isCurrentTaskCompleted && !answerState.status.isLoading);

  Widget get view => BlocBuilder<QuestionAnswerBloc, QuestionAnswerState>(
      bloc: answerBloc,
      builder: (context, answerState) => BlocBuilder<NextTaskBloc, NextTaskState>(
          builder: (context, state) => Column(children: [
                const SizedBox(height: 24),
                progressHeader,
                const SizedBox(height: 24),
                QuestionsCard(questionText: currentQuestion.title),
                const SizedBox(height: 20),
                if (currentAnswers.isNotEmpty)
                  ...optionsList
                else
                  Text('No answers available.',
                      style: Style.small3w4(context, color: TextColorRole.greyColor)),
                const SizedBox(height: 20),
                continueButton(state, answerState)
              ])));

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty)
      return Center(
          child: Text('No questions available.',
              style: Style.bodyw5(context, color: TextColorRole.greyColor)));

    return BlocListener<QuestionAnswerBloc, QuestionAnswerState>(
        bloc: answerBloc,
        listener: (context, state) {
          if (state.status.isError && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        child: view);
  }
}
