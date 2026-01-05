import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/cubit/next_task_bloc.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_quiz_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/learn_listening_quiz_card.dart';

class LearnQuizComponent extends StatefulWidget {
  final List<LearnQuizModel> learnQuizModels;
  final ValueChanged<int> onFinish;
  const LearnQuizComponent({super.key, required this.learnQuizModels, required this.onFinish});

  @override
  State<LearnQuizComponent> createState() => _LearnQuizComponentState();
}

class _LearnQuizComponentState extends State<LearnQuizComponent> {
  late final List<LearnQuizModel> learnQuizModel;
  int questionIndex = 0;
  int correctCount = 0;

  int? selectedIndex;

  /// --- Life cycle ---

  @override
  void initState() {
    learnQuizModel = widget.learnQuizModels;
    context.read<NextTaskBloc>().setCurrentTaskCompleted(false);

    super.initState();
  }

  /// --- Getters ---
  LearnQuizModel get currentLearnQuizModel => learnQuizModel[questionIndex];

  /// --- Methods ---

  void onSelectAnswerOption(int index) {
    final bloc = context.read<NextTaskBloc>();
    if (bloc.state.isCurrentTaskCompleted) return;
    selectedIndex = index;
    bool isAnswerCorrect = index == currentLearnQuizModel.correctIndex;
    bloc.setCurrentTaskCompleted(true, isAnswerCorrect: isAnswerCorrect);
    if (isAnswerCorrect) correctCount++;
  }

  void continueAfterAnswer() {
    context.read<NextTaskBloc>().setCurrentTaskCompleted(false);

    if (questionIndex == learnQuizModel.length - 1) return widget.onFinish(correctCount);

    questionIndex++;
    selectedIndex = null;

    setState(() {});
  }

  /// --- Widgets ---

  Widget get indicator =>
      PageIndicator(currentIndex: questionIndex, total: learnQuizModel.length, isExpanded: true);

  Row get progressHeaderInfo => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('${questionIndex + 1} Question',
            style: Style.small2w4(context, color: TextColorRole.greyColor)),
        Text('Total ${learnQuizModel.length} Questions', style: Style.small2w4(context))
      ]);

  Widget get progressHeader =>
      Column(children: [indicator, const SizedBox(height: 4), progressHeaderInfo]);

  /// --- Widgets ---

  Color optionColor(BuildContext context, int index) {
    if (selectedIndex == null) return context.cs.surface;
    if (index == currentLearnQuizModel.correctIndex) return context.cs.primary;
    if (selectedIndex == index && index != currentLearnQuizModel.correctIndex) {
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
      text: currentLearnQuizModel.options[index]);

  List<Widget> get optionsList => List.generate(
      currentLearnQuizModel.options.length,
      (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: optionItem(index),
          ));

  Widget continueButton(NextTaskState state) => Button.primary(
      onTap: continueAfterAnswer, text: 'Continue', isAvialable: state.isCurrentTaskCompleted);

  Widget get view => BlocBuilder<NextTaskBloc, NextTaskState>(
      builder: (context, state) => Column(children: [
            const SizedBox(height: 24),
            progressHeader,
            const SizedBox(height: 24),
            LearnQuestionsCard(questionText: currentLearnQuizModel.prompt),
            const SizedBox(height: 20),
            ...optionsList,
            const SizedBox(height: 20),
            continueButton(state)
          ]));

  @override
  Widget build(BuildContext context) => view;
}
