import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/next_task_bloc/next_task_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/cards/audio_card.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_listen_tap_set_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_status_bloc/practice_listen_tap_status_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_status_bloc/practice_listen_tap_status_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_status_bloc/practice_listen_tap_status_state.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/practice_listen_quiz_view_content.dart';
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

  int listeningIndex = 0;
  int correctCount = 0;
  final Set<int> countedIndices = {};
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
    context.read<NextTaskBloc>().setCurrentTaskCompleted(false, isAnswerCorrect: false);
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
    final nextState = context.read<NextTaskBloc>().state;
    if (!countedIndices.contains(listeningIndex)) {
      countedIndices.add(listeningIndex);
      if (nextState.isAnswerCorrect) {
        correctCount++;
      }
    }
    if (listeningIndex == questions.length - 1) {
      statusBloc
          .add(PracticeListenTapStatusRequested(listenTapId: widget.set.id, status: 'completed'));
      return;
    }
    setState(() {
      listeningIndex++;
    });
    context.read<NextTaskBloc>().setCurrentTaskCompleted(false, isAnswerCorrect: false);
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

  Widget get quizView => ListView(
        physics: const ClampingScrollPhysics(),
        children: [
          const SizedBox(height: 24),
          indicator,
          const SizedBox(height: 4),
          listeningInfo,
          const SizedBox(height: 12),
          AudioCard(sectionModel: currentQuestionAudioSection),
          PracticeListenQuizViewContent(
              question: current, onPlay: () {}, isLoading: false, hideAudioControls: true),
          const SizedBox(height: 10),
          BlocBuilder<PracticeListenTapStatusBloc, PracticeListenTapStatusState>(
              bloc: statusBloc,
              builder: (context, statusState) => BlocBuilder<NextTaskBloc, NextTaskState>(
                  builder: (context, state) => Button.primary(
                      onTap: onNext,
                      text: 'Next'.tr(),
                      isAvialable: state.isCurrentTaskCompleted && !statusState.status.isLoading))),
        ],
      );

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
      body: PrimaryBackground(
          title: widget.set.title, isScrollable: false, child: view));
}
