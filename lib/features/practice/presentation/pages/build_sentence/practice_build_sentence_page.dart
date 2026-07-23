import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_sentence_builder_set_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_status_bloc/practice_sentence_builder_status_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_status_bloc/practice_sentence_builder_status_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_status_bloc/practice_sentence_builder_status_state.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/practice_build_sentence_content.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/practice_questions_overview.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';
import 'package:ustadia_user_app/injection_container.dart';

class PracticeBuildSentencePage extends StatefulWidget {
  final PracticeSentenceBuilderSetModel set;
  const PracticeBuildSentencePage({super.key, required this.set});

  @override
  State<PracticeBuildSentencePage> createState() => _PracticeBuildSentencePageState();
}

class _PracticeBuildSentencePageState extends State<PracticeBuildSentencePage> {
  final PracticeSentenceBuilderStatusBloc statusBloc = sl<PracticeSentenceBuilderStatusBloc>();
  final ProfileStatisticsStore statisticsStore = sl<ProfileStatisticsStore>();
  final GlobalKey contentKey = GlobalKey(debugLabel: 'build_sentence_content');
  final Set<int> completedIndices = {};
  bool showResult = false;
  bool showOverview = false;
  int questionIndex = 0;
  int wrongAttempts = 0;
  int attemptNonce = 0;

  /// --- Data ---

  List<PracticeSentenceBuilderQuestionModel> get questions => widget.set.questions;

  PracticeSentenceBuilderQuestionModel? get currentQuestion =>
      questions.isNotEmpty ? questions[questionIndex] : null;

  List<String> get correctOrder => currentQuestion?.correctOrder ?? const [];

  int get totalQuestions => questions.isNotEmpty ? questions.length : widget.set.totalQuestions;

  bool get isFirstQuestion => questionIndex == 0;
  bool get isLastQuestion => questionIndex >= questions.length - 1;
  bool get isCurrentQuestionCompleted => completedIndices.contains(questionIndex);
  bool get allQuestionsCompleted =>
      questions.isNotEmpty && completedIndices.length >= questions.length;

  @override
  void dispose() {
    statusBloc.close();
    super.dispose();
  }

  void submitCompleted() {
    statusBloc.add(PracticeSentenceBuilderStatusRequested(
        sentenceBuilderId: widget.set.id,
        status: 'completed',
        correctAnswers: completedIndices.length,
        wrongAnswers: wrongAttempts));
  }

  void onQuestionCompleted() {
    setState(() => completedIndices.add(questionIndex));
  }

  void goToQuestion(int index) {
    if (index < 0 || index >= questions.length) return;
    setState(() {
      showOverview = false;
      questionIndex = index;
      attemptNonce++;
    });
  }

  void goPreviousQuestion() {
    if (isFirstQuestion) return;
    goToQuestion(questionIndex - 1);
  }

  void repeatQuestion() {
    setState(() => attemptNonce++);
  }

  void goNextQuestion() {
    if (!isLastQuestion) {
      goToQuestion(questionIndex + 1);
      return;
    }
    finishOrReview();
  }

  void finishOrReview() {
    if (allQuestionsCompleted) {
      submitCompleted();
      return;
    }
    setState(() => showOverview = true);
  }

  void onWrongAttempt() => setState(() => wrongAttempts++);

  /// --- Widgets ---

  Widget get progressHeader => Column(children: [
        PageIndicator(currentIndex: questionIndex, total: questions.length, isExpanded: true),
        const SizedBox(height: 4),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('Question {number}'.tr(namedArgs: {'number': '${questionIndex + 1}'}),
              style: Style.small2w4(context, color: TextColorRole.greyColor)),
          Text('Completed {completed} of {total}'.tr(namedArgs: {
            'completed': '${completedIndices.length}',
            'total': '${questions.length}'
          }))
        ])
      ]);

  Widget get actionButtons {
    final primaryLabel = isLastQuestion
        ? allQuestionsCompleted
            ? 'Finish'
            : 'Review'
        : 'Next';
    return Column(children: [
      Button.border(
          onTap: repeatQuestion,
          text: 'Repeat'.tr(),
          isAvialable: isCurrentQuestionCompleted,
          height: 46),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(
            child: Button.border(
                onTap: goPreviousQuestion,
                text: 'Back'.tr(),
                isAvialable: !isFirstQuestion,
                height: 46)),
        const SizedBox(width: 10),
        Expanded(child: Button.primary(onTap: goNextQuestion, text: primaryLabel.tr(), height: 46)),
      ]),
    ]);
  }

  Widget get view => PrimaryBackground(
      title: widget.set.title.isEmpty ? 'Build the sentence' : widget.set.title,
      isScrollable: false,
      child: correctOrder.isEmpty
          ? Center(child: Text('No questions found'.tr()))
          : Column(children: [
              const SizedBox(height: 24),
              progressHeader,
              const SizedBox(height: 16),
              Expanded(
                  child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: KeyedSubtree(
                              key: contentKey,
                              child: PracticeBuildSentenceContent(
                                  key: ValueKey(
                                      '${currentQuestion?.id ?? questionIndex}-$attemptNonce'),
                                  correctOrder: correctOrder,
                                  onCompleted: onQuestionCompleted,
                                  onWrongAttempt: onWrongAttempt))))),
              const SizedBox(height: 12),
              actionButtons,
            ]));

  @override
  Widget build(BuildContext context) => BlocListener<PracticeSentenceBuilderStatusBloc,
          PracticeSentenceBuilderStatusState>(
      bloc: statusBloc,
      listener: (context, state) {
        if (state.status.isError && state.errorMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.status.isSuccess) {
          statisticsStore.refresh();
          setState(() => showResult = true);
        }
      },
      child: Scaffold(
          backgroundColor: context.cs.surface,
          body: SafeArea(
              child: showResult
                  ? QuizResultComponent(all: totalQuestions, correctOnes: completedIndices.length)
                  : showOverview
                      ? PracticeQuestionsOverview(
                          title: widget.set.title.isEmpty
                              ? 'Build the sentence'.tr()
                              : widget.set.title,
                          total: questions.length,
                          completedIndices: completedIndices,
                          onQuestionTap: goToQuestion,
                          onContinueIncomplete: () => setState(() => showOverview = false),
                          onShowResult: submitCompleted)
                      : GuidedTutorialPage(
                          pageId: '${TutorialPageIds.practiceSession}.build_sentence',
                          steps: TutorialPresets.buildSentencePractice(contentKey: contentKey),
                          child: view))));
}
