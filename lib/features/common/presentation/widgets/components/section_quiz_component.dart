import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_storage_service.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_answer_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_question_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_state.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/cards/quiz_card.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_answer_evidence_view.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_question_answer_result_model.dart';
import 'package:ustadia_user_app/features/mock_exam/data/datasources/mock_exam_remote_data_source.dart';
import 'package:ustadia_user_app/injection_container.dart';

class _QuizQuestionDraft {
  final int? selectedIndex;
  final Set<int> selectedIndices;
  final List<String> blankAnswers;
  final String shortAnswer;
  final bool showCorrectAnswer;

  const _QuizQuestionDraft({
    required this.selectedIndex,
    required this.selectedIndices,
    required this.blankAnswers,
    required this.shortAnswer,
    required this.showCorrectAnswer,
  });
}

class SectionQuizComponent extends StatefulWidget {
  final List<SectionQuestionModel> questions;
  final ValueChanged<int> onFinish;
  final String sectionContent;
  final String? sectionType;
  final Widget? headerWidget;
  final Widget Function(BuildContext context, bool isResultState, Color panelColor)?
      panelActionBuilder;
  const SectionQuizComponent(
      {super.key,
      required this.questions,
      required this.onFinish,
      this.sectionContent = '',
      this.sectionType,
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
  bool isQuestionsOverviewVisible = false;
  OverlayEntry? questionsOverviewEntry;
  final Set<String> submittedQuestionIds = {};
  final Map<String, _QuizQuestionDraft> questionDrafts = {};
  final Map<String, LearnQuestionAnswerResultModel> questionResults = {};
  final GlobalKey quizProgressKey = GlobalKey(debugLabel: 'quiz_progress');
  final GlobalKey questionListButtonKey = GlobalKey(debugLabel: 'quiz_question_list_button');
  final GlobalKey questionCardKey = GlobalKey(debugLabel: 'quiz_question_card');
  final GlobalKey answerAreaKey = GlobalKey(debugLabel: 'quiz_answer_area');
  final GlobalKey bottomPanelKey = GlobalKey(debugLabel: 'quiz_bottom_panel');
  final GlobalKey panelActionKey = GlobalKey(debugLabel: 'quiz_panel_action');
  final GlobalKey submitButtonKey = GlobalKey(debugLabel: 'quiz_submit_button');
  final GlobalKey previousButtonKey = GlobalKey(debugLabel: 'quiz_previous_button');
  final GlobalKey nextButtonKey = GlobalKey(debugLabel: 'quiz_next_button');

  int? selectedIndex;
  final Set<int> selectedIndices = {};
  final List<TextEditingController> blankControllers = [];
  final TextEditingController shortAnswerController = TextEditingController();

  /// --- Life cycle ---

  @override
  void initState() {
    questions = widget.questions;
    answerBloc.add(const QuestionAnswerReset());
    _syncSubmittedQuestions();
    if (questions.isNotEmpty) _syncQuestionState();
    shortAnswerController.addListener(_handleInputChanged);
    super.initState();
  }

  @override
  void dispose() {
    questionsOverviewEntry?.remove();
    questionsOverviewEntry = null;
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
      closeQuestionsOverview();
      questionDrafts.clear();
      questionResults.clear();
      _syncSubmittedQuestions();
      if (questions.isNotEmpty) _syncQuestionState();
    }
  }

  /// --- Getters ---
  SectionQuestionModel get currentQuestion => questions[questionIndex];
  List<SectionAnswerModel> get currentAnswers => currentQuestion.answers ?? [];
  String get questionType => currentQuestion.questionType.toLowerCase();
  bool get isReviewMode => currentQuestion.isAnswered == true;
  bool get isMockExam => currentQuestion.source == SectionSource.mockExam;

  bool get isMultipleChoice => questionType == 'multiple-choice';
  bool get isShortAnswer => questionType == 'short-answer';
  bool get isFillBlank =>
      questionType == 'fill-blank' ||
      questionType == 'fill_blank' ||
      questionType == 'fill-in-blank';
  int get maxSelectionLimit => (currentQuestion.maxSelections ?? 0) > 0
      ? currentQuestion.maxSelections!
      : currentAnswers.length;

  int get blanksCount => currentQuestion.numberOfBlanks > 0
      ? currentQuestion.numberOfBlanks
      : currentQuestion.blankAnswers.length;
  bool get isFirstQuestion => questionIndex == 0;
  bool get isLastQuestion => questionIndex == questions.length - 1;
  int get submittedCount => questions.where((question) => isQuestionSubmitted(question)).length;
  bool get allQuestionsSubmitted => questions.isNotEmpty && submittedCount == questions.length;
  int get unsubmittedCount => questions.length - submittedCount;

  /// --- Methods ---

  void _syncSubmittedQuestions() {
    submittedQuestionIds
      ..clear()
      ..addAll(questions
          .where((question) => question.isAnswered == true)
          .map((question) => question.id)
          .where((id) => id.isNotEmpty));
  }

  bool isQuestionSubmitted(SectionQuestionModel question) =>
      question.isAnswered == true || submittedQuestionIds.contains(question.id);

  LearnQuestionAnswerResultModel? currentQuestionResult(QuestionAnswerState answerState) {
    final result = answerState.result;
    if (result != null && result.questionId == currentQuestion.id) return result;
    return questionResults[currentQuestion.id];
  }

  void _saveCurrentQuestionState() {
    if (questions.isEmpty || currentQuestion.id.isEmpty) return;
    questionDrafts[currentQuestion.id] = _QuizQuestionDraft(
        selectedIndex: selectedIndex,
        selectedIndices: Set<int>.from(selectedIndices),
        blankAnswers: blankControllers.map((controller) => controller.text).toList(),
        shortAnswer: shortAnswerController.text,
        showCorrectAnswer: showCorrectAnswer);
  }

  void _resetBlankControllers([List<String>? draftAnswers]) {
    for (final controller in blankControllers) {
      controller.dispose();
    }
    blankControllers.clear();
    if (!isFillBlank) return;
    final count = blanksCount;
    for (var i = 0; i < count; i++) {
      final controller = TextEditingController();
      if (draftAnswers != null && draftAnswers.length > i) {
        controller.text = draftAnswers[i];
      } else if (currentQuestion.userBlankAnswers.length > i) {
        controller.text = currentQuestion.userBlankAnswers[i].answer ?? '';
      }
      controller.addListener(_handleInputChanged);
      blankControllers.add(controller);
    }
  }

  void _syncQuestionState() {
    if (questions.isEmpty) {
      selectedIndex = null;
      selectedIndices.clear();
      hasSubmitted = false;
      showCorrectAnswer = false;
      _resetBlankControllers();
      shortAnswerController.clear();
      return;
    }
    selectedIndex = null;
    selectedIndices.clear();
    final draft = questionDrafts[currentQuestion.id];
    hasSubmitted = isQuestionSubmitted(currentQuestion);
    showCorrectAnswer = draft?.showCorrectAnswer ?? false;

    if (draft != null) {
      selectedIndex = draft.selectedIndex;
      selectedIndices.addAll(draft.selectedIndices);
    } else {
      for (var i = 0; i < currentAnswers.length; i++) {
        if (!currentAnswers[i].userSelected) continue;
        if (isMultipleChoice) {
          selectedIndices.add(i);
        } else {
          selectedIndex = i;
        }
      }
    }

    _resetBlankControllers(draft?.blankAnswers);
    shortAnswerController.text = draft?.shortAnswer ?? '';
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
    _saveCurrentQuestionState();
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
          mockExamId: currentQuestion.mockExamId,
          mockAttemptId: currentQuestion.mockAttemptId,
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
          mockExamId: currentQuestion.mockExamId,
          mockAttemptId: currentQuestion.mockAttemptId,
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
          mockExamId: currentQuestion.mockExamId,
          mockAttemptId: currentQuestion.mockAttemptId,
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
          mockExamId: currentQuestion.mockExamId,
          mockAttemptId: currentQuestion.mockAttemptId,
          unitId: currentQuestion.unitId,
          lessonId: currentQuestion.lessonId,
          source: currentQuestion.source));
    }
  }

  Future<void> finishMockExamSectionIfNeeded() async {
    if (currentQuestion.source != SectionSource.mockExam) return;
    final mockExamId = currentQuestion.mockExamId;
    final attemptId = currentQuestion.mockAttemptId;
    if (mockExamId == null || mockExamId.isEmpty || attemptId == null || attemptId.isEmpty) return;
    try {
      await sl<MockExamRemoteDataSource>().finishMockExamSection(
          mockExamId: mockExamId, attemptId: attemptId, sectionId: currentQuestion.sectionId);
    } catch (_) {}
  }

  Future<void> goNextQuestion() async {
    if (answerBloc.state.status.isLoading) return;
    if (isLastQuestion) {
      return finishQuizIfComplete();
    }

    goToQuestion(questionIndex + 1);
  }

  Future<void> finishQuizIfComplete() async {
    if (!allQuestionsSubmitted) {
      openQuestionsOverview();
      return;
    }
    await finishMockExamSectionIfNeeded();
    return widget.onFinish(correctCount);
  }

  void goPreviousQuestion() {
    if (answerBloc.state.status.isLoading || isFirstQuestion) return;
    goToQuestion(questionIndex - 1);
  }

  void goToQuestion(int index, {bool closeQuestionsOverview = false}) {
    if (answerBloc.state.status.isLoading) return;
    if (index < 0 || index >= questions.length) return;
    _saveCurrentQuestionState();
    answerBloc.add(const QuestionAnswerReset());
    questionIndex = index;
    _syncQuestionState();
    if (closeQuestionsOverview) {
      this.closeQuestionsOverview();
      return;
    }
    setState(() {});
  }

  void openQuestionsOverview() {
    if (answerBloc.state.status.isLoading) return;
    _saveCurrentQuestionState();
    questionsOverviewEntry ??= OverlayEntry(builder: questionsOverviewOverlay);
    if (!questionsOverviewEntry!.mounted) {
      Overlay.of(context, rootOverlay: true).insert(questionsOverviewEntry!);
    }
    questionsOverviewEntry?.markNeedsBuild();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || questionsOverviewEntry == null) return;
      setState(() => isQuestionsOverviewVisible = true);
      questionsOverviewEntry?.markNeedsBuild();
    });
  }

  void closeQuestionsOverview() {
    if (!isQuestionsOverviewVisible) return;
    setState(() => isQuestionsOverviewVisible = false);
    questionsOverviewEntry?.markNeedsBuild();
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted || isQuestionsOverviewVisible) return;
      questionsOverviewEntry?.remove();
      questionsOverviewEntry = null;
    });
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

  Widget get quizTopBar => Align(
      alignment: Alignment.centerLeft,
      child: Padding(
          padding: const EdgeInsets.only(right: 128),
          child: Text(
              'Answered {count} of {total}'
                  .tr(namedArgs: {'count': '$submittedCount', 'total': '${questions.length}'}),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Style.small2w5(context).copyWith(color: AppColors.gray500))));

  Widget get questionsOverviewButton => Material(
      key: questionListButtonKey,
      color: Colors.transparent,
      child: InkWell(
          onTap: openQuestionsOverview,
          borderRadius: Style.border16,
          child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: Style.border16,
                  border: Border.all(color: AppColors.gray300)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.fact_check_rounded, size: 18),
                const SizedBox(width: 6),
                Text('Questions'.tr(), style: Style.small2w5(context))
              ]))));

  List<Widget> get isShownHeaderWidget => widget.headerWidget != null
      ? [
          widget.headerWidget!,
          const SizedBox(height: 24),
        ]
      : [];

  bool isSelectedIndex(int index) =>
      isMultipleChoice ? selectedIndices.contains(index) : selectedIndex == index;

  bool get hasResultForCurrentQuestion {
    final result = currentQuestionResult(answerBloc.state);
    return result != null &&
        result.questionId.isNotEmpty &&
        result.questionId == currentQuestion.id;
  }

  Set<String> effectiveCorrectAnswerIds(QuestionAnswerState answerState) {
    final localCorrectIds = currentAnswers
        .where((answer) => answer.isCorrect)
        .map((answer) => answer.id)
        .where((id) => id.isNotEmpty)
        .toSet();
    if (isReviewMode) return localCorrectIds;
    final result = currentQuestionResult(answerState);
    if (result == null || result.questionId != currentQuestion.id) {
      return hasSubmitted ? localCorrectIds : const {};
    }
    final idsFromResult = <String>{...result.correctAnswerIds};
    final singleId = result.correctAnswerId;
    if (singleId != null && singleId.isNotEmpty) idsFromResult.add(singleId);
    return idsFromResult.isEmpty && hasSubmitted ? localCorrectIds : idsFromResult;
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

  SectionAnswerModel? currentEvidenceAnswer(QuestionAnswerState answerState) {
    final correctIds = effectiveCorrectAnswerIds(answerState);
    for (final answer in currentAnswers) {
      if (answer.hasAnswerEvidence) return answer;
      if (correctIds.contains(answer.id) && answer.hasAnswerEvidenceData) return answer;
    }
    if (!hasSubmitted) return null;
    for (final answer in currentAnswers) {
      if (answer.hasAnswerEvidenceData) return answer;
    }
    return null;
  }

  bool hasCurrentAnswerEvidence(QuestionAnswerState answerState) {
    final answer = currentEvidenceAnswer(answerState);
    if (answer == null) return false;
    if (answer.hasAudioEvidenceData) return true;
    return answer.hasEvidenceRangeData && widget.sectionContent.isNotEmpty;
  }

  List<SectionBlankAnswer> effectiveCorrectBlankAnswers(QuestionAnswerState answerState) {
    final result = currentQuestionResult(answerState);
    final resultAnswers = result?.correctBlankAnswers
            .map((item) => SectionBlankAnswer(position: item.position, answer: item.answer))
            .where((item) => item.answer?.trim().isNotEmpty == true)
            .toList() ??
        const <SectionBlankAnswer>[];
    if (resultAnswers.isNotEmpty) return resultAnswers;
    return currentQuestion.blankAnswers
        .where((item) => item.answer?.trim().isNotEmpty == true)
        .toList();
  }

  bool get hasCorrectBlankAnswers =>
      isFillBlank && effectiveCorrectBlankAnswers(answerBloc.state).isNotEmpty;

  Color optionFillColor(BuildContext context, int index, QuestionAnswerState answerState) {
    if (!hasSubmitted) return context.cs.surface;
    if (!isSelectedIndex(index)) return context.cs.surface;
    if (isMockExam) return context.cs.surface;
    if (isCorrectAnswerIndex(index, answerState)) return AppColors.primary;
    return AppColors.error;
  }

  Color optionBorderColor(BuildContext context, int index, QuestionAnswerState answerState) {
    if (!hasSubmitted && isSelectedIndex(index)) return AppColors.primary;
    if (isMockExam && isSelectedIndex(index)) return AppColors.primary;
    if (isMockExam) return AppColors.transparent;
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
        borderWidth: isSelectedIndex(index) || showCorrectAnswer && isCorrect ? 1.5 : 1,
        child: label);
  }

  List<Widget> optionsList(QuestionAnswerState answerState) => List.generate(
      currentAnswers.length,
      (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: optionItem(index, answerState),
          ));

  Widget answerInputArea(QuestionAnswerState answerState) => KeyedSubtree(
      key: answerAreaKey,
      child: Column(children: [
        if (isFillBlank)
          fillBlankView()
        else if (isShortAnswer)
          shortAnswerView()
        else if (currentAnswers.isNotEmpty)
          ...optionsList(answerState)
        else
          Text('No answers available.'.tr(),
              style: Style.small3w4(context, color: TextColorRole.greyColor)),
      ]));

  String? correctBlankAnswer(int index) {
    final position = index + 1;
    final correctAnswers = effectiveCorrectBlankAnswers(answerBloc.state);
    for (final item in correctAnswers) {
      if (item.position == position && item.answer?.trim().isNotEmpty == true) {
        return item.answer!.trim();
      }
    }
    if (correctAnswers.length > index) {
      final answer = correctAnswers[index].answer?.trim();
      if (answer != null && answer.isNotEmpty) return answer;
    }
    return null;
  }

  Widget correctBlankAnswerView(String answer) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
            child: Text(answer,
                style: Style.small3w5(context)
                    .copyWith(color: AppColors.primary, fontWeight: FontWeight.w700)))
      ]));

  Widget fillBlankView() => Column(
          children: List.generate(blankControllers.length, (index) {
        final answer = correctBlankAnswer(index);
        return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (showCorrectAnswer && answer != null) correctBlankAnswerView(answer),
              TextField(
                  readOnly: isResultState,
                  controller: blankControllers[index],
                  decoration: InputDecoration(
                      hintText: 'Blank {number}'.tr(namedArgs: {'number': '${index + 1}'}),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))))
            ]));
      }));

  Widget shortAnswerView() => TextField(
      controller: shortAnswerController,
      readOnly: isResultState,
      maxLines: 4,
      decoration: InputDecoration(
          hintText: 'Type your answer'.tr(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))));

  bool get canRevealCorrectAnswer =>
      !isMockExam &&
      hasSubmitted &&
      isReviewableQuestion &&
      (!showCorrectAnswer || hasCurrentAnswerEvidence(answerBloc.state));

  bool get isReviewableQuestion => isFillBlank || currentAnswers.isNotEmpty || hasAnswerReviewData;

  bool get hasAnswerReviewData =>
      effectiveCorrectAnswerIds(answerBloc.state).isNotEmpty ||
      hasCurrentAnswerEvidence(answerBloc.state) ||
      hasCorrectBlankAnswers;

  bool get canShowAnswerButton => canRevealCorrectAnswer;

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
    final result = currentQuestionResult(answerState);
    return result?.questionId == currentQuestion.id && result?.isCorrect == true;
  }

  Color resultPanelColor(QuestionAnswerState answerState) => isMockExam
      ? AppColors.white
      : questionWasCorrect(answerState)
          ? AppColors.primary
          : AppColors.error;

  Color resultPanelTextColor(BuildContext context) =>
      isResultState && !isMockExam ? AppColors.white : context.cs.onSurface;

  IconData resultPanelIcon(QuestionAnswerState answerState) => isMockExam
      ? Icons.check_circle_rounded
      : questionWasCorrect(answerState)
          ? Icons.check_circle_rounded
          : Icons.error_outline_rounded;

  String resultPanelTitle(QuestionAnswerState answerState) {
    if (isMockExam) return 'Answer saved'.tr();
    return questionWasCorrect(answerState)
        ? 'Your answer was correct'.tr()
        : 'Your answer was incorrect'.tr();
  }

  String? resultPanelSubtitle(QuestionAnswerState answerState) {
    if (!isResultState) {
      return isReadyToSubmit
          ? 'Submit now or skip and return later.'.tr()
          : 'Choose an answer or skip and return later.'.tr();
    }
    if (isMockExam) {
      return allQuestionsSubmitted && isLastQuestion
          ? 'Tap finish to see your result.'.tr()
          : 'Tap continue to move to the next question.'.tr();
    }
    if (questionWasCorrect(answerState)) {
      return allQuestionsSubmitted && isLastQuestion
          ? 'Tap finish to see your result.'.tr()
          : 'Tap continue to move to the next question.'.tr();
    }
    if (showCorrectAnswer && effectiveCorrectAnswerIds(answerState).isNotEmpty) {
      return 'The correct answer is now marked for review.'.tr();
    }
    if (showCorrectAnswer && hasCorrectBlankAnswers) {
      return 'The correct blank answers are now shown above the fields.'.tr();
    }
    if (showCorrectAnswer && hasCurrentAnswerEvidence(answerState)) {
      return 'Tap the eye button again to review the answer evidence.'.tr();
    }
    if (canRevealCorrectAnswer) {
      return 'Tap the eye button to view the correct answer.'.tr();
    }
    return null;
  }

  Widget answerEvidenceLoadingView(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        const CircularProgressIndicator(strokeWidth: 3),
        const SizedBox(height: 14),
        Text('Loading answer...'.tr(),
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]));

  Widget answerEvidenceMissingView(BuildContext context) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.check_circle_outline_rounded,
            size: 42, color: context.cs.primary.withValues(alpha: 0.8)),
        const SizedBox(height: 12),
        Text('The correct answer is now marked on the question.'.tr(),
            textAlign: TextAlign.center,
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]));

  Widget answerEvidenceFutureView(
          {required BuildContext sheetContext,
          required Future<SectionAnswerModel?> answerFuture,
          SectionAnswerModel? initialAnswer}) =>
      FutureBuilder<SectionAnswerModel?>(
          future: answerFuture,
          initialData: initialAnswer,
          builder: (context, snapshot) {
            final answer = snapshot.data;
            if (answer == null && snapshot.connectionState != ConnectionState.done) {
              return answerEvidenceLoadingView(sheetContext);
            }
            if (answer == null) return answerEvidenceMissingView(sheetContext);
            return SingleChildScrollView(
                child: SectionAnswerEvidenceView(
                    content: widget.sectionContent,
                    answer: answer,
                    textStyle: Style.bodyw4(sheetContext)));
          });

  Future<void> showAnswerEvidenceSheet(
      {required Future<SectionAnswerModel?> answerFuture, SectionAnswerModel? initialAnswer}) {
    return showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: context.cs.surface,
        shape: RoundedRectangleBorder(borderRadius: Style.borderVer24),
        builder: (sheetContext) => SafeArea(
            top: false,
            child: SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.78,
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                      Center(
                          child: Container(
                              width: 46,
                              height: 5,
                              decoration: BoxDecoration(
                                  color: sheetContext.cs.outline.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(999)))),
                      const SizedBox(height: 18),
                      Row(children: [
                        Expanded(
                            child: Text('Answer evidence'.tr(), style: Style.body2w6(context))),
                        IconButton(
                            onPressed: () => Navigator.of(sheetContext).pop(),
                            icon: const Icon(Icons.close_rounded))
                      ]),
                      const SizedBox(height: 8),
                      Text(
                          'The highlighted text or audio time shows where this answer appears.'
                              .tr(),
                          style: Style.small3w4(context, color: TextColorRole.greyColor)),
                      const SizedBox(height: 16),
                      Expanded(
                          child: answerEvidenceFutureView(
                              sheetContext: sheetContext,
                              answerFuture: answerFuture,
                              initialAnswer: initialAnswer))
                    ])))));
  }

  Future<SectionAnswerModel?> refreshCurrentEvidenceAnswer(QuestionAnswerState answerState) async {
    if (currentQuestion.sectionId.isEmpty) return null;
    try {
      final detail = await fetchFreshSectionDetail();
      SectionQuestionModel? freshQuestion;
      for (final item in detail.questions) {
        if (item.id == currentQuestion.id) {
          freshQuestion = item;
          break;
        }
      }
      if (freshQuestion == null) return null;
      questions[questionIndex] = freshQuestion;
      submittedQuestionIds.add(freshQuestion.id);
      hasSubmitted = true;
      if (mounted) setState(() {});
      return currentEvidenceAnswer(answerState);
    } catch (_) {
      return null;
    }
  }

  Future<SectionModel> fetchFreshSectionDetail() {
    if (currentQuestion.source == SectionSource.assignment) {
      final assignmentId = currentQuestion.assignmentId;
      if (assignmentId == null || assignmentId.isEmpty) {
        throw Exception('Assignment id is missing.');
      }
      return answerBloc.assignmentsRemoteDataSource.fetchAssignmentSectionDetail(
          assignmentId: assignmentId, sectionId: currentQuestion.sectionId);
    }
    if (currentQuestion.source == SectionSource.mockExam) {
      final mockExamId = currentQuestion.mockExamId;
      final attemptId = currentQuestion.mockAttemptId;
      if (mockExamId == null || mockExamId.isEmpty || attemptId == null || attemptId.isEmpty) {
        throw Exception('Mock exam data is missing.');
      }
      return answerBloc.mockExamRemoteDataSource.fetchMockExamSectionDetail(
          mockExamId: mockExamId, attemptId: attemptId, sectionId: currentQuestion.sectionId);
    }
    return answerBloc.learnRemoteDataSource
        .fetchSectionDetail(sectionId: currentQuestion.sectionId);
  }

  Future<void> revealAnswer(QuestionAnswerState answerState) async {
    if (!showCorrectAnswer && mounted) setState(() => showCorrectAnswer = true);
    final evidenceAnswer = currentEvidenceAnswer(answerState);
    if (evidenceAnswer != null) {
      showAnswerEvidenceSheet(
          answerFuture: Future<SectionAnswerModel?>.value(evidenceAnswer),
          initialAnswer: evidenceAnswer);
      return;
    }

    final freshEvidenceAnswer = await refreshCurrentEvidenceAnswer(answerState);
    if (!mounted || freshEvidenceAnswer == null) return;
    showAnswerEvidenceSheet(
        answerFuture: Future<SectionAnswerModel?>.value(freshEvidenceAnswer),
        initialAnswer: freshEvidenceAnswer);
  }

  Widget showAnswerButton(QuestionAnswerState answerState) => InkWell(
      onTap: () => revealAnswer(answerState),
      borderRadius: BorderRadius.circular(21),
      child: Container(
          height: 30,
          width: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(21),
              border: Border.all(
                  color: isResultState
                      ? AppColors.white.withValues(alpha: 0.75)
                      : AppColors.orange033.withValues(alpha: 0.35))),
          child: Icon(Icons.visibility_rounded,
              size: 20,
              color: isResultState ? resultPanelColor(answerState) : AppColors.orange033)));

  Widget navigationCircleButton(
          {Key? key,
          required IconData icon,
          required VoidCallback onTap,
          required bool isAvailable}) =>
      InkWell(
          key: key,
          onTap: isAvailable ? onTap : null,
          child: Ink(
              child: Container(
                  width: 68,
                  height: 36,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(18)),
                      color: isAvailable ? AppColors.white : AppColors.gray100,
                      border:
                          Border.all(color: isAvailable ? AppColors.gray200 : AppColors.gray100)),
                  child: Icon(icon,
                      size: 26, color: isAvailable ? AppColors.gray700 : AppColors.gray400))));

  Widget submitButton(QuestionAnswerState answerState) {
    final canSubmit = hasSubmitted ? true : isReadyToSubmit;
    final label = hasSubmitted || isReviewMode
        ? allQuestionsSubmitted && isLastQuestion
            ? 'Finish'
            : 'Continue'
        : 'Submit';
    return KeyedSubtree(
        key: submitButtonKey,
        child: Button.primary(
            onTap: hasSubmitted || isReviewMode ? goNextQuestion : submitCurrentAnswer,
            height: 36,
            text: label.tr(),
            color: isResultState && !isMockExam ? AppColors.white : null,
            textColor: isResultState && !isMockExam ? resultPanelColor(answerState) : null,
            isLoading: !isReviewMode && answerState.status.isLoading,
            isAvialable: canSubmit));
  }

  Widget actionButtons(QuestionAnswerState answerState) {
    return Row(children: [
      navigationCircleButton(
          key: previousButtonKey,
          icon: Icons.chevron_left,
          onTap: goPreviousQuestion,
          isAvailable: !isFirstQuestion && !answerState.status.isLoading),
      const SizedBox(width: 12),
      Expanded(child: submitButton(answerState)),
      const SizedBox(width: 12),
      navigationCircleButton(
          key: nextButtonKey,
          icon: isLastQuestion
              ? allQuestionsSubmitted
                  ? Icons.check_rounded
                  : Icons.fact_check_rounded
              : Icons.chevron_right,
          onTap: goNextQuestion,
          isAvailable: !answerState.status.isLoading)
    ]);
  }

  Widget bottomResultPanel(BuildContext context, QuestionAnswerState answerState) {
    final panelColor = isResultState ? resultPanelColor(answerState) : AppColors.white;
    final subtitle = resultPanelSubtitle(answerState);
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final textColor = resultPanelTextColor(context);
    final panelAction = widget.panelActionBuilder?.call(context, isResultState, panelColor);
    return SizedBox(
        key: bottomPanelKey,
        width: double.infinity,
        child: Container(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 20 + bottomInset),
            decoration: BoxDecoration(
              color: panelColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              border: isResultState && isMockExam
                  ? Border.all(color: AppColors.primary, width: 1.5)
                  : null,
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  height: 80,
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
                              KeyedSubtree(key: panelActionKey, child: panelAction),
                            ]
                          ]),
                          const SizedBox(height: 8),
                          Expanded(
                              child: Row(
                            children: [
                              if (canShowAnswerButton) showAnswerButton(answerState),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(subtitle ?? '',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: Style.small3w4(context).copyWith(
                                        color: isMockExam
                                            ? context.cs.onSurface.withValues(alpha: 0.72)
                                            : AppColors.white.withValues(alpha: 0.92))),
                              ),
                            ],
                          ))
                        ])
                      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Expanded(
                              child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(subtitle ?? '',
                                      style: Style.bodyw4(context).copyWith(color: textColor)))),
                          if (panelAction != null) ...[
                            const SizedBox(width: 12),
                            KeyedSubtree(key: panelActionKey, child: panelAction),
                          ]
                        ])),
              const SizedBox(height: 12),
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

  Color questionStatusColor(SectionQuestionModel question) =>
      isQuestionSubmitted(question) ? AppColors.primary : AppColors.orange09;

  Widget questionStatusBadge(BuildContext context, SectionQuestionModel question) {
    final submitted = isQuestionSubmitted(question);
    return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
            color: submitted ? AppColors.greenE7 : AppColors.orangeEB, borderRadius: Style.border8),
        child: Text(submitted ? 'Submitted'.tr() : 'Not submitted'.tr(),
            style: Style.smallw6(context)
                .copyWith(color: submitted ? AppColors.green36 : AppColors.orange12)));
  }

  Widget questionListTile(BuildContext panelContext, int index) {
    final question = questions[index];
    final submitted = isQuestionSubmitted(question);
    final isCurrent = index == questionIndex;
    final statusColor = questionStatusColor(question);
    return Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: () => goToQuestion(index, closeQuestionsOverview: true),
            borderRadius: Style.border16,
            child: Ink(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: isCurrent ? AppColors.greenE7 : panelContext.cs.surface,
                    borderRadius: Style.border16,
                    border: Border.all(
                        color: isCurrent
                            ? AppColors.primary
                            : submitted
                                ? AppColors.greenC6
                                : AppColors.gray200)),
                child: Row(children: [
                  Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      child: Center(
                          child: Text('${index + 1}',
                              style:
                                  Style.small3w7(panelContext, color: TextColorRole.whiteColor)))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Question {current}'.tr(namedArgs: {'current': '${index + 1}'}),
                        style: Style.bodyw6(panelContext)),
                    const SizedBox(height: 4),
                    questionStatusBadge(panelContext, question)
                  ])),
                  if (isCurrent)
                    const Icon(Icons.radio_button_checked_rounded,
                        color: AppColors.green36, size: 20)
                  else
                    Icon(submitted ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: submitted ? AppColors.green36 : AppColors.gray400, size: 20)
                ]))));
  }

  Widget questionListPanel(BuildContext panelContext) => Container(
      width: double.infinity,
      height: MediaQuery.of(panelContext).size.height * 0.78,
      decoration: BoxDecoration(
          color: panelContext.cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                    child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                            color: panelContext.cs.outline.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999)))),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: Text('Questions'.tr(), style: Style.body2w6(panelContext))),
                  IconButton(
                      onPressed: closeQuestionsOverview, icon: const Icon(Icons.close_rounded))
                ]),
                const SizedBox(height: 4),
                Text(
                    allQuestionsSubmitted
                        ? 'All questions are submitted.'.tr()
                        : 'Choose not submitted questions and solve them.'.tr(),
                    style: Style.small3w4(panelContext, color: TextColorRole.greyColor)),
                const SizedBox(height: 14),
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration:
                        BoxDecoration(color: AppColors.gray100, borderRadius: Style.border16),
                    child: Row(children: [
                      Expanded(
                          child: Text(
                              'Answered {count} of {total}'.tr(namedArgs: {
                                'count': '$submittedCount',
                                'total': '${questions.length}'
                              }),
                              style: Style.small3w5(panelContext))),
                      Text('$unsubmittedCount ${'left'.tr()}',
                          style: Style.small3w5(panelContext).copyWith(
                              color:
                                  unsubmittedCount == 0 ? AppColors.green36 : AppColors.orange12))
                    ])),
                const SizedBox(height: 14),
                Expanded(
                    child: ListView.separated(
                        itemCount: questions.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, index) => questionListTile(panelContext, index))),
                if (allQuestionsSubmitted) ...[
                  const SizedBox(height: 14),
                  Button.primary(
                      onTap: () async {
                        closeQuestionsOverview();
                        await finishQuizIfComplete();
                      },
                      text: 'Finish'.tr())
                ]
              ]))));

  Widget questionsOverviewOverlay(BuildContext context) => Positioned.fill(
      child: IgnorePointer(
          ignoring: !isQuestionsOverviewVisible,
          child: Material(
              type: MaterialType.transparency,
              child: Stack(children: [
                AnimatedOpacity(
                    opacity: isQuestionsOverviewVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: GestureDetector(
                        onTap: closeQuestionsOverview,
                        child: Container(color: AppColors.black.withValues(alpha: 0.38)))),
                AnimatedSlide(
                    offset: isQuestionsOverviewVisible ? Offset.zero : const Offset(0, 1),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child:
                        Align(alignment: Alignment.bottomCenter, child: questionListPanel(context)))
              ]))));

  Widget scrollContent(QuestionAnswerState answerState, double bottomSpacerHeight) => ListView(
          padding: EdgeInsets.only(bottom: bottomSpacerHeight),
          physics: const ClampingScrollPhysics(),
          children: [
            Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(children: [
                  const SizedBox(height: 24),
                  quizTopBar,
                  const SizedBox(height: 16),
                  KeyedSubtree(key: quizProgressKey, child: progressHeader),
                  const SizedBox(height: 24),
                  ...isShownHeaderWidget,
                  KeyedSubtree(
                      key: questionCardKey, child: QuestionsCard(currentQuestion: currentQuestion)),
                  const SizedBox(height: 20),
                  // if (hasMalformedChoiceQuestion) ...[
                  //   malformedQuestionWarning(context),
                  //   const SizedBox(height: 12),
                  // ],
                  answerInputArea(answerState),
                ]))
          ]);

  Widget get view => LayoutBuilder(
      builder: (context, constraints) => BlocBuilder<QuestionAnswerBloc, QuestionAnswerState>(
          bloc: answerBloc,
          builder: (context, answerState) {
            final panelHeight = 210.0 + MediaQuery.of(context).padding.bottom;
            return Stack(children: [
              Positioned.fill(child: scrollContent(answerState, panelHeight + 16)),
              Positioned(top: 12, right: 12, child: questionsOverviewButton),
              Positioned(
                  left: 0, right: 0, bottom: 0, child: bottomResultPanel(context, answerState))
            ]);
          }));

  @override
  Widget build(BuildContext context) {
    if (questions.isEmpty)
      return Center(
          child: Text('No questions available.'.tr(),
              style: Style.bodyw5(context, color: TextColorRole.greyColor)));

    final storage = sl<TutorialStorageService>();
    final questionTypePageId = '${TutorialPageIds.sectionQuiz}.type.$questionType';
    final normalizedSectionType = widget.sectionType?.toLowerCase();
    final isEvidenceSection =
        normalizedSectionType == 'reading' || normalizedSectionType == 'listening';
    final evidencePageId = '${TutorialPageIds.sectionQuiz}.answer_evidence.$normalizedSectionType';
    final includeCommonSteps = !storage.isPageCompleted(TutorialPageIds.sectionQuiz);
    final includeEvidenceStep = isEvidenceSection && !storage.isPageCompleted(evidencePageId);
    final pageId = includeCommonSteps
        ? TutorialPageIds.sectionQuiz
        : includeEvidenceStep
            ? evidencePageId
            : questionTypePageId;
    final completedPageIds = [
      if (includeCommonSteps) questionTypePageId,
      if (includeCommonSteps && includeEvidenceStep) evidencePageId,
    ];

    return GuidedTutorialPage(
        pageId: pageId,
        additionalCompletedPageIds: completedPageIds,
        steps: TutorialPresets.sectionQuiz(
            questionType: questionType,
            sectionType: normalizedSectionType,
            includeCommonSteps: includeCommonSteps,
            includeEvidenceStep: includeEvidenceStep,
            progressKey: quizProgressKey,
            questionListKey: questionListButtonKey,
            questionKey: questionCardKey,
            answerKey: answerAreaKey,
            bottomPanelKey: bottomPanelKey,
            submitKey: submitButtonKey,
            previousKey: previousButtonKey,
            nextKey: nextButtonKey,
            panelActionKey: widget.panelActionBuilder == null ? null : panelActionKey),
        child: BlocListener<QuestionAnswerBloc, QuestionAnswerState>(
            bloc: answerBloc,
            listener: (context, state) {
              if (state.status.isSuccess) {
                if (!hasSubmitted) {
                  _saveCurrentQuestionState();
                  submittedQuestionIds.add(currentQuestion.id);
                  final result = state.result;
                  if (result != null && result.questionId == currentQuestion.id) {
                    questionResults[currentQuestion.id] = result;
                  }
                  if (!isMockExam &&
                      result?.questionId == currentQuestion.id &&
                      result?.isCorrect == true) {
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
            child: PopScope(
                canPop: !isQuestionsOverviewVisible,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop && isQuestionsOverviewVisible) closeQuestionsOverview();
                },
                child: view)));
  }
}
