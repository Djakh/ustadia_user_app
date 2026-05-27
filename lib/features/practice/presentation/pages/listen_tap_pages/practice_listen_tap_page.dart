import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/cards/audio_card.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_listen_tap_set_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_status_bloc/practice_listen_tap_status_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_status_bloc/practice_listen_tap_status_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_status_bloc/practice_listen_tap_status_state.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';
import 'package:ustadia_user_app/injection_container.dart';

class PracticeListenTapPage extends StatefulWidget {
  final PracticeListenTapSetModel set;

  const PracticeListenTapPage({super.key, required this.set});

  @override
  State<PracticeListenTapPage> createState() => PracticeListenTapPageState();
}

class PracticeListenTapPageState extends State<PracticeListenTapPage> {
  /// --- Widgets ---

  final PracticeListenTapStatusBloc statusBloc = sl<PracticeListenTapStatusBloc>();
  final ProfileStatisticsStore statisticsStore = sl<ProfileStatisticsStore>();
  final GlobalKey progressKey = GlobalKey(debugLabel: 'listen_tap_progress');
  final GlobalKey audioKey = GlobalKey(debugLabel: 'listen_tap_audio');
  final GlobalKey optionsKey = GlobalKey(debugLabel: 'listen_tap_options');
  final GlobalKey bottomPanelKey = GlobalKey(debugLabel: 'listen_tap_bottom_panel');
  final GlobalKey submitKey = GlobalKey(debugLabel: 'listen_tap_submit');

  int listeningIndex = 0;
  int correctCount = 0;
  final Set<int> countedIndices = {};
  int? selectedIndex;
  bool hasSubmitted = false;
  bool showCorrectAnswer = false;
  bool showResult = false;

  /// --- Getters ---

  List<PracticeListenTapQuestionModel> get questions => widget.set.questions;

  PracticeListenTapQuestionModel get current => questions[listeningIndex];

  double get progress => (listeningIndex + 1) / questions.length;

  String getNumberInWords(int number) {
    switch (number) {
      case 0:
        return 'First';
      case 1:
        return 'Second';
      case 2:
        return 'Third';

      default:
        return '';
    }
  }

  String get wordOrSentence => "word";

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    statusBloc.close();

    super.dispose();
  }

  /// --- Listener ---

  void practiceListenTapStatus(context, state) {
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
    if (state.status.isSuccess) {
      statisticsStore.refresh();
      setState(() {
        showResult = true;
      });
    }
  }

  /// --- Methods ---

  void onNext() {
    if (statusBloc.state.status.isLoading) return;
    if (!countedIndices.contains(listeningIndex)) {
      countedIndices.add(listeningIndex);
      if (selectedIndex == current.correctIndex) {
        correctCount++;
      }
    }
    if (listeningIndex == questions.length - 1) {
      final wrongCount = countedIndices.length - correctCount;
      statusBloc.add(PracticeListenTapStatusRequested(
          listenTapId: widget.set.id,
          status: 'completed',
          correctAnswers: correctCount,
          wrongAnswers: wrongCount < 0 ? 0 : wrongCount));
      return;
    }
    setState(() {
      listeningIndex++;
      selectedIndex = null;
      hasSubmitted = false;
      showCorrectAnswer = false;
    });
  }

  void submitCurrentAnswer() {
    if (selectedIndex == null || hasSubmitted) return;
    setState(() => hasSubmitted = true);
  }

  void selectOption(int index) {
    if (hasSubmitted || statusBloc.state.status.isLoading) return;
    setState(() => selectedIndex = index);
  }

  SectionModel get currentQuestionAudioSection => SectionModel(
      id: current.id,
      unitId: widget.set.id,
      lessonId: null,
      title: widget.set.title,
      content: '',
      orderIndex: listeningIndex,
      totalQuestions: current.options.length,
      answeredQuestions: null,
      assignmentId: null,
      audioFileId: current.audioId,
      audioFile: current.audio,
      flashCardSetId: null,
      flashCardSet: null,
      unitIsPublished: null,
      lessonIsPublic: null,
      questions: const [],
      iconAsset: AppImages.learnHeadphones,
      progressState: SectionProgressState.inProgress,
      sectionType: SectionType.listening,
      sectionStringType: 'listening',
      isLocked: false,
      source: SectionSource.learn);

  /// --- Widgets ---

  Widget get indicator =>
      PageIndicator(currentIndex: listeningIndex, total: questions.length, isExpanded: true);

  Widget get currentListening => Text(
        '{index} {label}'
            .tr(namedArgs: {'index': getNumberInWords(listeningIndex), 'label': wordOrSentence}),
        style: Style.small2w4(context, color: TextColorRole.greyColor),
      );

  Widget get totalListeningWidget => Text(
        'Total: {count} {label}s'
            .tr(namedArgs: {'count': '${questions.length}', 'label': wordOrSentence}),
        style: Style.small2w4(context),
      );

  Widget get listeningInfo => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [currentListening, totalListeningWidget],
      );

  bool get isResultState => hasSubmitted;

  bool get questionWasCorrect => selectedIndex != null && selectedIndex == current.correctIndex;

  bool get canRevealCorrectAnswer =>
      hasSubmitted &&
      !questionWasCorrect &&
      current.correctIndex >= 0 &&
      current.correctIndex < current.options.length &&
      !showCorrectAnswer;

  Color optionFillColor(BuildContext context, int index) {
    if (!hasSubmitted) return context.cs.surface;
    if (selectedIndex != index) return context.cs.surface;
    return questionWasCorrect ? AppColors.primary : AppColors.error;
  }

  Color optionBorderColor(BuildContext context, int index) {
    if (!hasSubmitted && selectedIndex == index) return AppColors.primary;
    if (showCorrectAnswer && index == current.correctIndex) return AppColors.orange033;
    return AppColors.transparent;
  }

  Color optionTextColor(BuildContext context, int index) {
    final fill = optionFillColor(context, index);
    if (fill == AppColors.primary || fill == AppColors.error) return context.cs.onPrimary;
    if (showCorrectAnswer && index == current.correctIndex) return AppColors.orange033;
    return context.cs.onSurface;
  }

  Widget optionItem(int index) {
    final fill = optionFillColor(context, index);
    final isFilled = fill == AppColors.primary || fill == AppColors.error;
    final showCheck = hasSubmitted && showCorrectAnswer && index == current.correctIndex;
    final checkColor = isFilled ? AppColors.white : AppColors.primary;
    final label = Stack(alignment: Alignment.center, children: [
      Text(current.options[index].word,
          style: Style.bodyw5(context).copyWith(color: optionTextColor(context, index)),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis),
      if (showCheck)
        Align(
            alignment: Alignment.centerRight, child: Icon(Icons.check, size: 18, color: checkColor))
    ]);
    if (isFilled) {
      return Button.primary(onTap: () => selectOption(index), color: fill, child: label);
    }
    return Button.border(
        onTap: () => selectOption(index),
        color: context.cs.surface,
        borderColor: optionBorderColor(context, index),
        borderWidth: showCorrectAnswer && index == current.correctIndex ? 1.5 : 1,
        child: label);
  }

  IconData get resultPanelIcon =>
      questionWasCorrect ? Icons.check_circle_rounded : Icons.error_outline_rounded;

  Color get resultPanelColor => questionWasCorrect ? AppColors.primary : AppColors.error;

  Color resultPanelTextColor(BuildContext context) =>
      isResultState ? AppColors.white : context.cs.onSurface;

  String get resultPanelTitle =>
      questionWasCorrect ? 'Your answer was correct'.tr() : 'Your answer was incorrect'.tr();

  String? get resultPanelSubtitle {
    if (!isResultState) {
      return selectedIndex != null
          ? 'Tap submit to check your answer.'.tr()
          : 'Choose an answer to continue.'.tr();
    }
    if (questionWasCorrect) {
      return 'Tap continue to move to the next question.'.tr();
    }
    if (showCorrectAnswer) {
      return 'The correct answer is now marked for review.'.tr();
    }
    if (canRevealCorrectAnswer) {
      return 'Tap the eye button to view the correct answer.'.tr();
    }
    return null;
  }

  Widget showAnswerButton() => Button.border(
      onTap: () => setState(() => showCorrectAnswer = true),
      height: 52,
      color: AppColors.white,
      borderColor: isResultState
          ? AppColors.white.withValues(alpha: 0.75)
          : AppColors.orange033.withValues(alpha: 0.35),
      child: Icon(Icons.visibility_rounded,
          size: 20, color: isResultState ? resultPanelColor : AppColors.orange033));

  Widget submitButton(PracticeListenTapStatusState statusState) {
    final label = hasSubmitted ? 'Continue' : 'Submit';
    return KeyedSubtree(
        key: submitKey,
        child: Button.primary(
            onTap: hasSubmitted ? onNext : submitCurrentAnswer,
            text: label.tr(),
            color: isResultState ? AppColors.white : null,
            textColor: isResultState ? resultPanelColor : null,
            isLoading: statusState.status.isLoading,
            isAvialable: hasSubmitted || selectedIndex != null));
  }

  Widget actionButtons(PracticeListenTapStatusState statusState) {
    if (!canRevealCorrectAnswer) return submitButton(statusState);
    return Row(children: [
      SizedBox(width: 84, child: showAnswerButton()),
      const SizedBox(width: 12),
      Expanded(child: submitButton(statusState))
    ]);
  }

  Widget bottomResultPanel(PracticeListenTapStatusState statusState) {
    final panelColor = isResultState ? resultPanelColor : AppColors.white;
    final subtitle = resultPanelSubtitle;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final textColor = resultPanelTextColor(context);
    return SizedBox(
        key: bottomPanelKey,
        width: double.infinity,
        child: Container(
            padding: EdgeInsets.fromLTRB(18, 18, 18, 20 + bottomInset),
            decoration: BoxDecoration(
                color: panelColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(
                  height: 72,
                  child: isResultState
                      ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Icon(resultPanelIcon, color: textColor, size: 26),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(resultPanelTitle,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: Style.body2w6(context).copyWith(color: textColor)))
                          ]),
                          const SizedBox(height: 10),
                          Expanded(
                              child: Text(subtitle ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Style.bodyw4(context)
                                      .copyWith(color: AppColors.white.withValues(alpha: 0.92))))
                        ])
                      : Align(
                          alignment: Alignment.centerLeft,
                          child: Text(subtitle ?? '',
                              style: Style.bodyw4(context).copyWith(color: textColor)))),
              const SizedBox(height: 18),
              actionButtons(statusState)
            ])));
  }

  Widget get quizView => BlocBuilder<PracticeListenTapStatusBloc, PracticeListenTapStatusState>(
      bloc: statusBloc,
      builder: (context, statusState) {
        final panelHeight = 210.0 + MediaQuery.of(context).padding.bottom;
        return Stack(children: [
          Positioned.fill(
              child: ListView(
                  padding: EdgeInsets.only(bottom: panelHeight + 16),
                  physics: const ClampingScrollPhysics(),
                  children: [
                Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(children: [
                      const SizedBox(height: 24),
                      KeyedSubtree(
                          key: progressKey,
                          child: Column(
                              children: [indicator, const SizedBox(height: 4), listeningInfo])),
                      const SizedBox(height: 24),
                      KeyedSubtree(
                          key: audioKey,
                          child: AudioCard(sectionModel: currentQuestionAudioSection)),
                      const SizedBox(height: 24),
                      KeyedSubtree(
                          key: optionsKey,
                          child: Column(
                              children: List.generate(
                                  current.options.length,
                                  (index) => Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 6),
                                      child: optionItem(index))))),
                    ]))
              ])),
          Positioned(left: 0, right: 0, bottom: 0, child: bottomResultPanel(statusState))
        ]);
      });

  Widget get view => MultiBlocListener(
          listeners: [
            BlocListener<PracticeListenTapStatusBloc, PracticeListenTapStatusState>(
                bloc: statusBloc, listener: practiceListenTapStatus),
          ],
          child: showResult
              ? QuizResultComponent(
                  all: questions.length,
                  correctOnes: correctCount,
                )
              : quizView);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: GuidedTutorialPage(
          pageId: '${TutorialPageIds.practiceSession}.listen_tap',
          steps: TutorialPresets.listenTapPractice(
              progressKey: progressKey,
              audioKey: audioKey,
              optionsKey: optionsKey,
              bottomPanelKey: bottomPanelKey,
              submitKey: submitKey),
          child: PrimaryBackground(
              title: widget.set.title,
              padding: EdgeInsets.zero,
              margin: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              applyBottomSafeArea: false,
              isScrollable: false,
              alwaysScrollable: false,
              child: view)));
}
