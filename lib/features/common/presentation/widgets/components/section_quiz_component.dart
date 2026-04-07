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
  final Widget Function(BuildContext context, bool isResultState, Color panelColor)? panelActionBuilder;
  const SectionQuizComponent(
      {super.key,
      required this.questions,
      required this.onFinish,
      this.headerWidget,
      this.panelActionBuilder});

  @override
  State<SectionQuizComponent> createState() => _SectionQuizComponentState();
}

class _SectionQuizComponentState extends State<SectionQuizComponent> {
  late List<SectionQuestionModel> questions;
  final QuestionAnswerBloc answerBloc = sl<QuestionAnswerBloc>();
  int questionIndex = 0;
  int correctCount = 0;
  bool hasSubmitted = false;
  bool showCorrectAnswer = false;

  int? selectedIndex;
  final Set<int> selectedIndices = {};
  final List<TextEditingController> blankControllers = [];
  final TextEditingController shortAnswerController = TextEditingController();

  /// --- Life cycle ---

  @override
  void initState() {
    questions = widget.questions;
    answerBloc.add(const QuestionAnswerReset());
    _syncQuestionState();
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
      _syncQuestionState();
    }
  }

  /// --- Getters ---
  SectionQuestionModel get currentQuestion => questions[questionIndex];
  List<SectionAnswerModel> get currentAnswers => currentQuestion.answers ?? [];
  String get questionType => currentQuestion.questionType.toLowerCase();
  bool get isReviewMode => currentQuestion.isAnswered == true;

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
      if (currentQuestion.userBlankAnswers.length > i) {
        controller.text = currentQuestion.userBlankAnswers[i].answer ?? '';
      }
      controller.addListener(_handleInputChanged);
      blankControllers.add(controller);
    }
  }

  void _syncQuestionState() {
    selectedIndex = null;
    selectedIndices.clear();
    hasSubmitted = isReviewMode;
    showCorrectAnswer = false;

    for (var i = 0; i < currentAnswers.length; i++) {
      if (!currentAnswers[i].userSelected) continue;
      if (isMultipleChoice) {
        selectedIndices.add(i);
      } else {
        selectedIndex = i;
      }
    }

    _resetBlankControllers();
    shortAnswerController.clear();
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
    if (hasSubmitted || isReviewMode) return;
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

  void submitCurrentAnswer() {
    if (!isReadyToSubmit) return;
    if (answerBloc.state.status.isLoading) return;
    if (isMultipleChoice) {
      final selectedAnswerIds = selectedIndices
          .map((index) => currentAnswers[index].id)
          .where((id) => id.isNotEmpty)
          .toList();
      if (selectedAnswerIds.isEmpty) return;
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
    _syncQuestionState();

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

  bool get hasResultForCurrentQuestion {
    final result = answerBloc.state.result;
    return result != null &&
        result.questionId.isNotEmpty &&
        result.questionId == currentQuestion.id;
  }

  Set<String> effectiveCorrectAnswerIds(QuestionAnswerState answerState) {
    if (isReviewMode) {
      return currentAnswers
          .where((answer) => answer.isCorrect)
          .map((answer) => answer.id)
          .where((id) => id.isNotEmpty)
          .toSet();
    }
    if (!hasResultForCurrentQuestion) return const {};
    final idsFromResult = <String>{...answerState.result?.correctAnswerIds ?? const []};
    final singleId = answerState.result?.correctAnswerId;
    if (singleId != null && singleId.isNotEmpty) idsFromResult.add(singleId);
    return idsFromResult;
  }

  bool isCorrectAnswerIndex(int index, QuestionAnswerState answerState) {
    final ids = effectiveCorrectAnswerIds(answerState);
    return ids.contains(currentAnswers[index].id);
  }

  bool get hasMalformedChoiceQuestion =>
      !isReviewMode &&
      (questionType == 'multiple-choice' || questionType == 'single-choice') &&
      currentAnswers.isNotEmpty &&
      currentAnswers.every((answer) => !answer.isCorrect);

  Color optionFillColor(BuildContext context, int index, QuestionAnswerState answerState) {
    if (!hasSubmitted) return context.cs.surface;
    if (!isSelectedIndex(index)) return context.cs.surface;
    if (isCorrectAnswerIndex(index, answerState)) return AppColors.primary;
    return AppColors.error;
  }

  Color optionBorderColor(BuildContext context, int index, QuestionAnswerState answerState) {
    if (!hasSubmitted && isSelectedIndex(index)) return AppColors.primary;
    if (showCorrectAnswer && isCorrectAnswerIndex(index, answerState)) return AppColors.orange033;
    return AppColors.transparent;
  }

  Color optionTextColor(BuildContext context, int index, QuestionAnswerState answerState) {
    final fill = optionFillColor(context, index, answerState);
    if (fill == AppColors.primary || fill == AppColors.error) return context.cs.onPrimary;
    if (showCorrectAnswer && isCorrectAnswerIndex(index, answerState)) return AppColors.orange033;
    return context.cs.onSurface;
  }

  Button optionItem(int index, QuestionAnswerState answerState) {
    final fill = optionFillColor(context, index, answerState);
    final isFilled = fill == AppColors.primary || fill == AppColors.error;
    final isCorrect = isCorrectAnswerIndex(index, answerState);
    final showCheck = hasSubmitted && showCorrectAnswer && isCorrect;
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
        borderColor: optionBorderColor(context, index, answerState),
        borderWidth: showCorrectAnswer && isCorrect ? 1.5 : 1,
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
                  readOnly: isReviewMode,
                  controller: blankControllers[index],
                  decoration: InputDecoration(
                      hintText: 'Blank {number}'.tr(namedArgs: {'number': '${index + 1}'}),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))))));

  Widget shortAnswerView() => TextField(
      controller: shortAnswerController,
      readOnly: isReviewMode,
      maxLines: 4,
      decoration: InputDecoration(
          hintText: 'Type your answer'.tr(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));

  bool get canRevealCorrectAnswer =>
      hasSubmitted &&
      !questionWasCorrect(answerBloc.state) &&
      currentAnswers.isNotEmpty &&
      effectiveCorrectAnswerIds(answerBloc.state).isNotEmpty &&
      !showCorrectAnswer;

  bool get isResultState => hasSubmitted || isReviewMode;

  bool questionWasCorrect(QuestionAnswerState answerState) {
    if (isReviewMode) {
      final correctIds = effectiveCorrectAnswerIds(answerState);
      if (correctIds.isEmpty) return false;
      final selectedIds = currentAnswers
          .where((answer) => answer.userSelected)
          .map((answer) => answer.id)
          .where((id) => id.isNotEmpty)
          .toSet();
      return selectedIds.isNotEmpty &&
          selectedIds.length == correctIds.length &&
          selectedIds.containsAll(correctIds);
    }
    return answerState.result?.questionId == currentQuestion.id && answerState.result?.isCorrect == true;
  }

  Color resultPanelColor(QuestionAnswerState answerState) =>
      questionWasCorrect(answerState) ? AppColors.primary : AppColors.error;

  Color resultPanelTextColor(BuildContext context) =>
      isResultState ? AppColors.white : context.cs.onSurface;

  IconData resultPanelIcon(QuestionAnswerState answerState) =>
      questionWasCorrect(answerState) ? Icons.check_circle_rounded : Icons.error_outline_rounded;

  String resultPanelTitle(QuestionAnswerState answerState) =>
      questionWasCorrect(answerState) ? 'Your answer was correct'.tr() : 'Your answer was incorrect'.tr();

  String? resultPanelSubtitle(QuestionAnswerState answerState) {
    if (!isResultState) {
      return isReadyToSubmit
          ? 'Tap submit to check your answer.'.tr()
          : 'Choose an answer to continue.'.tr();
    }
    if (questionWasCorrect(answerState)) {
      return 'Tap continue to move to the next question.'.tr();
    }
    if (showCorrectAnswer && effectiveCorrectAnswerIds(answerState).isNotEmpty) {
      return 'The correct answer is now marked for review.'.tr();
    }
    if (canRevealCorrectAnswer) {
      return 'Tap the eye button to view the correct answer.'.tr();
    }
    return null;
  }

  Widget showAnswerButton(QuestionAnswerState answerState) => Button.border(
      onTap: () => setState(() => showCorrectAnswer = true),
      height: 52,
      color: AppColors.white,
      borderColor: isResultState
          ? AppColors.white.withValues(alpha: 0.75)
          : AppColors.orange033.withValues(alpha: 0.35),
      child: Icon(Icons.visibility_rounded,
          size: 20,
          color: isResultState ? resultPanelColor(answerState) : AppColors.orange033));

  Widget submitButton(QuestionAnswerState answerState) {
    final canSubmit = hasSubmitted ? true : isReadyToSubmit;
    final label = hasSubmitted || isReviewMode ? 'Continue' : 'Submit';
    return Button.primary(
        onTap: hasSubmitted || isReviewMode ? goNextQuestion : submitCurrentAnswer,
        text: label.tr(),
        color: isResultState ? AppColors.white : null,
        textColor: isResultState ? resultPanelColor(answerState) : null,
        isLoading: !isReviewMode && answerState.status.isLoading,
        isAvialable: canSubmit);
  }

  Widget actionButtons(QuestionAnswerState answerState) {
    if (!canRevealCorrectAnswer) return submitButton(answerState);
    return Row(children: [
      SizedBox(width: 84, child: showAnswerButton(answerState)),
      const SizedBox(width: 12),
      Expanded(child: submitButton(answerState))
    ]);
  }

  Widget bottomResultPanel(BuildContext context, QuestionAnswerState answerState) {
    final panelColor = isResultState ? resultPanelColor(answerState) : AppColors.white;
    final subtitle = resultPanelSubtitle(answerState);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final textColor = resultPanelTextColor(context);
    final panelAction = widget.panelActionBuilder?.call(context, isResultState, panelColor);
    return SizedBox(
        width: double.infinity,
        child: Container(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 20 + bottomInset),
            decoration: BoxDecoration(
                color: panelColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  height: 72,
                  child: isResultState
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Icon(resultPanelIcon(answerState), color: textColor, size: 26),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(resultPanelTitle(answerState),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Style.body2w6(context).copyWith(color: textColor))),
                            if (panelAction != null) ...[
                              const SizedBox(width: 12),
                              panelAction,
                            ]
                          ]),
                          const SizedBox(height: 10),
                          Expanded(
                              child: Text(subtitle ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Style.bodyw4(context)
                                      .copyWith(color: AppColors.white.withValues(alpha: 0.92))))
                        ])
                      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(subtitle ?? '',
                                      style: Style.bodyw4(context).copyWith(color: textColor)))),
                          if (panelAction != null) ...[
                            const SizedBox(width: 12),
                            panelAction,
                          ]
                        ])),
              const SizedBox(height: 18),
              actionButtons(answerState)
            ])));
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

  Widget scrollContent(QuestionAnswerState answerState, double bottomSpacerHeight) => ListView(
      padding: EdgeInsets.only(bottom: bottomSpacerHeight),
      physics: const ClampingScrollPhysics(),
      children: [
        Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(children: [
              const SizedBox(height: 24),
              progressHeader,
              const SizedBox(height: 24),
              ...isShownHeaderWidget,
              QuestionsCard(currentQuestion: currentQuestion),
              const SizedBox(height: 20),
              // if (hasMalformedChoiceQuestion) ...[
              //   malformedQuestionWarning(context),
              //   const SizedBox(height: 12),
              // ],
              if (isFillBlank)
                fillBlankView()
              else if (isShortAnswer)
                shortAnswerView()
              else if (currentAnswers.isNotEmpty)
                ...optionsList(answerState)
              else
                Text('No answers available.'.tr(),
                    style: Style.small3w4(context, color: TextColorRole.greyColor)),
            ]))
      ]);

  Widget get view => LayoutBuilder(
      builder: (context, constraints) => BlocBuilder<QuestionAnswerBloc, QuestionAnswerState>(
          bloc: answerBloc,
          builder: (context, answerState) {
            final panelHeight = 210.0 + MediaQuery.of(context).padding.bottom;
            return Stack(children: [
              Positioned.fill(child: scrollContent(answerState, panelHeight + 16)),
              Positioned(left: 0, right: 0, bottom: 0, child: bottomResultPanel(context, answerState))
            ]);
          }));

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
              if (state.result?.questionId == currentQuestion.id &&
                  state.result?.isCorrect == true) {
                correctCount++;
              }
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
