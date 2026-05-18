import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/practice/data/models/monkey_type_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_session_bloc/monkey_type_session_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_session_bloc/monkey_type_session_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_session_bloc/monkey_type_session_state.dart';
import 'package:ustadia_user_app/injection_container.dart';

class MonkeyTypeSessionPage extends StatefulWidget {
  final MonkeyTypePracticeModel practice;

  const MonkeyTypeSessionPage({super.key, required this.practice});

  @override
  State<MonkeyTypeSessionPage> createState() => _MonkeyTypeSessionPageState();
}

class _MonkeyTypeSessionPageState extends State<MonkeyTypeSessionPage> {
  final MonkeyTypeSessionBloc sessionBloc = sl<MonkeyTypeSessionBloc>();
  final TextEditingController controller = TextEditingController();
  final Stopwatch stopwatch = Stopwatch();
  Timer? timer;
  int activeTextIndex = 0;
  int elapsedSeconds = 0;
  bool hasSubmitted = false;

  @override
  void initState() {
    super.initState();
    sessionBloc.add(MonkeyTypeTextsRequested(practiceId: widget.practice.id));
    controller.addListener(onTypingChanged);
  }

  @override
  void dispose() {
    timer?.cancel();
    stopwatch.stop();
    controller
      ..removeListener(onTypingChanged)
      ..dispose();
    sessionBloc.close();
    super.dispose();
  }

  String targetText(List<MonkeyTypeTextModel> texts) =>
      texts.isEmpty ? '' : texts[activeTextIndex.clamp(0, texts.length - 1)].text;

  int correctChars(String typed, String target) {
    final count = typed.length < target.length ? typed.length : target.length;
    var correct = 0;
    for (var i = 0; i < count; i++) {
      if (typed[i] == target[i]) correct++;
    }
    return correct;
  }

  int get effectiveSeconds => elapsedSeconds == 0 ? 1 : elapsedSeconds;

  double wpm(String typed) => typed.trim().isEmpty
      ? 0
      : ((typed.length / 5) / (effectiveSeconds / 60)).clamp(0, 999).toDouble();

  double accuracy(String typed, String target) {
    if (typed.isEmpty) return 0;
    return (correctChars(typed, target) / typed.length * 100).clamp(0, 100).toDouble();
  }

  bool isComplete(String typed, String target) =>
      typed.length >= target.length && target.isNotEmpty;

  void startTimer() {
    if (stopwatch.isRunning) return;
    stopwatch.start();
    timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => elapsedSeconds = stopwatch.elapsed.inSeconds));
  }

  void onTypingChanged() {
    if (controller.text.isNotEmpty) startTimer();
    setState(() {});
  }

  void resetCurrentText() {
    controller.clear();
    stopwatch
      ..reset()
      ..stop();
    timer?.cancel();
    timer = null;
    setState(() {
      elapsedSeconds = 0;
      hasSubmitted = false;
    });
  }

  void previousText() {
    if (activeTextIndex == 0) return;
    setState(() => activeTextIndex--);
    resetCurrentText();
  }

  void nextText(List<MonkeyTypeTextModel> texts) {
    if (activeTextIndex >= texts.length - 1) return;
    setState(() => activeTextIndex++);
    resetCurrentText();
  }

  void submitAnswer(List<MonkeyTypeTextModel> texts) {
    final target = targetText(texts);
    final typed = controller.text;
    if (typed.trim().isEmpty || hasSubmitted) return;
    stopwatch.stop();
    timer?.cancel();
    setState(() {
      elapsedSeconds = stopwatch.elapsed.inSeconds;
      hasSubmitted = true;
    });
    sessionBloc.add(MonkeyTypeAnswerSubmitted(
        practiceId: widget.practice.id,
        text: typed,
        wpm: double.parse(wpm(typed).toStringAsFixed(1)),
        accuracy: accuracy(typed, target),
        correctChars: correctChars(typed, target),
        totalChars: typed.length,
        timeTakenSeconds: effectiveSeconds));
  }

  Widget statBox(BuildContext context, String title, String value) => Expanded(
      child: PrimaryBox(
          isTappable: false,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(children: [
            Text(value, style: Style.body2w7(context).copyWith(color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(title, style: Style.small2w4(context, color: TextColorRole.greyColor))
          ])));

  Widget targetTextView(String target, String typed) => PrimaryBox(
      isTappable: false,
      width: double.infinity,
      child: Wrap(
          children: List.generate(target.length, (index) {
        final hasTyped = index < typed.length;
        final isCorrect = hasTyped && typed[index] == target[index];
        return Text(target[index],
            style: Style.body2w5(context).copyWith(
                color: !hasTyped
                    ? context.cs.onSurface
                    : isCorrect
                        ? AppColors.primary
                        : AppColors.error,
                backgroundColor:
                    index == typed.length ? AppColors.primary.withValues(alpha: 0.12) : null));
      })));

  Widget resultPanel(BuildContext context, String typed, String target) => PrimaryBox(
      isTappable: false,
      backgroundColor: AppColors.greenE7,
      child: Row(children: [
        const Icon(Icons.check_circle_rounded, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
            child: Text(
                '${'Saved'.tr()} • ${wpm(typed).toStringAsFixed(0)} WPM • ${accuracy(typed, target).toStringAsFixed(0)}%',
                style: Style.small3w5(context)))
      ]));

  Widget textProgress(List<MonkeyTypeTextModel> texts) => Row(children: [
        Text(
            'Text {current} of {total}'.tr(namedArgs: {
              'current': '${activeTextIndex + 1}',
              'total': '${texts.length}',
            }),
            style: Style.bodyw7(context))
      ]);

  Widget navigationButtons(List<MonkeyTypeTextModel> texts) => Row(children: [
        Expanded(
            child: Button.border(
                onTap: previousText,
                isAvialable: activeTextIndex > 0,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.chevron_left_rounded, size: 20),
                  const SizedBox(width: 4),
                  Text('Previous'.tr())
                ]))),
        const SizedBox(width: 10),
        Expanded(
            child: Button.border(
                onTap: () => nextText(texts),
                isAvialable: activeTextIndex < texts.length - 1,
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Next'.tr()),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right_rounded, size: 20),
                ])))
      ]);

  Widget sessionView(
      BuildContext context, List<MonkeyTypeTextModel> texts, MonkeyTypeSessionState state) {
    final target = targetText(texts);
    final typed = controller.text;
    final isLast = activeTextIndex >= texts.length - 1;
    return ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
      const SizedBox(height: 20),
      Text(widget.practice.description,
          style: Style.small3w4(context, color: TextColorRole.greyColor)),
      const SizedBox(height: 16),
      textProgress(texts),
      const SizedBox(height: 10),
      Row(children: [
        statBox(context, 'WPM'.tr(), wpm(typed).toStringAsFixed(0)),
        const SizedBox(width: 8),
        statBox(context, 'Accuracy'.tr(), '${accuracy(typed, target).toStringAsFixed(0)}%'),
        const SizedBox(width: 8),
        statBox(context, 'Time'.tr(), '${elapsedSeconds}s')
      ]),
      const SizedBox(height: 16),
      targetTextView(target, typed),
      const SizedBox(height: 14),
      TextField(
          controller: controller,
          minLines: 5,
          maxLines: 8,
          enabled: !state.submitStatus.isLoading && !hasSubmitted,
          decoration: InputDecoration(
              hintText: 'Start typing'.tr(),
              filled: true,
              fillColor: context.cs.surface,
              suffixIcon: controller.text.isEmpty && !hasSubmitted
                  ? null
                  : IconButton(
                      tooltip: 'Clear'.tr(),
                      onPressed: resetCurrentText,
                      icon: const Icon(Icons.cancel_rounded)),
              border: OutlineInputBorder(borderRadius: Style.border20),
              enabledBorder: OutlineInputBorder(
                  borderRadius: Style.border20,
                  borderSide: const BorderSide(color: AppColors.grayF4)))),
      const SizedBox(height: 14),
      if (state.submitStatus.isSuccess && hasSubmitted) resultPanel(context, typed, target),
      if (state.submitStatus.isError && state.submitErrorMessage != null)
        Text(state.submitErrorMessage!,
            style: Style.small3w4(context).copyWith(color: AppColors.error)),
      const SizedBox(height: 14),
      Button.primary(
          onTap: () => hasSubmitted && !isLast ? nextText(texts) : submitAnswer(texts),
          isLoading: state.submitStatus.isLoading,
          isAvialable: typed.trim().isNotEmpty,
          text: hasSubmitted && !isLast ? 'Next text'.tr() : 'Submit'.tr()),
      const SizedBox(height: 10),
      navigationButtons(texts),
      const SizedBox(height: 80),
    ]);
  }

  Widget get contentChecker =>
      BlocStatusView<MonkeyTypeSessionBloc, MonkeyTypeSessionState, List<MonkeyTypeTextModel>>(
          bloc: sessionBloc,
          statusOf: (state) => state.status,
          errorOf: (state) => state.errorMessage,
          data: (state) => state.texts,
          isEmpty: (texts) => texts.isEmpty,
          keepDataOnLoading: false,
          loading: const PrimaryLoadingIndicator(height: 30, width: 30),
          empty: Center(child: Text('No texts found'.tr())),
          builder: (context, texts) => sessionView(context, texts, sessionBloc.state));

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(title: widget.practice.title, child: contentChecker));
}
