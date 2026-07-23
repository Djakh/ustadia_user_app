import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/practice/data/models/monkey_type_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_session_bloc/monkey_type_session_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_session_bloc/monkey_type_session_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_session_bloc/monkey_type_session_state.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';

class MonkeyTypeSessionPage extends StatefulWidget {
  final MonkeyTypePracticeModel practice;

  const MonkeyTypeSessionPage({super.key, required this.practice});

  @override
  State<MonkeyTypeSessionPage> createState() => _MonkeyTypeSessionPageState();
}

class _MonkeyTypeSessionPageState extends State<MonkeyTypeSessionPage> {
  final MonkeyTypeSessionBloc sessionBloc = sl<MonkeyTypeSessionBloc>();
  final TextEditingController controller = TextEditingController();
  final FocusNode typingFocusNode = FocusNode(debugLabel: 'monkey_type_typing_focus');
  final ScrollController targetScrollController = ScrollController();
  final Stopwatch stopwatch = Stopwatch();
  final GlobalKey progressKey = GlobalKey(debugLabel: 'monkey_type_progress');
  final GlobalKey statsKey = GlobalKey(debugLabel: 'monkey_type_stats');
  final GlobalKey targetTextKey = GlobalKey(debugLabel: 'monkey_type_target_text');
  final GlobalKey inputKey = GlobalKey(debugLabel: 'monkey_type_input');
  final GlobalKey submitKey = GlobalKey(debugLabel: 'monkey_type_submit');
  final GlobalKey navigationKey = GlobalKey(debugLabel: 'monkey_type_navigation');
  Timer? timer;
  int activeTextIndex = 0;
  int elapsedSeconds = 0;
  bool hasSubmitted = false;
  String? positionedTextId;
  bool isClampingControllerText = false;
  double typingTextWidth = 0;
  double typingViewportHeight = 0;

  @override
  void initState() {
    super.initState();
    sessionBloc.add(MonkeyTypeTextsRequested(practiceId: widget.practice.id));
    controller.addListener(onTypingChanged);
    typingFocusNode.addListener(onTypingFocusChanged);
  }

  @override
  void dispose() {
    timer?.cancel();
    stopwatch.stop();
    controller
      ..removeListener(onTypingChanged)
      ..dispose();
    typingFocusNode.removeListener(onTypingFocusChanged);
    typingFocusNode.dispose();
    targetScrollController.dispose();
    sessionBloc.close();
    super.dispose();
  }

  String normalizePrompt(String value) =>
      value.replaceAll(RegExp(r'[–—]'), '-').replaceAll(RegExp(r'\s+'), ' ').trim();

  List<String> charactersOf(String value) => value.characters.toList(growable: false);

  /// Normalizes only input variants produced by mobile keyboards.  The text is
  /// still displayed exactly as supplied by the practice, but curly quotes,
  /// long dashes, case and non-breaking spaces are not treated as mistakes.
  String comparisonCharacter(String value) => value
      .replaceAll(RegExp(r'[\u00A0\u202F\t\n\r]'), ' ')
      .replaceAll(RegExp(r'[‘’‚‛]'), "'")
      .replaceAll(RegExp(r'[“”„‟]'), '"')
      .replaceAll(RegExp(r'[‐‑‒–—−]'), '-')
      .toLowerCase();

  bool charactersMatch(String typedCharacter, String targetCharacter) =>
      comparisonCharacter(typedCharacter) == comparisonCharacter(targetCharacter);

  String targetText(List<MonkeyTypeTextModel> texts) =>
      texts.isEmpty ? '' : normalizePrompt(texts[activeTextIndex.clamp(0, texts.length - 1)].text);

  int correctChars(String typed, String target) {
    final typedCharacters = charactersOf(typed);
    final targetCharacters = charactersOf(target);
    final count = typedCharacters.length < targetCharacters.length
        ? typedCharacters.length
        : targetCharacters.length;
    var correct = 0;
    for (var i = 0; i < count; i++) {
      if (charactersMatch(typedCharacters[i], targetCharacters[i])) correct++;
    }
    return correct;
  }

  int get effectiveSeconds => elapsedSeconds == 0 ? 1 : elapsedSeconds;

  double wpm(String typed) => typed.trim().isEmpty
      ? 0
      : ((charactersOf(typed).length / 5) / (effectiveSeconds / 60)).clamp(0, 999).toDouble();

  double accuracy(String typed, String target) {
    if (typed.isEmpty) return 0;
    return (correctChars(typed, target) / typed.length * 100).clamp(0, 100).toDouble();
  }

  bool isComplete(String typed, String target) =>
      charactersOf(typed).length >= charactersOf(target).length && target.isNotEmpty;

  void startTimer() {
    if (stopwatch.isRunning) return;
    stopwatch.start();
    timer = Timer.periodic(const Duration(seconds: 1),
        (_) => setState(() => elapsedSeconds = stopwatch.elapsed.inSeconds));
  }

  void onTypingChanged() {
    if (isClampingControllerText) return;
    final target = targetText(sessionBloc.state.texts);
    final typedCharacters = charactersOf(controller.text);
    final targetCharacters = charactersOf(target);
    if (target.isNotEmpty && typedCharacters.length > targetCharacters.length) {
      final shortenedText = typedCharacters.take(targetCharacters.length).join();
      isClampingControllerText = true;
      controller.value = TextEditingValue(
          text: shortenedText, selection: TextSelection.collapsed(offset: shortenedText.length));
      isClampingControllerText = false;
    }
    if (controller.text.isNotEmpty) startTimer();
    scrollTypingSurfaceToCursor(controller.text, target);
    if (isComplete(controller.text, target) && !hasSubmitted) {
      submitAnswer(sessionBloc.state.texts);
      return;
    }
    setState(() {});
  }

  void onTypingFocusChanged() {
    if (mounted) setState(() {});
  }

  void resetCurrentText() {
    controller.clear();
    typingFocusNode.requestFocus();
    resetTypingPosition();
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
    setState(() {
      activeTextIndex--;
      positionedTextId = null;
    });
    resetCurrentText();
  }

  void nextText(List<MonkeyTypeTextModel> texts) {
    if (activeTextIndex >= texts.length - 1) return;
    setState(() {
      activeTextIndex++;
      positionedTextId = null;
    });
    resetCurrentText();
  }

  void resetTypingPosition() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (targetScrollController.hasClients) targetScrollController.jumpTo(0);
    });
  }

  void scrollTypingSurfaceToCursor(String typed, String target) {
    if (target.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !targetScrollController.hasClients) return;
      final maxScroll = targetScrollController.position.maxScrollExtent;
      if (maxScroll <= 0) return;
      final textWidth = typingTextWidth;
      final viewportHeight = typingViewportHeight;
      if (textWidth <= 0 || viewportHeight <= 0) return;
      final painter = TextPainter(
          text: TextSpan(text: target, style: typingTextStyle(context)),
          textDirection: Directionality.of(context),
          maxLines: null)
        ..layout(maxWidth: textWidth);
      final targetCharacters = charactersOf(target);
      final typedCount = charactersOf(typed).length.clamp(0, targetCharacters.length).toInt();
      final targetTextOffset = targetCharacters.take(typedCount).join().length;
      final cursorOffset =
          painter.getOffsetForCaret(TextPosition(offset: targetTextOffset), Rect.zero);
      final desiredOffset = (cursorOffset.dy - viewportHeight * 0.42).clamp(0.0, maxScroll);
      targetScrollController.animateTo(
        desiredOffset,
        duration: const Duration(milliseconds: 140),
        curve: Curves.easeOut,
      );
    });
  }

  void positionAtCurrentTextStart(List<MonkeyTypeTextModel> texts) {
    if (texts.isEmpty) return;
    final text = texts[activeTextIndex.clamp(0, texts.length - 1)];
    if (positionedTextId == text.id) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      resetTypingPosition();
      positionedTextId = text.id;
      typingFocusNode.requestFocus();
    });
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
        totalChars: charactersOf(typed).length,
        timeTakenSeconds: effectiveSeconds));
  }

  Future<void> copyPracticeLink(String url) async {
    await Clipboard.setData(ClipboardData(text: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Link copied'.tr())));
  }

  Future<void> openPracticeLink(String url) async {
    final uri = Uri.tryParse(url);
    final isWebLink = uri != null && (uri.scheme == 'https' || uri.scheme == 'http');
    if (!isWebLink) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invalid link'.tr())));
      }
      return;
    }
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Could not open link'.tr())));
    }
  }

  Future<void> showPracticeLinkSheet(String url) => showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
          child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ListTile(
                    leading: const Icon(Icons.copy_rounded),
                    title: Text('Copy link'.tr()),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      copyPracticeLink(url);
                    }),
                ListTile(
                    leading: const Icon(Icons.open_in_browser_rounded),
                    title: Text('Open in browser'.tr()),
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      openPracticeLink(url);
                    })
              ]))));

  Widget practiceLinkButton(String url) => Button.border(
      onTap: () => showPracticeLinkSheet(url),
      height: 44,
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const Icon(Icons.link_rounded, size: 18),
        const SizedBox(width: 8),
        Text('Practice link'.tr())
      ]));

  Widget statBox(BuildContext context, String title, String value) => Expanded(
      child: PrimaryBox(
          isTappable: false,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
          child: Column(children: [
            Text(value, style: Style.body2w7(context).copyWith(color: AppColors.primary)),
            const SizedBox(height: 4),
            Text(title, style: Style.small2w4(context, color: TextColorRole.greyColor))
          ])));

  TextStyle typingTextStyle(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final fontSize = width < 380 ? 16.0 : 17.0;
    return Style.bodyw6(context).copyWith(fontSize: fontSize, height: 1.55, letterSpacing: 0.1);
  }

  int? firstIncorrectCharacterIndex(List<String> targetCharacters, List<String> typedCharacters) {
    final count = typedCharacters.length < targetCharacters.length
        ? typedCharacters.length
        : targetCharacters.length;
    for (var index = 0; index < count; index++) {
      if (!charactersMatch(typedCharacters[index], targetCharacters[index])) return index;
    }
    return null;
  }

  TextSpan charSpan(BuildContext context, List<String> targetCharacters,
      List<String> typedCharacters, int index, int? firstIncorrectIndex) {
    final targetCharacter = targetCharacters[index];
    final hasTyped = index < typedCharacters.length;
    final isCorrect = hasTyped && charactersMatch(typedCharacters[index], targetCharacter);
    final isBlockedByEarlierMistake = firstIncorrectIndex != null && index > firstIncorrectIndex;
    final isCursor = index == typedCharacters.length && !hasSubmitted;
    final baseStyle = typingTextStyle(context);
    return TextSpan(
        // A middle dot makes every required space visible without moving the
        // text as the user types. It is particularly useful on a phone.
        text: targetCharacter == ' ' ? '·' : targetCharacter,
        style: baseStyle.copyWith(
            color: !hasTyped || isBlockedByEarlierMistake
                ? AppColors.gray500
                : isCorrect
                    ? AppColors.primary
                    : AppColors.error,
            decoration: isCursor ? TextDecoration.underline : TextDecoration.none,
            decorationColor: AppColors.primary,
            decorationThickness: 2.4));
  }

  List<InlineSpan> typingSpans(BuildContext context, String target, String typed) {
    final targetCharacters = charactersOf(target);
    final typedCharacters = charactersOf(typed);
    final firstIncorrectIndex = firstIncorrectCharacterIndex(targetCharacters, typedCharacters);
    final spans = <InlineSpan>[];
    for (var index = 0; index < targetCharacters.length; index++) {
      spans.add(charSpan(context, targetCharacters, typedCharacters, index, firstIncorrectIndex));
    }
    return spans;
  }

  Widget hiddenKeyboardInput(MonkeyTypeSessionState state) => SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Opacity(
          opacity: 0.01,
          child: TextField(
              focusNode: typingFocusNode,
              controller: controller,
              autofocus: true,
              enabled: !state.submitStatus.isLoading && !hasSubmitted,
              enableInteractiveSelection: false,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              smartDashesType: SmartDashesType.disabled,
              smartQuotesType: SmartQuotesType.disabled,
              expands: true,
              maxLines: null,
              minLines: null,
              keyboardType: TextInputType.text,
              textInputAction: TextInputAction.done,
              scrollPhysics: const NeverScrollableScrollPhysics(),
              showCursor: false,
              style: const TextStyle(color: Colors.transparent, fontSize: 1),
              cursorColor: Colors.transparent,
              decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.zero))));

  Widget targetTextView(String target, String typed, MonkeyTypeSessionState state) =>
      GestureDetector(
          key: inputKey,
          behavior: HitTestBehavior.opaque,
          onTap: () => typingFocusNode.requestFocus(),
          child: Container(
              decoration: BoxDecoration(
                  color: context.cs.surface,
                  borderRadius: Style.border20,
                  border: Border.all(
                      color: typingFocusNode.hasFocus
                          ? AppColors.primary.withValues(alpha: 0.7)
                          : AppColors.gray300.withValues(alpha: 0.55),
                      width: typingFocusNode.hasFocus ? 1.4 : 1)),
              child: ClipRRect(
                  borderRadius: Style.border20,
                  child: LayoutBuilder(builder: (context, constraints) {
                    const horizontalPadding = 16.0;
                    typingTextWidth =
                        (constraints.maxWidth - horizontalPadding * 2).clamp(0, double.infinity);
                    typingViewportHeight = constraints.maxHeight;
                    return Stack(children: [
                      Scrollbar(
                          controller: targetScrollController,
                          thumbVisibility: target.length > 420,
                          child: SingleChildScrollView(
                              controller: targetScrollController,
                              padding: const EdgeInsets.fromLTRB(
                                  horizontalPadding, 16, horizontalPadding, 20),
                              child: Text.rich(
                                key: const ValueKey('monkey_type_target_rich_text'),
                                TextSpan(children: typingSpans(context, target, typed)),
                                textAlign: TextAlign.start,
                              ))),
                      Positioned.fill(child: IgnorePointer(child: hiddenKeyboardInput(state))),
                      if (!typingFocusNode.hasFocus && typed.isEmpty && !hasSubmitted)
                        Positioned.fill(
                            child: IgnorePointer(
                                child: Center(
                                    child: Container(
                                        padding:
                                            const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                        decoration: BoxDecoration(
                                            color: AppColors.gray900.withValues(alpha: 0.72),
                                            borderRadius: Style.border16),
                                        child: Text('Tap here and start typing'.tr(),
                                            style: Style.small2w5(context)
                                                .copyWith(color: AppColors.white))))))
                    ]);
                  }))));

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

  Widget navigationButtons(List<MonkeyTypeTextModel> texts) => KeyedSubtree(
      key: navigationKey,
      child: Row(children: [
        Expanded(
            child: Button.border(
                onTap: previousText,
                isAvialable: activeTextIndex > 0,
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      const Icon(Icons.chevron_left_rounded, size: 20),
                      const SizedBox(width: 4),
                      Text('Previous'.tr())
                    ])))),
        const SizedBox(width: 10),
        Expanded(
            child: Button.border(
                onTap: () => nextText(texts),
                isAvialable: activeTextIndex < texts.length - 1,
                child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      Text('Next'.tr()),
                      const SizedBox(width: 4),
                      const Icon(Icons.chevron_right_rounded, size: 20),
                    ]))))
      ]));

  Widget topBar(BuildContext context) => Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(children: [
        Material(
            color: context.cs.secondaryContainer,
            shape: const CircleBorder(),
            child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).maybePop(),
                child: const SizedBox(
                    width: 44, height: 44, child: Icon(Icons.chevron_left_rounded, size: 30)))),
        const SizedBox(width: 14),
        Expanded(
            child: Text(widget.practice.title,
                maxLines: 1, overflow: TextOverflow.ellipsis, style: Style.body3w7(context)))
      ]));

  Widget sessionView(
      BuildContext context, List<MonkeyTypeTextModel> texts, MonkeyTypeSessionState state) {
    positionAtCurrentTextStart(texts);
    final target = targetText(texts);
    final typed = controller.text;
    final practice = state.practice ?? widget.practice;
    final practiceUrl = practice.monkeyTypeUrl;
    final keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    return LayoutBuilder(builder: (context, constraints) {
      final compact = constraints.maxHeight < 560 || keyboardOpen;
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        if (!compact && practice.description.trim().isNotEmpty) ...[
          Text(practice.description,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Style.small3w4(context, color: TextColorRole.greyColor)),
          const SizedBox(height: 8),
        ],
        if (practiceUrl != null && !keyboardOpen && !compact) ...[
          practiceLinkButton(practiceUrl),
          const SizedBox(height: 10),
        ],
        KeyedSubtree(key: progressKey, child: textProgress(texts)),
        const SizedBox(height: 8),
        KeyedSubtree(
            key: statsKey,
            child: Row(children: [
              statBox(context, 'WPM'.tr(), wpm(typed).toStringAsFixed(0)),
              const SizedBox(width: 8),
              statBox(context, 'Accuracy'.tr(), '${accuracy(typed, target).toStringAsFixed(0)}%'),
              const SizedBox(width: 8),
              statBox(context, 'Time'.tr(), '${elapsedSeconds}s')
            ])),
        const SizedBox(height: 10),
        Expanded(
            child: KeyedSubtree(key: targetTextKey, child: targetTextView(target, typed, state))),
        const SizedBox(height: 10),
        if (state.submitStatus.isSuccess && hasSubmitted) ...[
          resultPanel(context, typed, target),
          const SizedBox(height: 8),
        ],
        if (state.submitStatus.isError && state.submitErrorMessage != null) ...[
          Text(state.submitErrorMessage!,
              style: Style.small3w4(context).copyWith(color: AppColors.error)),
          const SizedBox(height: 8),
        ],
        KeyedSubtree(
            key: submitKey,
            child: Button.primary(
                onTap: hasSubmitted ? resetCurrentText : () => submitAnswer(texts),
                isLoading: state.submitStatus.isLoading,
                isAvialable: hasSubmitted || typed.trim().isNotEmpty,
                text: hasSubmitted ? 'Repeat'.tr() : 'Submit'.tr())),
        if (texts.length > 1 && !keyboardOpen) ...[
          const SizedBox(height: 10),
          navigationButtons(texts),
        ],
      ]);
    });
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
      resizeToAvoidBottomInset: true,
      body: GuidedTutorialPage(
          pageId: '${TutorialPageIds.practiceSession}.monkey_type',
          steps: TutorialPresets.monkeyTypePractice(
              progressKey: progressKey,
              statsKey: statsKey,
              targetTextKey: targetTextKey,
              inputKey: inputKey,
              submitKey: submitKey,
              navigationKey: navigationKey),
          child: SafeArea(
              child: Column(children: [
            topBar(context),
            Expanded(
                child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12), child: contentChecker))
          ]))));
}
