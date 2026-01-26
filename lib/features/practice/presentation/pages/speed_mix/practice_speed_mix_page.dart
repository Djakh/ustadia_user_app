import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/practice/data/models/speed_mix_task_model.dart';
import 'package:ustadia_user_app/features/practice/data/models/vocabulary_question.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/next_task_bloc/next_task_bloc.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_listen_tap_set_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/speed_mix/practice_speed_mix_result_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/practice_build_sentence_content.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/practice_listen_quiz_view_content.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/practice_vocabulary_content.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/practice_word_match_content.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/cards/practice_word_match_card.dart';
import 'package:ustadia_user_app/router.dart';

class PracticeSpeedMixPlayPage extends StatefulWidget {
  const PracticeSpeedMixPlayPage({super.key});

  @override
  State<PracticeSpeedMixPlayPage> createState() => PracticeSpeedMixPlayPageState();
}

class PracticeSpeedMixPlayPageState extends State<PracticeSpeedMixPlayPage> {
  static const totalSeconds = 120;
  final FlutterTts _tts = FlutterTts();

  late final List<SpeedMixTaskModel> tasks;
  int secondsLeft = totalSeconds;
  int currentIndex = 0;
  int correctCount = 0;
  int completedCount = 0;
  bool finished = false;
  Timer? _timer;
  bool _resultOpened = false;

  /// --- Gerrets ---

  SpeedMixTaskModel get currentTaskModel => tasks[currentIndex];
  bool get isSentenceTask => currentTaskModel.type == SpeedMixTaskType.sentence;

  String get currentCategory {
    switch (currentTaskModel.type) {
      case SpeedMixTaskType.vocabulary:
        return 'Vocabulary';
      case SpeedMixTaskType.listen:
        return 'Listen';
      case SpeedMixTaskType.sentence:
        return 'Order';
      case SpeedMixTaskType.wordMatch:
        return 'Word match';
    }
  }

  List<SpeedMixTaskModel> _buildTasks() => [
        const SpeedMixTaskModel(
            type: SpeedMixTaskType.listen,
            prompt: 'thank you',
            options: ['Thank you', 'Think you', 'Tank you'],
            answerIndex: 0),
        const SpeedMixTaskModel(
            type: SpeedMixTaskType.vocabulary,
            prompt: 'Opposite of “Happy”',
            options: ['Sad', 'Angry', 'Excited'],
            answerIndex: 0),
        const SpeedMixTaskModel(
            type: SpeedMixTaskType.sentence,
            prompt: 'I go to school every day',
            options: ['I', 'go', 'to', 'school', 'every', 'day'],
            answerIndex: 0),
        const SpeedMixTaskModel(
            type: SpeedMixTaskType.wordMatch,
            prompt: 'Tap pairs that belong together',
            options: ['Dog', 'Собака', 'Cat', 'Кошка', 'Water', 'Вода', 'Book', 'Книга'],
            answerIndex: 0),
      ];

  List<(String, String)> _pairsFromOptions(List<String> opts) {
    final pairs = <(String, String)>[];
    for (var i = 0; i + 1 < opts.length; i += 2) {
      pairs.add((opts[i], opts[i + 1]));
    }
    return pairs;
  }

  List<PracticeWordMatchCardData> _wordMatchSources(List<(String, String)> pairs) => List.generate(
      pairs.length,
      (index) => PracticeWordMatchCardData(pairId: index, text: pairs[index].$1));

  List<PracticeWordMatchCardData> _wordMatchTargets(List<(String, String)> pairs) => List.generate(
      pairs.length,
      (index) => PracticeWordMatchCardData(pairId: index, text: pairs[index].$2));

  PracticeListenTapQuestionModel _listenQuestionFromTask(SpeedMixTaskModel task) {
    final options = List.generate(
        task.options.length,
        (index) => PracticeListenTapOptionModel(
            id: '',
            listenTapQuestionId: '',
            word: task.options[index],
            isCorrect: index == task.answerIndex,
            order: index));
    return PracticeListenTapQuestionModel(
        id: 'speed-mix-listen-${task.prompt}',
        listenTapId: '',
        audioId: '',
        order: 0,
        options: options,
        audio: null);
  }

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    configureTts();
    context.read<NextTaskBloc>().setCurrentTaskCompleted(false, isAnswerCorrect: false);
    tasks = _buildTasks()..shuffle(Random());
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _tts.stop();
    super.dispose();
  }

  /// --- Listeners ---

  void nextPracticeListener(_, NextTaskState state) {
    if (!state.isCurrentTaskCompleted || finished) return;
    setState(() {
      completedCount++;
      if (state.isAnswerCorrect) correctCount++;
      if (currentIndex == tasks.length - 1) {
        finished = true;
        _timer?.cancel();
        _openResultPage();
      } else {
        currentIndex++;
      }
    });
    context.read<NextTaskBloc>().setCurrentTaskCompleted(false);
  }

  /// --- Methods ---

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsLeft <= 1) {
        timer.cancel();
        setState(() {
          secondsLeft = 0;
          finished = true;
          _timer = null;
        });
        _openResultPage();
      } else {
        setState(() => secondsLeft--);
      }
    });
  }

  void _openResultPage() {
    if (_resultOpened || !mounted) return;
    _resultOpened = true;
    final stats = PracticeSpeedMixResultStats(
        total: tasks.length,
        completed: completedCount,
        correct: correctCount,
        timeUp: secondsLeft == 0);
    Future.microtask(() {
      if (!mounted) return;
      context.pushReplacement(speedMixResultRoute, extra: stats);
    });
  }

  Future<void> configureTts() async {
    await _tts.setLanguage('en-US');
    await _tts.setSpeechRate(0.6);
    await _tts.setPitch(1.0);
    await _tts.setVolume(1.0);
    await _tts.awaitSpeakCompletion(true);
  }

  Future<void> _playListenPrompt(String prompt) async {
    await _tts.stop();
    await _tts.speak(prompt);
  }

  /// --- Widgets ---

  Widget get timerPill => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border16),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.watch_later, color: AppColors.primary),
          const SizedBox(width: 4),
          Text('${secondsLeft ~/ 60}:${(secondsLeft % 60).toString().padLeft(2, '0')}',
              style: Style.small3w4(context))
        ]),
      );

  Widget get taskNumber => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(shape: BoxShape.circle, color: context.cs.surface),
      child: Text('${currentIndex + 1}',
          style: Style.bodyw4(context, color: TextColorRole.greyColor)));

  Widget get header => Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [timerPill, taskNumber]),
      ]);

  Widget get currentTaskBody {
    switch (currentTaskModel.type) {
      case SpeedMixTaskType.vocabulary:
        return PracticeVocabularyContent(
            key: ValueKey('vocab-$currentIndex'),
            vocabularyModel: VocabularyModel(
                category: 'Vocabulary',
                prompt: currentTaskModel.prompt,
                options: currentTaskModel.options,
                answerIndex: currentTaskModel.answerIndex));
      case SpeedMixTaskType.listen:
        return PracticeListenQuizViewContent(
            key: ValueKey('listen-$currentIndex'),
            question: _listenQuestionFromTask(currentTaskModel),
            onPlay: () => _playListenPrompt(currentTaskModel.prompt),
            isLoading: false);
      case SpeedMixTaskType.sentence:
        return PracticeBuildSentenceContent(
            key: ValueKey('sentence-$currentIndex'), correctOrder: currentTaskModel.options);
      case SpeedMixTaskType.wordMatch:
        final pairs = _pairsFromOptions(currentTaskModel.options);
        return PracticeWordMatchContent(
            key: ValueKey('wordmatch-$currentIndex'),
            sources: _wordMatchSources(pairs),
            targets: _wordMatchTargets(pairs));
    }
  }

  Widget get view => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          header,
          const SizedBox(height: 12),
          if (isSentenceTask) ...[
            Expanded(child: Center(child: currentTaskBody)),
            const SizedBox(height: 16),
            Text('Answer as many as you can!',
                style: Style.small3w4(context, color: TextColorRole.greyColor)),
          ] else ...[
            currentTaskBody,
            const SizedBox(height: 20),
            Text('Answer as many as you can!',
                style: Style.small3w4(context, color: TextColorRole.greyColor)),
          ],
        ],
      );

  @override
  Widget build(BuildContext context) => BlocListener<NextTaskBloc, NextTaskState>(
      listener: nextPracticeListener,
      child: Scaffold(
          backgroundColor: context.cs.surface,
          body: PrimaryBackground(
              title: 'Speed Mix',
              isScrollable: !isSentenceTask,
              child: isSentenceTask ? SizedBox.expand(child: view) : view)));
}
