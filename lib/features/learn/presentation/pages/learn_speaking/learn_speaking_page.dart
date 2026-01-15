import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:record/record.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/banners/learn_speaking_status_banner.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/buttons/learn_speaking_mic_button.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/learn_speaking_prompt_card.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_result_component.dart';

enum LearnSpeakingStage { ready, listening, checking, result }

class LearnSpeakingPage extends StatefulWidget {
  final LearnSectionModel lesson;

  const LearnSpeakingPage({super.key, required this.lesson});

  @override
  State<LearnSpeakingPage> createState() => LearnSpeakingPageState();
}

class LearnSpeakingPageState extends State<LearnSpeakingPage> {
  LearnSpeakingStage stage = LearnSpeakingStage.ready;
  int questionIndex = 0;
  int correctCount = 0;
  bool isCurrentAnswerCorrect = true;
  bool isStopping = false;
  final AudioRecorder recorder = AudioRecorder();
  Timer? sessionTimer;
  Duration remainingDuration = Duration.zero;

  /// --- Life cycle ---

  @override
  void dispose() {
    sessionTimer?.cancel();
    recorder.dispose();
    super.dispose();
  }

  /// --- Getters ---

  List<String> get prompts => const [
        'Introduce yourself',
        'Describe your hometown',
        'Talk about your hobbies',
        'Explain your daily routine',
        'Share your goals'
      ];

  List<bool> get results => const [false, true, true, false, true];

  Duration get maxSpeakingDuration => const Duration(minutes: 2);

  String get currentPrompt => prompts[questionIndex];

  String get micStatusText {
    if (stage == LearnSpeakingStage.listening) return 'Listening...';
    if (stage == LearnSpeakingStage.checking) return 'Checking';
    return 'Tap to record';
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
        await stopAndCheck();
        return;
      }

      remainingDuration = next;
      setState(() {});
    });
  }

  Future<void> startRecording() async {
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

  Future<bool> checkPronunciation(String audioPath) async {
    if (audioPath.isEmpty) return false;
    await Future.delayed(const Duration(milliseconds: 900));
    return results[questionIndex % results.length];
  }

  void nextOrFinish() {
    final isLast = questionIndex == prompts.length - 1;
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

  Future<void> stopAndCheck() async {
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

      final isCorrect = await checkPronunciation(audioPath);

      if (!mounted) return;
      isCurrentAnswerCorrect = isCorrect;
      if (isCorrect) correctCount++;
      setState(() {});

      await Future.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      nextOrFinish();
    } finally {
      isStopping = false;
    }
  }

  Future<void> onMicTap() async {
    switch (stage) {
      case LearnSpeakingStage.ready:
        await startRecording();
        return;
      case LearnSpeakingStage.listening:
        await stopAndCheck();
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

  Row progressHeaderInfo() => Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text('Question ${questionIndex + 1}',
            style: Style.small2w4(context, color: TextColorRole.greyColor)),
        Text('Total: ${prompts.length} Questions', style: Style.small2w4(context))
      ]);

  Widget get progressHeader => Column(children: [
        PageIndicator(currentIndex: questionIndex, total: prompts.length, isExpanded: true),
        const SizedBox(height: 4),
        progressHeaderInfo()
      ]);

  Widget get countdownText => Text(formatDuration(remainingDuration),
      style: Style.small3w4(context, color: TextColorRole.greyColor));

  Widget get speakingView => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        const SizedBox(height: 24),
        progressHeader,
        const SizedBox(height: 24),
        LearnSpeakingPromptCard(prompt: currentPrompt),
        const SizedBox(height: 32),
        if (stage == LearnSpeakingStage.checking)
          LearnSpeakingStatusBanner(isSuccess: isCurrentAnswerCorrect),
        if (stage == LearnSpeakingStage.listening) countdownText,
        const Spacer(),
        LearnSpeakingMicButton(stage: stage, onTap: onMicTap),
        const SizedBox(height: 12),
        Text(micStatusText, style: Style.body3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 12)
      ]);

  Widget get view {
    if (stage == LearnSpeakingStage.result)
      return LearnQuizResultComponent(correctCount: correctCount, quizLength: prompts.length);
    return speakingView;
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(title: 'Listen & Tap', isScrollable: false, child: view));
}
