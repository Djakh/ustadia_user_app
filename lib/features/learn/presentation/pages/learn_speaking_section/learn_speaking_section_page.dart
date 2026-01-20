import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:record/record.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_state.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_question_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_question_answer_bloc/learn_question_answer_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_question_answer_bloc/learn_question_answer_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_question_answer_bloc/learn_question_answer_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/banners/learn_speaking_status_banner.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/buttons/learn_speaking_mic_button.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/learn_speaking_prompt_card.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_result_component.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum LearnSpeakingStage { ready, listening, checking, result }

class LearnSpeakingPage extends StatefulWidget {
  final LearnSectionModel sectionModel;

  const LearnSpeakingPage({super.key, required this.sectionModel});

  @override
  State<LearnSpeakingPage> createState() => LearnSpeakingPageState();
}

class LearnSpeakingPageState extends State<LearnSpeakingPage> {
  final LearnSectionDetailBloc detailBloc = sl<LearnSectionDetailBloc>();
  final LearnQuestionAnswerBloc answerBloc = sl<LearnQuestionAnswerBloc>();
  final FileUploadBloc uploadBloc = sl<FileUploadBloc>();
  LearnSpeakingStage stage = LearnSpeakingStage.ready;
  int questionIndex = 0;

  bool isStopping = false;
  final AudioRecorder recorder = AudioRecorder();
  Timer? sessionTimer;
  Duration remainingDuration = Duration.zero;
  String? pendingAudioPath;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    if (widget.sectionModel.id.isNotEmpty) {
      detailBloc.add(LearnSectionDetailRequested(sectionId: widget.sectionModel.id));
    }
  }

  @override
  void dispose() {
    sessionTimer?.cancel();
    recorder.dispose();
    detailBloc.close();
    answerBloc.close();
    uploadBloc.close();
    super.dispose();
  }

  /// --- Getters ---

  List<LearnSectionQuestionModel> getQuestionsList(LearnSectionDetailState state) {
    return state.detail?.questions ?? [];
  }

  Duration get maxSpeakingDuration => const Duration(minutes: 2);

  LearnSectionQuestionModel? currentQuestionFor(LearnSectionDetailState state) {
    final questions = getQuestionsList(state);
    if (questions.isEmpty) return null;
    if (questionIndex >= questions.length) questionIndex = 0;
    return questions[questionIndex];
  }

  String get micStatusText {
    if (stage == LearnSpeakingStage.listening) return 'Listening...';
    if (stage == LearnSpeakingStage.checking) return 'Checking';
    return 'Tap to record';
  }

  /// --- Listeners ---

  void fileUploadListener(_, FileUploadState state) {
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      setStage(LearnSpeakingStage.ready);
      setState(() {});
      return;
    }
    if (state.status.isSuccess && state.uploadedFile != null) {
      final currentQuestion = currentQuestionFor(detailBloc.state);
      if (currentQuestion == null) return;
      answerBloc.add(LearnQuestionAnswerSubmitted(
        sectionId: currentQuestion.sectionId,
        questionId: currentQuestion.id,
        userAudioId: state.uploadedFile!.id,
      ));
      pendingAudioPath = null;
    }
  }

  void learnQuestionAnswerListener(_, LearnQuestionAnswerState state) async {
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      setStage(LearnSpeakingStage.ready);
      setState(() {});
      nextOrFinish(getQuestionsList(detailBloc.state).length);
    }
    if (state.status.isSuccess) {
      if (!mounted) return;
      nextOrFinish(getQuestionsList(detailBloc.state).length);
    }
  }

  /// --- Methods ---

  void setStage(LearnSpeakingStage value) => stage = value;

  String tempRecordingPath() =>
      '${Directory.systemTemp.path}/speaking_${DateTime.now().millisecondsSinceEpoch}.m4a';

  void showMicPermissionSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Microphone permission is required.')),
    );
  }

  void startSessionTimer() {
    sessionTimer?.cancel();
    sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || stage != LearnSpeakingStage.listening) return timer.cancel();

      final next = remainingDuration - const Duration(seconds: 1);
      if (next.inSeconds <= 0) {
        remainingDuration = Duration.zero;
        setState(() {});
        timer.cancel();
        await stopAndCheck(detailBloc.state);
        return;
      }

      remainingDuration = next;
      setState(() {});
    });
  }

  Future<void> startRecording() async {
    if (detailBloc.state.detail == null) return;
    final hasPermission = await recorder.hasPermission();
    if (!hasPermission) return showMicPermissionSnack();

    final path = tempRecordingPath();
    await recorder.start(
      const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
      path: path,
    );

    if (!mounted) return;
    setStage(LearnSpeakingStage.listening);
    remainingDuration = maxSpeakingDuration;
    startSessionTimer();
    setState(() {});
  }

  void nextOrFinish(int totalQuestions) {
    final isLast = questionIndex == totalQuestions - 1;
    if (isLast) {
      setStage(LearnSpeakingStage.result);
      setState(() {});
      return;
    }

    questionIndex++;
    setStage(LearnSpeakingStage.ready);
    remainingDuration = maxSpeakingDuration;
    setState(() {});
  }

  Future<void> stopAndCheck(LearnSectionDetailState state) async {
    if (isStopping) return;
    isStopping = true;

    try {
      final audioPath = await recorder.stop();
      sessionTimer?.cancel();

      if (!mounted) return;
      if (audioPath == null || audioPath.isEmpty) {
        setStage(LearnSpeakingStage.ready);
        setState(() {});
        return;
      }

      setStage(LearnSpeakingStage.checking);
      setState(() {});
      pendingAudioPath = audioPath;
      uploadBloc.add(ImageUploadRequested(filePath: audioPath));
    } finally {
      isStopping = false;
    }
  }

  Future<void> onMicTap(LearnSectionDetailState state) async {
    if (state.status.isLoading || state.detail == null) return;
    if (getQuestionsList(state).isEmpty) return;
    switch (stage) {
      case LearnSpeakingStage.ready:
        await startRecording();
        return;
      case LearnSpeakingStage.listening:
        await stopAndCheck(state);
        return;
      case LearnSpeakingStage.checking:
      case LearnSpeakingStage.result:
        return;
    }
  }

  String formatDuration(Duration duration) {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  /// --- Widgets ---

  Row progressHeaderInfo(int totalQuestions) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Question ${questionIndex + 1}',
            style: Style.small2w4(context, color: TextColorRole.greyColor)),
        Text('Total: $totalQuestions Questions', style: Style.small2w4(context))
      ]);

  Widget progressHeader(int totalQuestions) => Column(children: [
        PageIndicator(currentIndex: questionIndex, total: totalQuestions, isExpanded: true),
        const SizedBox(height: 4),
        progressHeaderInfo(totalQuestions)
      ]);

  Widget get countdownText => Text(formatDuration(remainingDuration),
      style: Style.small3w4(context, color: TextColorRole.greyColor));

  Widget speakingView(LearnSectionDetailState state) => getQuestionsList(state).isEmpty
      ? Center(
          child: Text('No questions available.',
              style: Style.bodyw5(context, color: TextColorRole.greyColor)))
      : Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(height: 24),
          progressHeader(getQuestionsList(state).length),
          const SizedBox(height: 24),
          LearnSpeakingPromptCard(prompt: currentQuestionFor(state)?.title ?? ''),
          const SizedBox(height: 32),
          if (stage == LearnSpeakingStage.checking) const LearnSpeakingStatusBanner(),
          if (stage == LearnSpeakingStage.listening) countdownText,
          const Spacer(),
          LearnSpeakingMicButton(stage: stage, onTap: () => onMicTap(state)),
          const SizedBox(height: 12),
          Text(micStatusText, style: Style.body3w4(context, color: TextColorRole.greyColor)),
          const SizedBox(height: 12)
        ]);

  Widget get bodyChecker => BlocBuilder<LearnSectionDetailBloc, LearnSectionDetailState>(
      bloc: detailBloc,
      builder: (context, state) {
        if (stage == LearnSpeakingStage.result) {
          return const LearnQuizResultComponent();
        }
        if (state.status.isLoading && state.detail == null) {
          return const PrimaryLoadingIndicator();
        }
        return speakingView(state);
      });

  @override
  Widget build(BuildContext context) => MultiBlocListener(
          listeners: [
            BlocListener<FileUploadBloc, FileUploadState>(
                bloc: uploadBloc, listener: fileUploadListener),
            BlocListener<LearnQuestionAnswerBloc, LearnQuestionAnswerState>(
                bloc: answerBloc, listener: learnQuestionAnswerListener),
          ],
          child: Scaffold(
              backgroundColor: context.cs.surface,
              body: PrimaryBackground(
                  title: 'Listen & Tap', isScrollable: false, child: bodyChecker)));
}
