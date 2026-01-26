import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/next_task_bloc/next_task_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/audio_bloc/audio_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/audio_bloc/audio_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/audio_bloc/audio_state.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_listen_tap_set_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_status_bloc/practice_listen_tap_status_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_status_bloc/practice_listen_tap_status_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_status_bloc/practice_listen_tap_status_state.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/practice_listen_quiz_view_content.dart';
import 'package:ustadia_user_app/injection_container.dart';

class PracticeListenQuizView extends StatefulWidget {
  final PracticeListenTapSetModel set;

  const PracticeListenQuizView({super.key, required this.set});

  @override
  State<PracticeListenQuizView> createState() => PracticeListenQuizViewState();
}

class PracticeListenQuizViewState extends State<PracticeListenQuizView> {
  final AudioPlayer player = AudioPlayer();
  final AudioBloc audioBloc = sl<AudioBloc>();
  final PracticeListenTapStatusBloc statusBloc = sl<PracticeListenTapStatusBloc>();

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
    requestAudio();
  }

  @override
  void dispose() {
    player.dispose();
    audioBloc.close();
    statusBloc.close();

    super.dispose();
  }

  /// --- Listener ---

  void audioListener(context, state) {
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
  }

  void practiceListenTapStatus(context, state) {
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
    if (state.status.isSuccess) {
      setState(() {
        showResult = true;
      });
    }
  }

  /// --- Methods ---

  void requestAudio() {
    final url = current.audio?.url ?? '';
    if (url.isEmpty) return;
    audioBloc.add(AudioRequested(url: url));
  }

  Future<void> onPlayAudio() async {
    final state = audioBloc.state;
    if (state.status.isLoading) return;
    final path = state.filePath;
    if (path == null || path.isEmpty) {
      requestAudio();
      return;
    }
    await player.play(DeviceFileSource(path));
  }

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
    requestAudio();
  }

  /// --- Widgets ---

  Widget get indicator =>
      PageIndicator(currentIndex: listeningIndex, total: questions.length, isExpanded: true);

  Widget get currentListening => Text(
        "${getNumberInWords(listeningIndex)} $wordOrSentence",
        style: Style.small2w4(context, color: TextColorRole.greyColor),
      );

  Widget get totalListeningWidget => Text(
        "Total: ${questions.length} ${wordOrSentence}s",
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
          BlocBuilder<AudioBloc, AudioState>(
              bloc: audioBloc,
              builder: (context, state) => PracticeListenQuizViewContent(
                  question: current, onPlay: onPlayAudio, isLoading: state.status.isLoading)),
          const SizedBox(height: 10),
          BlocBuilder<PracticeListenTapStatusBloc, PracticeListenTapStatusState>(
              bloc: statusBloc,
              builder: (context, statusState) => BlocBuilder<NextTaskBloc, NextTaskState>(
                  builder: (context, state) => Button.primary(
                      onTap: onNext,
                      text: 'Next',
                      isAvialable: state.isCurrentTaskCompleted && !statusState.status.isLoading))),
        ],
      );

  @override
  Widget build(BuildContext context) => MultiBlocListener(
          listeners: [
            BlocListener<AudioBloc, AudioState>(bloc: audioBloc, listener: audioListener),
            BlocListener<PracticeListenTapStatusBloc, PracticeListenTapStatusState>(
                bloc: statusBloc, listener: practiceListenTapStatus),
          ],
          child: showResult
              ? QuizResultComponent(
                  all: questions.length,
                  correctOnes: correctCount,
                )
              : quizView);
}
