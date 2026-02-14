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
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_question_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_state.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_state.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/banners/learn_speaking_status_banner.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/buttons/learn_speaking_mic_button.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/learn_speaking_prompt_card.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum SpeakingSectionStage { ready, listening, checking, result }

class SpeakingSectionPage extends StatefulWidget {
  final SectionModel sectionModel;

  const SpeakingSectionPage({super.key, required this.sectionModel});

  @override
  State<SpeakingSectionPage> createState() => SpeakingSectionPageState();
}

class SpeakingSectionPageState extends State<SpeakingSectionPage> {
  final SectionDetailBloc detailBloc = sl<SectionDetailBloc>();
  final QuestionAnswerBloc answerBloc = sl<QuestionAnswerBloc>();
  final FileUploadBloc uploadBloc = sl<FileUploadBloc>();
  SpeakingSectionStage stage = SpeakingSectionStage.ready;
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
      detailBloc.add(SectionDetailRequested(
          sectionId: widget.sectionModel.id,
          source: widget.sectionModel.source,
          unitId: widget.sectionModel.unitId,
          lessonId: widget.sectionModel.lessonId));
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

  List<SectionQuestionModel> getQuestionsList(SectionDetailState state) {
    return state.detail?.questions ?? [];
  }

  Duration get maxSpeakingDuration => const Duration(minutes: 2);

  SectionQuestionModel? currentQuestionFor(SectionDetailState state) {
    final questions = getQuestionsList(state);
    if (questions.isEmpty) return null;
    if (questionIndex >= questions.length) questionIndex = 0;
    return questions[questionIndex];
  }

  String get micStatusText {
    if (stage == SpeakingSectionStage.listening) return 'Listening...';
    if (stage == SpeakingSectionStage.checking) return 'Checking';
    return 'Tap to record';
  }

  /// --- Listeners ---

  void fileUploadListener(_, FileUploadState state) {
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      setStage(SpeakingSectionStage.ready);
      setState(() {});
      return;
    }
    if (state.status.isSuccess && state.uploadedFile != null) {
      final currentQuestion = currentQuestionFor(detailBloc.state);
      if (currentQuestion == null) return;
      answerBloc.add(QuestionAnswerSubmitted(
          sectionId: currentQuestion.sectionId,
          questionId: currentQuestion.id,
          assignmentId: currentQuestion.assignmentId,
          unitId: currentQuestion.unitId,
          lessonId: currentQuestion.lessonId,
          userAudioId: state.uploadedFile!.id,
          source: currentQuestion.source));
      pendingAudioPath = null;
    }
  }

  void questionAnswerListener(_, QuestionAnswerState state) async {
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      setStage(SpeakingSectionStage.ready);
      setState(() {});
      nextOrFinish(getQuestionsList(detailBloc.state).length);
    }
    if (state.status.isSuccess) {
      if (!mounted) return;
      nextOrFinish(getQuestionsList(detailBloc.state).length);
    }
  }

  /// --- Methods ---

  void setStage(SpeakingSectionStage value) => stage = value;

  String tempRecordingPath() =>
      '${Directory.systemTemp.path}/speaking_${DateTime.now().millisecondsSinceEpoch}.m4a';

  void showMicPermissionSnack() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Microphone permission is required.'.tr())),
    );
  }

  void startSessionTimer() {
    sessionTimer?.cancel();
    sessionTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (!mounted || stage != SpeakingSectionStage.listening) return timer.cancel();

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
    setStage(SpeakingSectionStage.listening);
    remainingDuration = maxSpeakingDuration;
    startSessionTimer();
    setState(() {});
  }

  void nextOrFinish(int totalQuestions) {
    final isLast = questionIndex == totalQuestions - 1;
    if (isLast) {
      setStage(SpeakingSectionStage.result);
      setState(() {});
      return;
    }

    questionIndex++;
    setStage(SpeakingSectionStage.ready);
    remainingDuration = maxSpeakingDuration;
    setState(() {});
  }

  Future<void> stopAndCheck(SectionDetailState state) async {
    if (isStopping) return;
    isStopping = true;

    try {
      final audioPath = await recorder.stop();
      sessionTimer?.cancel();

      if (!mounted) return;
      if (audioPath == null || audioPath.isEmpty) {
        setStage(SpeakingSectionStage.ready);
        setState(() {});
        return;
      }

      setStage(SpeakingSectionStage.checking);
      setState(() {});
      pendingAudioPath = audioPath;
      uploadBloc.add(ImageUploadRequested(filePath: audioPath));
    } finally {
      isStopping = false;
    }
  }

  Future<void> onMicTap(SectionDetailState state) async {
    if (state.status.isLoading || state.detail == null) return;
    if (getQuestionsList(state).isEmpty) return;
    switch (stage) {
      case SpeakingSectionStage.ready:
        await startRecording();
        return;
      case SpeakingSectionStage.listening:
        await stopAndCheck(state);
        return;
      case SpeakingSectionStage.checking:
      case SpeakingSectionStage.result:
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
        Text('Question {current}'.tr(namedArgs: {
          'current': '${questionIndex + 1}'
        }), style: Style.small2w4(context, color: TextColorRole.greyColor)),
        Text('Total: {total} Questions'.tr(namedArgs: {
          'total': '$totalQuestions'
        }), style: Style.small2w4(context))
      ]);

  Widget progressHeader(int totalQuestions) => Column(children: [
        PageIndicator(currentIndex: questionIndex, total: totalQuestions, isExpanded: true),
        const SizedBox(height: 4),
        progressHeaderInfo(totalQuestions)
      ]);

  Widget get countdownText => Text(formatDuration(remainingDuration),
      style: Style.small3w4(context, color: TextColorRole.greyColor));

  Widget speakingView(SectionDetailState state) => getQuestionsList(state).isEmpty
      ? Center(
          child: Text('No questions available.'.tr(),
              style: Style.bodyw5(context, color: TextColorRole.greyColor)))
      : Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
          const SizedBox(height: 24),
          progressHeader(getQuestionsList(state).length),
          const SizedBox(height: 24),
          LearnSpeakingPromptCard(prompt: currentQuestionFor(state)?.title ?? ''),
          const SizedBox(height: 32),
          if (stage == SpeakingSectionStage.checking) const LearnSpeakingStatusBanner(),
          if (stage == SpeakingSectionStage.listening) countdownText,
          const Spacer(),
          LearnSpeakingMicButton(stage: stage, onTap: () => onMicTap(state)),
          const SizedBox(height: 12),
          Text(micStatusText, style: Style.body3w4(context, color: TextColorRole.greyColor)),
          const SizedBox(height: 12)
        ]);

  Widget get bodyChecker => BlocBuilder<SectionDetailBloc, SectionDetailState>(
      bloc: detailBloc,
      builder: (context, state) {
        if (stage == SpeakingSectionStage.result) {
          return const QuizResultComponent();
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
            BlocListener<QuestionAnswerBloc, QuestionAnswerState>(
                bloc: answerBloc, listener: questionAnswerListener),
          ],
          child: Scaffold(
              backgroundColor: context.cs.surface,
              body: PrimaryBackground(
                  title: widget.sectionModel.title, isScrollable: false, child: bodyChecker)));
}
