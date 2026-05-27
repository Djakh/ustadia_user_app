import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_mascot.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_storage_service.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/injection_container.dart';

class GuidedTutorialPage extends StatefulWidget {
  final String pageId;
  final List<String> additionalCompletedPageIds;
  final List<TutorialStepModel> steps;
  final Widget child;
  final bool enabled;

  const GuidedTutorialPage({
    super.key,
    required this.pageId,
    this.additionalCompletedPageIds = const [],
    required this.steps,
    required this.child,
    this.enabled = true,
  });

  @override
  State<GuidedTutorialPage> createState() => _GuidedTutorialPageState();
}

class _GuidedTutorialPageState extends State<GuidedTutorialPage> {
  bool didScheduleStart = false;
  bool didAttemptStart = false;

  @override
  void didUpdateWidget(covariant GuidedTutorialPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.pageId != widget.pageId) {
      didScheduleStart = false;
      didAttemptStart = false;
    }
  }

  void scheduleStartIfNeeded() {
    if (!widget.enabled || widget.steps.isEmpty || didScheduleStart || didAttemptStart) return;
    if (!TickerMode.of(context)) return;
    didScheduleStart = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      didScheduleStart = false;
      maybeStartTutorial();
    });
  }

  Future<void> maybeStartTutorial() async {
    if (!mounted || didAttemptStart || !TickerMode.of(context)) return;
    final storage = sl<TutorialStorageService>();
    if (!storage.shouldConsiderPage(widget.pageId)) {
      didAttemptStart = true;
      return;
    }
    if (GuidedTutorialRuntime.isActive) return;
    didAttemptStart = true;

    final shouldRun = await resolveTutorialConsent(storage);
    if (!mounted || !shouldRun) return;

    await GuidedTutorialOverlay.show(context: context, steps: widget.steps);
    await storage.markPageCompleted(widget.pageId);
    for (final pageId in widget.additionalCompletedPageIds) {
      await storage.markPageCompleted(pageId);
    }
  }

  Future<bool> resolveTutorialConsent(TutorialStorageService storage) async {
    if (storage.isPromptAnswered) return storage.isEnabled;
    final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => const TutorialOptInDialog());
    final accepted = result == true;
    await storage.setTutorialEnabled(accepted);
    return accepted;
  }

  @override
  Widget build(BuildContext context) {
    scheduleStartIfNeeded();
    return widget.child;
  }
}

class TutorialOptInDialog extends StatelessWidget {
  const TutorialOptInDialog({super.key});

  @override
  Widget build(BuildContext context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      shape: RoundedRectangleBorder(borderRadius: Style.border24),
      child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const TutorialMascot(size: 92),
            const SizedBox(height: 12),
            Text('Want a quick guided tour?'.tr(),
                textAlign: TextAlign.center, style: Style.body2w7(context)),
            const SizedBox(height: 8),
            Text(
                'I can show the important buttons only when you open each page. Short, useful, and no homework, promise.'
                    .tr(),
                textAlign: TextAlign.center,
                style: Style.bodyw4(context, color: TextColorRole.greyColor)),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                  child: Button.border(
                      onTap: () => Navigator.of(context).pop(false),
                      text: 'No'.tr(),
                      borderColor: AppColors.gray200,
                      color: AppColors.white,
                      textColor: AppColors.gray700)),
              const SizedBox(width: 12),
              Expanded(
                  child: Button.primary(
                      onTap: () => Navigator.of(context).pop(true), text: 'Start tour'.tr()))
            ])
          ])));
}

class GuidedTutorialRuntime {
  GuidedTutorialRuntime._();

  static bool isActive = false;
}

class GuidedTutorialOverlay {
  const GuidedTutorialOverlay._();

  static Future<void> show({
    required BuildContext context,
    required List<TutorialStepModel> steps,
  }) async {
    if (steps.isEmpty || GuidedTutorialRuntime.isActive) return;
    final completer = Completer<void>();
    late final OverlayEntry entry;
    GuidedTutorialRuntime.isActive = true;

    void close() {
      if (entry.mounted) entry.remove();
      GuidedTutorialRuntime.isActive = false;
      if (!completer.isCompleted) completer.complete();
    }

    entry =
        OverlayEntry(builder: (_) => GuidedTutorialOverlayContent(steps: steps, onClose: close));
    Overlay.of(context, rootOverlay: true).insert(entry);
    return completer.future;
  }
}

class GuidedTutorialOverlayContent extends StatefulWidget {
  final List<TutorialStepModel> steps;
  final VoidCallback onClose;

  const GuidedTutorialOverlayContent({super.key, required this.steps, required this.onClose});

  @override
  State<GuidedTutorialOverlayContent> createState() => _GuidedTutorialOverlayContentState();
}

class _GuidedTutorialOverlayContentState extends State<GuidedTutorialOverlayContent>
    with TickerProviderStateMixin {
  static const Duration _bubbleHideDuration = Duration(milliseconds: 260);
  static const Duration _bubbleShowDuration = Duration(milliseconds: 360);
  static const Duration _characterMoveDuration = Duration(milliseconds: 460);

  late final AnimationController pulseController;
  late final AnimationController idleController;
  late final AnimationController speechController;
  late final AnimationController characterMoveController;
  late final ScrollController bubbleScrollController;
  int currentIndex = 0;
  Rect? currentTargetRect;
  TutorialBubbleLayout? currentLayout;
  Offset? currentCharacterOffset;
  Tween<Offset>? characterMoveTween;
  bool isTransitioning = false;
  bool showBubbleScrollHint = false;
  double lockedIdleDy = 0;

  @override
  void initState() {
    super.initState();
    pulseController = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
    idleController = AnimationController(vsync: this, duration: const Duration(milliseconds: 3200))
      ..repeat();
    speechController = AnimationController(vsync: this, duration: _bubbleShowDuration);
    characterMoveController = AnimationController(vsync: this, duration: _characterMoveDuration)
      ..value = 1;
    bubbleScrollController = ScrollController()..addListener(updateBubbleScrollHint);
    WidgetsBinding.instance.addPostFrameCallback((_) => ensureCurrentTargetVisible());
  }

  @override
  void dispose() {
    bubbleScrollController.dispose();
    characterMoveController.dispose();
    speechController.dispose();
    idleController.dispose();
    pulseController.dispose();
    super.dispose();
  }

  TutorialStepModel get currentStep => widget.steps[currentIndex];

  bool get isLastStep => currentIndex == widget.steps.length - 1;

  double get currentIdleDy =>
      isTransitioning ? lockedIdleDy : math.sin(idleController.value * math.pi * 2) * 3.2;

  TutorialMascotMood get currentMascotMood => currentStep.mascotMood ?? resolvedMascotMood;

  TutorialMascotMood get resolvedMascotMood {
    final lowerTitle = currentStep.title.toLowerCase();
    final lowerMessage = currentStep.message.toLowerCase();
    final combined = '$lowerTitle $lowerMessage';
    final icon = currentStep.icon;

    if (combined.contains('wrong') ||
        combined.contains('incorrect') ||
        combined.contains('mistake') ||
        combined.contains('xato') ||
        combined.contains('невер') ||
        icon == Icons.error_outline_rounded ||
        icon == Icons.warning_rounded) {
      return TutorialMascotMood.confused;
    }

    if (combined.contains('tired') ||
        combined.contains('skip') ||
        combined.contains('later') ||
        combined.contains('unfinished') ||
        combined.contains('remaining') ||
        combined.contains('not answered') ||
        combined.contains('неотправ') ||
        combined.contains('yuborilmagan') ||
        icon == Icons.info_rounded) {
      return TutorialMascotMood.tired;
    }

    if (combined.contains('correct') ||
        combined.contains('finish') ||
        combined.contains('result') ||
        combined.contains('leaderboard') ||
        combined.contains('xp') ||
        combined.contains('progress') ||
        combined.contains('complete') ||
        icon == Icons.check_circle_rounded ||
        icon == Icons.emoji_events_rounded ||
        icon == Icons.flag_rounded ||
        icon == Icons.assignment_turned_in_rounded) {
      return TutorialMascotMood.strong;
    }

    if (combined.contains('rule') ||
        combined.contains('grammar') ||
        combined.contains('reading') ||
        combined.contains('question') ||
        combined.contains('answer') ||
        combined.contains('lesson') ||
        combined.contains('study') ||
        combined.contains('learn') ||
        icon == Icons.menu_book_rounded ||
        icon == Icons.help_outline_rounded ||
        icon == Icons.psychology_alt_rounded) {
      return TutorialMascotMood.smart;
    }

    return TutorialMascotMood.happy;
  }

  Rect? resolveTargetRectForStep(TutorialStepModel step) {
    final context = step.targetKey?.currentContext;
    final renderObject = context?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.hasSize) return null;
    final offset = renderObject.localToGlobal(Offset.zero);
    final rawRect = offset & renderObject.size;
    final screenRect = Offset.zero & MediaQuery.of(this.context).size;
    if (!screenRect.overlaps(rawRect)) return null;
    return rawRect.intersect(screenRect);
  }

  Future<Rect?> resolveTargetRectForIndex(int index) async {
    final step = widget.steps[index];
    final targetContext = step.targetKey?.currentContext;
    if (targetContext == null) return null;
    await Scrollable.ensureVisible(targetContext,
        duration: const Duration(milliseconds: 380), curve: Curves.easeInOutCubic, alignment: 0.32);
    if (!mounted || index >= widget.steps.length) return null;
    await Future<void>.delayed(const Duration(milliseconds: 20));
    if (!mounted || index >= widget.steps.length) return null;
    return resolveTargetRectForStep(step);
  }

  Future<void> nextStep() async {
    if (isTransitioning) return;
    if (isLastStep) {
      widget.onClose();
      return;
    }
    await goToStep(currentIndex + 1);
  }

  Future<void> goToStep(int nextIndex) async {
    if (isTransitioning || nextIndex < 0 || nextIndex >= widget.steps.length) return;

    final idleDy = currentIdleDy;
    final fromOffset = animatedCharacterOffset;
    setState(() {
      isTransitioning = true;
      lockedIdleDy = idleDy;
      showBubbleScrollHint = false;
    });

    await hideBubble();
    if (!mounted) return;

    setState(() => currentTargetRect = null);

    final nextRect = await resolveTargetRectForIndex(nextIndex);
    if (!mounted) return;

    final nextLayout = calculateLayout(MediaQuery.of(context).size, MediaQuery.of(context).padding,
        nextRect, widget.steps[nextIndex]);
    final toOffset = nextLayout.mascotOffset;

    await moveCharacter(fromOffset, toOffset);
    if (!mounted) return;

    setState(() {
      currentIndex = nextIndex;
      currentTargetRect = nextRect;
      currentLayout = nextLayout;
      currentCharacterOffset = toOffset;
      characterMoveTween = null;
      lockedIdleDy = 0;
    });

    resetBubbleScroll();
    await showBubble();
    if (!mounted) return;

    setState(() => isTransitioning = false);
    updateBubbleScrollHint();
  }

  Future<void> hideBubble() async {
    speechController.duration = _bubbleHideDuration;
    await speechController.reverse();
  }

  Future<void> showBubble() async {
    speechController.duration = _bubbleShowDuration;
    await speechController.forward(from: 0);
  }

  Future<void> moveCharacter(Offset fromOffset, Offset toOffset) async {
    setState(() {
      lockedIdleDy = 0;
      characterMoveTween = Tween<Offset>(begin: fromOffset, end: toOffset);
    });
    await characterMoveController.forward(from: 0);
    if (!mounted) return;
    setState(() {
      currentCharacterOffset = toOffset;
      characterMoveTween = null;
    });
  }

  Future<void> ensureCurrentTargetVisible() async {
    final stepIndex = currentIndex;
    final rect = await resolveTargetRectForIndex(stepIndex);
    if (!mounted || stepIndex != currentIndex) return;
    final layout = calculateLayout(
        MediaQuery.of(context).size, MediaQuery.of(context).padding, rect, currentStep);
    setState(() {
      currentTargetRect = rect;
      currentLayout = layout;
      currentCharacterOffset = layout.mascotOffset;
    });
    await showBubble();
    resetBubbleScroll();
  }

  void resetBubbleScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !bubbleScrollController.hasClients) return;
      bubbleScrollController.jumpTo(0);
      updateBubbleScrollHint();
    });
  }

  void updateBubbleScrollHint() {
    if (!mounted || !bubbleScrollController.hasClients) return;
    if (speechController.value < 1 || isTransitioning) {
      if (showBubbleScrollHint) setState(() => showBubbleScrollHint = false);
      return;
    }
    final position = bubbleScrollController.position;
    final shouldShow =
        position.maxScrollExtent > 6 && position.pixels < position.maxScrollExtent - 6;
    if (showBubbleScrollHint != shouldShow) {
      setState(() => showBubbleScrollHint = shouldShow);
    }
  }

  void scrollBubbleDown() {
    if (!bubbleScrollController.hasClients) return;
    final position = bubbleScrollController.position;
    final target = math.min(position.maxScrollExtent, position.pixels + position.viewportDimension);
    bubbleScrollController.animateTo(target,
        duration: const Duration(milliseconds: 240), curve: Curves.easeOutCubic);
  }

  double calculateBubbleLeft(Size size, Rect? rect, double bubbleWidth) {
    final centerX = rect?.center.dx ?? size.width / 2;
    return math.max(16, math.min(centerX - bubbleWidth / 2, size.width - bubbleWidth - 16));
  }

  TutorialBubbleLayout calculateLayout(
      Size size, EdgeInsets padding, Rect? rect, TutorialStepModel step) {
    final safeTop = padding.top + 10;
    final safeBottom = size.height - padding.bottom - 10;
    final gap = rect == null ? 0.0 : 14.0;
    final bubbleWidth = math.min(size.width - 32, 390.0);
    final belowAvailable = rect == null ? size.height * 0.50 : safeBottom - rect.bottom - gap;
    final aboveAvailable = rect == null ? size.height * 0.50 : rect.top - gap - safeTop;
    const tailHeight = 14.0;
    final comfortableHeight = size.height < 680 ? 220.0 : 250.0;
    final desiredHeight = math.min(size.height * 0.44, 286.0);
    final preferBelow = rect == null
        ? true
        : belowAvailable >= comfortableHeight
            ? true
            : aboveAvailable >= comfortableHeight
                ? false
                : belowAvailable >= aboveAvailable;
    final available = math.max(112.0, preferBelow ? belowAvailable : aboveAvailable);
    final mascotSize = calculateMascotSize(available, size.height);
    final mascotOverlap = mascotSize * 0.22;
    final speechAvailable = math.max(86.0, available - mascotSize - tailHeight + mascotOverlap);
    final isCompact = speechAvailable < 206 || size.width < 360;
    final speechMaxHeight =
        calculateSpeechMaxHeight(step, bubbleWidth, isCompact, desiredHeight, speechAvailable);
    final bubbleLeft = calculateBubbleLeft(size, rect, bubbleWidth);
    final bubbleTop = calculateBubbleTop(
        safeTop: safeTop,
        safeBottom: safeBottom,
        rect: rect,
        preferBelow: preferBelow,
        gap: gap,
        speechHeight: speechMaxHeight,
        tailHeight: tailHeight,
        mascotOverlap: mascotOverlap,
        mascotSize: mascotSize);
    final mascotOffset = avoidTargetOverlap(
        size: size,
        safeTop: safeTop,
        safeBottom: safeBottom,
        targetRect: rect,
        initialOffset: calculateMascotOffset(
            size: size,
            rect: rect,
            bubbleLeft: bubbleLeft,
            bubbleTop: bubbleTop,
            bubbleWidth: bubbleWidth,
            speechHeight: speechMaxHeight,
            tailHeight: tailHeight,
            mascotOverlap: mascotOverlap,
            mascotSize: mascotSize,
            preferBelow: preferBelow),
        mascotSize: mascotSize);
    final tailLeft = (mascotOffset.dx + mascotSize / 2 - bubbleLeft - 13)
        .clamp(24.0, bubbleWidth - 50)
        .toDouble();

    return TutorialBubbleLayout(
        bubbleOffset: Offset(bubbleLeft, bubbleTop),
        bubbleWidth: bubbleWidth,
        speechMaxHeight: speechMaxHeight,
        mascotOffset: mascotOffset,
        mascotSize: mascotSize,
        tailLeft: tailLeft,
        isTailAbove: !preferBelow,
        isCompact: isCompact);
  }

  double calculateMascotSize(double available, double screenHeight) {
    final preferred = screenHeight < 680 ? 160.0 : 180.0;
    final reservedForBubble = screenHeight < 680 ? 104.0 : 118.0;
    return math.max(46.0, math.min(preferred, available - reservedForBubble));
  }

  double calculateSpeechMaxHeight(TutorialStepModel step, double bubbleWidth, bool isCompact,
      double desiredHeight, double available) {
    final horizontalPadding = isCompact ? 28.0 : 36.0;
    final textWidth = math.max(180.0, bubbleWidth - horizontalPadding - 48);
    final titleLineCapacity = math.max(12, (textWidth / (isCompact ? 7.2 : 8.0)).floor());
    final messageLineCapacity = math.max(18, (textWidth / (isCompact ? 6.5 : 7.2)).floor());
    final titleLines = math.min(2, math.max(1, (step.title.length / titleLineCapacity).ceil()));
    final messageLines = math.max(1, (step.message.length / messageLineCapacity).ceil());
    final verticalPadding = isCompact ? 24.0 : 32.0;
    final headerHeight = math.max(isCompact ? 30.0 : 34.0, titleLines * (isCompact ? 18.0 : 20.0));
    const actionHeight = 32.0;
    final gaps = isCompact ? 20.0 : 24.0;
    final estimatedHeight = verticalPadding +
        headerHeight +
        messageLines * (isCompact ? 18.0 : 20.0) +
        actionHeight +
        gaps;

    return math.max(86.0, math.min(math.min(desiredHeight, available), estimatedHeight + 6));
  }

  double calculateBubbleTop({
    required double safeTop,
    required double safeBottom,
    required Rect? rect,
    required bool preferBelow,
    required double gap,
    required double speechHeight,
    required double tailHeight,
    required double mascotOverlap,
    required double mascotSize,
  }) {
    final blockHeight = speechHeight + tailHeight + mascotSize - mascotOverlap;
    final rawTop = rect == null
        ? safeBottom - blockHeight
        : preferBelow
            ? rect.bottom + gap
            : rect.top - gap - speechHeight - tailHeight;
    final minTop = preferBelow ? safeTop : safeTop + mascotSize - mascotOverlap;
    final maxTop = preferBelow ? safeBottom - blockHeight : safeBottom - speechHeight - tailHeight;
    return rawTop.clamp(minTop, math.max(minTop, maxTop)).toDouble();
  }

  Offset calculateMascotOffset({
    required Size size,
    required Rect? rect,
    required double bubbleLeft,
    required double bubbleTop,
    required double bubbleWidth,
    required double speechHeight,
    required double tailHeight,
    required double mascotOverlap,
    required double mascotSize,
    required bool preferBelow,
  }) {
    final placeOnRight = rect == null ? false : rect.center.dx < size.width / 2;
    final preferredLeft = rect == null
        ? bubbleLeft + bubbleWidth / 2 - mascotSize / 2
        : placeOnRight
            ? bubbleLeft + bubbleWidth - mascotSize - 26
            : bubbleLeft + 26;
    final mascotLeft =
        preferredLeft.clamp(14.0, math.max(14.0, size.width - mascotSize - 14)).toDouble();
    final mascotTop = preferBelow
        ? bubbleTop + speechHeight + tailHeight - mascotOverlap
        : bubbleTop - mascotSize + mascotOverlap;
    return Offset(mascotLeft, mascotTop);
  }

  Offset avoidTargetOverlap({
    required Size size,
    required double safeTop,
    required double safeBottom,
    required Rect? targetRect,
    required Offset initialOffset,
    required double mascotSize,
  }) {
    final target = targetRect?.inflate(12);
    if (target == null || !mascotRect(initialOffset, mascotSize).overlaps(target)) {
      return initialOffset;
    }

    final candidates = [
      Offset(14, initialOffset.dy),
      Offset(size.width - mascotSize - 14, initialOffset.dy),
      Offset(initialOffset.dx, target.top - mascotSize - 12),
      Offset(initialOffset.dx, target.bottom + 12),
    ].map((offset) => clampMascotOffset(offset, size, safeTop, safeBottom, mascotSize)).toList();

    for (final offset in candidates) {
      if (!mascotRect(offset, mascotSize).overlaps(target)) return offset;
    }

    candidates.sort((a, b) => distanceFromTarget(b, target, mascotSize)
        .compareTo(distanceFromTarget(a, target, mascotSize)));
    return candidates.first;
  }

  Offset clampMascotOffset(
          Offset offset, Size size, double safeTop, double safeBottom, double mascotSize) =>
      Offset(offset.dx.clamp(14.0, math.max(14.0, size.width - mascotSize - 14)).toDouble(),
          offset.dy.clamp(safeTop, math.max(safeTop, safeBottom - mascotSize)).toDouble());

  Rect mascotRect(Offset offset, double mascotSize) =>
      Rect.fromLTWH(offset.dx, offset.dy, mascotSize, mascotSize);

  double distanceFromTarget(Offset offset, Rect target, double mascotSize) {
    final rect = mascotRect(offset, mascotSize);
    return (rect.center - target.center).distance;
  }

  Offset get animatedCharacterOffset {
    final tween = characterMoveTween;
    if (tween != null) {
      final value = Curves.easeInOutCubic.transform(characterMoveController.value);
      return tween.transform(value);
    }
    final offset = currentCharacterOffset ?? currentLayout?.mascotOffset ?? Offset.zero;
    return offset.translate(0, currentIdleDy);
  }

  Widget focusHighlight(Rect rect) => AnimatedBuilder(
      animation: pulseController,
      builder: (context, _) {
        final pulse = math.sin(pulseController.value * math.pi);
        return Positioned.fromRect(
            rect: rect.inflate(8 + pulse * 4),
            child: IgnorePointer(
                child: DecoratedBox(
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        border:
                            Border.all(color: AppColors.primary.withValues(alpha: 0.65), width: 2),
                        boxShadow: [
                  BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.22),
                      blurRadius: 18 + pulse * 8,
                      spreadRadius: 2)
                ]))));
      });

  Widget compactPrimaryAction(BuildContext context, String text) => FilledButton(
      onPressed: isTransitioning ? null : nextStep,
      style: FilledButton.styleFrom(
          minimumSize: const Size(74, 30),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: Style.border32),
          backgroundColor: AppColors.primary),
      child: Text(text,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Style.small2w5(context, color: TextColorRole.whiteColor)));

  Widget controlEntrance(Widget child) => AnimatedBuilder(
      animation: speechController,
      builder: (context, _) {
        final value = Curves.easeOutCubic.transform(speechController.value);
        return Opacity(
            opacity: value,
            child: Transform.translate(offset: Offset(0, 10 * (1 - value)), child: child));
      });

  Widget speechActions(BuildContext context, TutorialBubbleLayout layout) =>
      controlEntrance(Row(children: [
        Flexible(
            child: _TutorialTapScale(
                child: TextButton(
                    onPressed: isTransitioning ? null : widget.onClose,
                    style: TextButton.styleFrom(
                        minimumSize: const Size(0, 30),
                        padding: EdgeInsets.symmetric(horizontal: layout.isCompact ? 6 : 10),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                    child: Text('Skip'.tr(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Style.small2w5(context))))),
        SizedBox(width: layout.isCompact ? 4 : 8),
        ConstrainedBox(
            constraints: BoxConstraints(maxWidth: layout.isCompact ? 82 : 96),
            child: _TutorialTapScale(
                child: compactPrimaryAction(context, isLastStep ? 'Done'.tr() : 'Next'.tr())))
      ]));

  Widget speechBubble(BuildContext context, TutorialBubbleLayout layout) {
    final horizontalPadding = layout.isCompact ? 14.0 : 18.0;
    final verticalPadding = layout.isCompact ? 12.0 : 16.0;
    final iconSize = layout.isCompact ? 30.0 : 34.0;
    final titleStyle = layout.isCompact ? Style.small3w7(context) : Style.bodyw7(context);
    final messageStyle = layout.isCompact
        ? Style.small2w4(context, color: TextColorRole.greyColor)
        : Style.small3w4(context, color: TextColorRole.greyColor);
    final accentColor = currentStep.accentColor ?? AppColors.green36;
    final accentBackgroundColor = currentStep.accentBackgroundColor ?? AppColors.greenE7;

    return DecoratedBox(
        decoration: BoxDecoration(color: AppColors.white, borderRadius: Style.border24, boxShadow: [
          BoxShadow(
              color: AppColors.black.withValues(alpha: 0.20),
              blurRadius: 30,
              offset: const Offset(0, 14))
        ]),
        child: Padding(
            padding: EdgeInsets.fromLTRB(
                horizontalPadding, verticalPadding, horizontalPadding, verticalPadding),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(children: [
                    Container(
                        width: iconSize,
                        height: iconSize,
                        decoration:
                            BoxDecoration(color: accentBackgroundColor, shape: BoxShape.circle),
                        child: Icon(currentStep.icon,
                            size: layout.isCompact ? 17 : 19, color: accentColor)),
                    SizedBox(width: layout.isCompact ? 8 : 10),
                    Expanded(
                        child: Text(currentStep.title,
                            maxLines: 2, overflow: TextOverflow.ellipsis, style: titleStyle)),
                    SizedBox(width: layout.isCompact ? 6 : 8),
                    Text('${currentIndex + 1}/${widget.steps.length}',
                        style: Style.small2w5(context, color: TextColorRole.greyColor))
                  ]),
                  SizedBox(height: layout.isCompact ? 8 : 10),
                  Text(currentStep.message, style: messageStyle),
                  SizedBox(height: layout.isCompact ? 10 : 14),
                  Align(alignment: Alignment.centerRight, child: speechActions(context, layout))
                ])));
  }

  Widget bubbleStepTransition(Widget child, Animation<double> animation) {
    final curved = CurvedAnimation(
        parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
    final slide = Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero).animate(curved);
    final scale = Tween<double>(begin: 0.88, end: 1).animate(curved);
    return FadeTransition(
        opacity: curved,
        child:
            SlideTransition(position: slide, child: ScaleTransition(scale: scale, child: child)));
  }

  Widget animatedSpeechBlock(BuildContext context, TutorialBubbleLayout layout) => AnimatedBuilder(
      animation: Listenable.merge([speechController, idleController]),
      child: speechBlock(context, layout),
      builder: (context, child) {
        final value = Curves.easeOutCubic.transform(speechController.value);
        final idleValue = math.sin(idleController.value * math.pi * 2);
        final idleDy = isTransitioning ? 0.0 : idleValue * 2.2;
        final idleScale = isTransitioning ? 0.0 : (idleValue + 1) * 0.0035;
        return IgnorePointer(
            ignoring: isTransitioning || value < 1,
            child: Opacity(
                opacity: value,
                child: Transform.translate(
                    offset: Offset(0, 22 * (1 - value) + idleDy),
                    child: Transform.scale(
                        scale: 0.88 + 0.12 * value + idleScale,
                        alignment: Alignment.bottomCenter,
                        child: child))));
      });

  Widget animatedMascot(TutorialBubbleLayout layout) => AnimatedBuilder(
      animation: Listenable.merge([characterMoveController, idleController]),
      builder: (context, _) {
        final offset = animatedCharacterOffset;
        return Positioned(
            left: offset.dx,
            top: offset.dy,
            child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: bubbleStepTransition,
                child: TutorialMascot(
                    key: ValueKey(currentMascotMood),
                    size: layout.mascotSize,
                    mood: currentMascotMood)));
      });

  Widget bubbleScrollHint() => Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: IgnorePointer(
          ignoring: !showBubbleScrollHint,
          child: AnimatedOpacity(
              duration: const Duration(milliseconds: 160),
              opacity: showBubbleScrollHint ? 1 : 0,
              child: Container(
                  height: 54,
                  alignment: Alignment.bottomCenter,
                  decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
                      gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            AppColors.white.withValues(alpha: 0),
                            AppColors.white.withValues(alpha: 0.96)
                          ])),
                  child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Material(
                          color: AppColors.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                              onTap: scrollBubbleDown,
                              customBorder: const CircleBorder(),
                              child: const SizedBox(
                                  width: 30,
                                  height: 30,
                                  child: Icon(Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.white, size: 24)))))))));

  Widget bubbleTail(TutorialBubbleLayout layout, {bool isTop = false}) => Align(
      alignment: Alignment.centerLeft,
      child: Padding(
          padding: EdgeInsets.only(left: layout.tailLeft),
          child: Transform.rotate(
              angle: isTop ? math.pi : 0,
              child: CustomPaint(size: const Size(26, 14), painter: TutorialBubbleTailPainter()))));

  Widget speechBlock(BuildContext context, TutorialBubbleLayout layout) {
    final speechContent = ConstrainedBox(
        constraints: BoxConstraints(maxHeight: layout.speechMaxHeight),
        child: Stack(children: [
          SingleChildScrollView(
              controller: bubbleScrollController,
              padding: EdgeInsets.only(bottom: showBubbleScrollHint ? 34 : 0),
              child: speechBubble(context, layout)),
          bubbleScrollHint(),
        ]));
    return Column(
        key: ValueKey('speech_$currentIndex'),
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (layout.isTailAbove) bubbleTail(layout, isTop: true),
          speechContent,
          if (!layout.isTailAbove) bubbleTail(layout),
        ]);
  }

  @override
  Widget build(BuildContext context) {
    final layout = currentLayout;
    final idleDy = currentIdleDy;

    return Material(
        color: Colors.transparent,
        child: Stack(children: [
          Positioned.fill(
              child: CustomPaint(painter: TutorialScrimPainter(targetRect: currentTargetRect))),
          if (currentTargetRect != null) focusHighlight(currentTargetRect!),
          if (layout != null) ...[
            Positioned(
                left: layout.bubbleOffset.dx,
                top: layout.bubbleOffset.dy + idleDy,
                width: layout.bubbleWidth,
                child: animatedSpeechBlock(context, layout)),
            animatedMascot(layout),
          ]
        ]));
  }
}

class _TutorialTapScale extends StatefulWidget {
  final Widget child;

  const _TutorialTapScale({required this.child});

  @override
  State<_TutorialTapScale> createState() => _TutorialTapScaleState();
}

class _TutorialTapScaleState extends State<_TutorialTapScale> {
  bool isPressed = false;

  void setPressed(bool value) {
    if (isPressed == value) return;
    setState(() => isPressed = value);
  }

  @override
  Widget build(BuildContext context) => Listener(
      onPointerDown: (_) => setPressed(true),
      onPointerUp: (_) => setPressed(false),
      onPointerCancel: (_) => setPressed(false),
      child: AnimatedScale(
          scale: isPressed ? 0.95 : 1,
          duration: const Duration(milliseconds: 90),
          curve: Curves.easeOutCubic,
          child: widget.child));
}

class TutorialBubbleLayout {
  final Offset bubbleOffset;
  final double bubbleWidth;
  final double speechMaxHeight;
  final Offset mascotOffset;
  final double mascotSize;
  final double tailLeft;
  final bool isTailAbove;
  final bool isCompact;

  const TutorialBubbleLayout({
    required this.bubbleOffset,
    required this.bubbleWidth,
    required this.speechMaxHeight,
    required this.mascotOffset,
    required this.mascotSize,
    required this.tailLeft,
    required this.isTailAbove,
    required this.isCompact,
  });
}

class TutorialBubbleTailPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..quadraticBezierTo(size.width * 0.30, size.height * 0.20, size.width * 0.18, size.height)
      ..close();
    canvas.drawPath(path, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class TutorialScrimPainter extends CustomPainter {
  final Rect? targetRect;

  const TutorialScrimPainter({required this.targetRect});

  @override
  void paint(Canvas canvas, Size size) {
    final overlay = Path()..addRect(Offset.zero & size);
    final target = targetRect;
    if (target != null) {
      overlay.addRRect(RRect.fromRectAndRadius(target.inflate(10), const Radius.circular(22)));
      overlay.fillType = PathFillType.evenOdd;
    }
    canvas.drawPath(overlay, Paint()..color = AppColors.black.withValues(alpha: 0.62));
  }

  @override
  bool shouldRepaint(covariant TutorialScrimPainter oldDelegate) =>
      oldDelegate.targetRect != targetRect;
}
