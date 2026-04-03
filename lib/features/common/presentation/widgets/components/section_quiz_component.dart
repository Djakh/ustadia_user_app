import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_answer_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_question_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_state.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/cards/quiz_card.dart';
import 'package:ustadia_user_app/injection_container.dart';

class SectionQuizComponent extends StatefulWidget {
  final List<SectionQuestionModel> questions;
  final ValueChanged<int> onFinish;
  final Widget? headerWidget;
  const SectionQuizComponent(
      {super.key, required this.questions, required this.onFinish, this.headerWidget});

  @override
  State<SectionQuizComponent> createState() => _SectionQuizComponentState();
}

class _SectionQuizComponentState extends State<SectionQuizComponent> {
  late List<SectionQuestionModel> questions;
  final QuestionAnswerBloc answerBloc = sl<QuestionAnswerBloc>();
  int questionIndex = 0;
  int correctCount = 0;
  bool hasSubmitted = false;
  bool? submitWasCorrect;

  int? selectedIndex;
  final Set<int> selectedIndices = {};
  final List<TextEditingController> blankControllers = [];
  final TextEditingController shortAnswerController = TextEditingController();

  /// --- Life cycle ---

  @override
  void initState() {
    questions = widget.questions;
    answerBloc.add(const QuestionAnswerReset());
    _resetBlankControllers();
    shortAnswerController.addListener(_handleInputChanged);
    super.initState();
  }

  @override
  void dispose() {
    for (final controller in blankControllers) {
      controller.dispose();
    }
    shortAnswerController.dispose();
    answerBloc.close();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SectionQuizComponent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.questions != widget.questions) {
      answerBloc.add(const QuestionAnswerReset());
      questions = widget.questions;
      questionIndex = 0;
      correctCount = 0;
      hasSubmitted = false;
      submitWasCorrect = null;
      selectedIndex = null;
      selectedIndices.clear();
      _resetBlankControllers();
      shortAnswerController.clear();
    }
  }

  /// --- Getters ---
  SectionQuestionModel get currentQuestion => questions[questionIndex];
  List<SectionAnswerModel> get currentAnswers => currentQuestion.answers ?? [];
  String get questionType => currentQuestion.questionType.toLowerCase();

  bool get isMultipleChoice => questionType == 'multiple-choice';
  bool get isShortAnswer => questionType == 'short-answer';
  bool get isFillBlank => questionType == 'fill-blank';
  int get maxSelectionLimit => (currentQuestion.maxSelections ?? 0) > 0
      ? currentQuestion.maxSelections!
      : currentAnswers.length;

  int get blanksCount => currentQuestion.numberOfBlanks > 0
      ? currentQuestion.numberOfBlanks
      : currentQuestion.blankAnswers.length;

  /// --- Methods ---

  void _resetBlankControllers() {
    for (final controller in blankControllers) {
      controller.dispose();
    }
    blankControllers.clear();
    if (!isFillBlank) return;
    final count = blanksCount;
    for (var i = 0; i < count; i++) {
      final controller = TextEditingController();
      controller.addListener(_handleInputChanged);
      blankControllers.add(controller);
    }
  }

  void _handleInputChanged() {
    if (isFillBlank) {
      setState(() {});
      return;
    }
    if (isShortAnswer) {
      setState(() {});
      return;
    }
  }

  void onSelectAnswerOption(int index) {
    if (hasSubmitted) return;
    if (answerBloc.state.status.isLoading) return;
    if (currentAnswers.isEmpty) return;
    if (isMultipleChoice) {
      if (selectedIndices.contains(index)) {
        selectedIndices.remove(index);
      } else {
        if (selectedIndices.length >= maxSelectionLimit) return;
        selectedIndices.add(index);
      }
      setState(() {});
      return;
    }

    selectedIndex = index;
    setState(() {});
  }

  bool get isReadyToSubmit {
    if (isFillBlank) return blankControllers.every((c) => c.text.trim().isNotEmpty);
    if (isShortAnswer) return shortAnswerController.text.trim().isNotEmpty;
    if (isMultipleChoice) return selectedIndices.isNotEmpty;
    return selectedIndex != null;
  }

  bool evaluateMultipleChoiceCorrect(List<String> selectedAnswerIds) {
    final correctIds = currentAnswers.where((a) => a.isCorrect).map((a) => a.id).toSet();
    final selectedSet = selectedAnswerIds.toSet();
    return correctIds.isNotEmpty &&
        selectedSet.length == correctIds.length &&
        selectedSet.containsAll(correctIds);
  }

  void submitCurrentAnswer() {
    if (!isReadyToSubmit) return;
    if (answerBloc.state.status.isLoading) return;
    submitWasCorrect = null;
    if (isMultipleChoice) {
      final selectedAnswerIds = selectedIndices
          .map((index) => currentAnswers[index].id)
          .where((id) => id.isNotEmpty)
          .toList();
      if (selectedAnswerIds.isEmpty) return;
      submitWasCorrect = evaluateMultipleChoiceCorrect(selectedAnswerIds);
      answerBloc.add(QuestionAnswerSubmitted(
          sectionId: currentQuestion.sectionId,
          questionId: currentQuestion.id,
          answerIds: selectedAnswerIds,
          assignmentId: currentQuestion.assignmentId,
          unitId: currentQuestion.unitId,
          lessonId: currentQuestion.lessonId,
          source: currentQuestion.source));
    } else if (isFillBlank) {
      final blanks = blankControllers
          .asMap()
          .entries
          .map((entry) =>
              SectionBlankAnswer(position: entry.key + 1, answer: entry.value.text.trim()))
          .toList();
      if (blanks.any((item) => item.answer == null || item.answer!.isEmpty)) return;
      answerBloc.add(QuestionAnswerSubmitted(
          sectionId: currentQuestion.sectionId,
          questionId: currentQuestion.id,
          blankAnswers: blanks,
          assignmentId: currentQuestion.assignmentId,
          unitId: currentQuestion.unitId,
          lessonId: currentQuestion.lessonId,
          source: currentQuestion.source));
    } else if (isShortAnswer) {
      final text = shortAnswerController.text.trim();
      if (text.isEmpty) return;
      answerBloc.add(QuestionAnswerSubmitted(
          sectionId: currentQuestion.sectionId,
          questionId: currentQuestion.id,
          userInputText: text,
          assignmentId: currentQuestion.assignmentId,
          unitId: currentQuestion.unitId,
          lessonId: currentQuestion.lessonId,
          source: currentQuestion.source));
    } else if (selectedIndex != null && currentAnswers.isNotEmpty) {
      submitWasCorrect = currentAnswers[selectedIndex!].isCorrect;
      answerBloc.add(QuestionAnswerSubmitted(
          sectionId: currentQuestion.sectionId,
          questionId: currentQuestion.id,
          answerId: currentAnswers[selectedIndex!].id,
          answerIds: const [],
          assignmentId: currentQuestion.assignmentId,
          unitId: currentQuestion.unitId,
          lessonId: currentQuestion.lessonId,
          source: currentQuestion.source));
    }
  }

  void goNextQuestion() {
    if (questionIndex == questions.length - 1) return widget.onFinish(correctCount);

    answerBloc.add(const QuestionAnswerReset());
    questionIndex++;
    selectedIndex = null;
    selectedIndices.clear();
    _resetBlankControllers();
    shortAnswerController.clear();
    hasSubmitted = false;
    submitWasCorrect = null;

    setState(() {});
  }

  /// --- Widgets ---

  Widget get indicator =>
      PageIndicator(currentIndex: questionIndex, total: questions.length, isExpanded: true);

  Row get progressHeaderInfo => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('{current} Question'.tr(namedArgs: {'current': '${questionIndex + 1}'}),
            style: Style.small2w4(context, color: TextColorRole.greyColor)),
        Text('Total {total} Questions'.tr(namedArgs: {'total': '${questions.length}'}),
            style: Style.small2w4(context))
      ]);

  Widget get progressHeader =>
      Column(children: [indicator, const SizedBox(height: 4), progressHeaderInfo]);

  List<Widget> get isShownHeaderWidget => widget.headerWidget != null
      ? [
          widget.headerWidget!,
          const SizedBox(height: 24),
        ]
      : [];

  bool isSelectedIndex(int index) =>
      isMultipleChoice ? selectedIndices.contains(index) : selectedIndex == index;

  Set<String> effectiveCorrectAnswerIds(QuestionAnswerState answerState) {
    final idsFromQuestion = currentAnswers.where((a) => a.isCorrect).map((a) => a.id).toSet();
    if (idsFromQuestion.isNotEmpty) return idsFromQuestion;
    final idsFromResult = <String>{...answerState.result?.correctAnswerIds ?? const []};
    final singleId = answerState.result?.correctAnswerId;
    if (singleId != null && singleId.isNotEmpty) idsFromResult.add(singleId);
    return idsFromResult;
  }

  bool isCorrectAnswerIndex(int index, QuestionAnswerState answerState) {
    final ids = effectiveCorrectAnswerIds(answerState);
    if (ids.isNotEmpty) return ids.contains(currentAnswers[index].id);
    return currentAnswers[index].isCorrect;
  }

  bool get hasMalformedChoiceQuestion {
    if (isFillBlank || isShortAnswer || currentAnswers.isEmpty) return false;
    return currentAnswers.every((answer) => !answer.isCorrect);
  }

  Color optionFillColor(BuildContext context, int index, QuestionAnswerState answerState) {
    if (!hasSubmitted) return context.cs.surface;
    if (!isSelectedIndex(index)) return context.cs.surface;
    if (isCorrectAnswerIndex(index, answerState)) return AppColors.primary;
    return AppColors.error;
  }

  Color optionTextColor(BuildContext context, int index, QuestionAnswerState answerState) {
    final fill = optionFillColor(context, index, answerState);
    if (fill == AppColors.primary || fill == AppColors.error) return context.cs.onPrimary;
    return context.cs.onSurface;
  }

  Button optionItem(int index, QuestionAnswerState answerState) {
    final fill = optionFillColor(context, index, answerState);
    final isFilled = fill == AppColors.primary || fill == AppColors.error;
    final isCorrect = isCorrectAnswerIndex(index, answerState);
    final showCheck = hasSubmitted && isCorrect;
    final checkColor = isFilled ? AppColors.white : AppColors.primary;
    final label = Stack(alignment: Alignment.center, children: [
      Text(currentAnswers[index].answerText,
          style:
              Style.bodyw5(context).copyWith(color: optionTextColor(context, index, answerState)),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis),
      if (showCheck)
        Align(
            alignment: Alignment.centerRight, child: Icon(Icons.check, size: 18, color: checkColor))
    ]);
    if (isFilled) {
      return Button.primary(onTap: () => onSelectAnswerOption(index), color: fill, child: label);
    }
    return Button.border(
        onTap: () => onSelectAnswerOption(index),
        color: context.cs.surface,
        borderColor:
            !hasSubmitted && isSelectedIndex(index) ? AppColors.primary : AppColors.transparent,
        child: label);
  }

  List<Widget> optionsList(QuestionAnswerState answerState) => List.generate(
      currentAnswers.length,
      (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: optionItem(index, answerState),
          ));

  Widget fillBlankView() => Column(
      children: List.generate(
          blankControllers.length,
          (index) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TextField(
                  controller: blankControllers[index],
                  decoration: InputDecoration(
                      hintText: 'Blank {number}'.tr(namedArgs: {'number': '${index + 1}'}),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))))));

  Widget shortAnswerView() => TextField(
      controller: shortAnswerController,
      maxLines: 4,
      decoration: InputDecoration(
          hintText: 'Type your answer'.tr(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));

  Widget submitButton(QuestionAnswerState answerState) {
    final canSubmit = hasSubmitted ? true : isReadyToSubmit;
    final label = hasSubmitted ? 'Continue' : 'Submit';
    return Button.primary(
        onTap: hasSubmitted ? goNextQuestion : submitCurrentAnswer,
        text: label.tr(),
        isAvialable: canSubmit && !answerState.status.isLoading);
  }

  Widget malformedQuestionWarning(BuildContext context) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AppColors.redE2,
          borderRadius: Style.border12,
          border: Border.all(color: AppColors.error.withValues(alpha: 0.25))),
      child: Text('Question data is incomplete. No correct answer was provided by the server.'.tr(),
          style: Style.small3w4(context).copyWith(color: AppColors.error)));

  Widget get view => BlocBuilder<QuestionAnswerBloc, QuestionAnswerState>(
      bloc: answerBloc,
      builder: (context, answerState) => Column(children: [
            const SizedBox(height: 24),
            progressHeader,
            const SizedBox(height: 24),
            ...isShownHeaderWidget,
            QuestionsCard(currentQuestion: currentQuestion),
            const SizedBox(height: 20),
            if (hasMalformedChoiceQuestion) ...[
              malformedQuestionWarning(context),
              const SizedBox(height: 12),
            ],
            if (isFillBlank)
              fillBlankView()
            else if (isShortAnswer)
              shortAnswerView()
            else if (currentAnswers.isNotEmpty)
              ...optionsList(answerState)
            else
              Text('No answers available.'.tr(),
                  style: Style.small3w4(context, color: TextColorRole.greyColor)),
            const SizedBox(height: 20),
            submitButton(answerState)
          ]));

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty)
      return Center(
          child: Text('No questions available.'.tr(),
              style: Style.bodyw5(context, color: TextColorRole.greyColor)));

    return BlocListener<QuestionAnswerBloc, QuestionAnswerState>(
        bloc: answerBloc,
        listener: (context, state) {
          if (state.status.isSuccess) {
            if (!hasSubmitted) {
              final backendWasCorrect = state.result?.isCorrect;
              if ((backendWasCorrect ?? submitWasCorrect) == true) correctCount++;
              hasSubmitted = true;
              setState(() {});
            }
            return;
          }
          if (state.status.isError && state.errorMessage != null) {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
          }
        },
        child: view);
  }
}
