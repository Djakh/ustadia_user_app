import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_model.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/flashcard_status_bloc/flashcard_status_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/flashcard_status_bloc/flashcard_status_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/flashcard_status_bloc/flashcard_status_state.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/flashcard_sprint/flashcard_sprint_result_page.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_navigation_circle_button.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/flashcard_view.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum FlashcardSprintStage { cards, result }

class FlashcardSprintParams {
  final LearnFlashcardSetModel set;
  final bool isPractice;
  final SectionModel? sectionModel;

  const FlashcardSprintParams({
    required this.set,
    this.isPractice = false,
    this.sectionModel,
  });
}

class FlashcardSprintPage extends StatefulWidget {
  final LearnFlashcardSetModel flashcardSetModel;
  final bool isPractice;
  final SectionModel? sectionModel;
  const FlashcardSprintPage({
    super.key,
    required this.flashcardSetModel,
    this.isPractice = false,
    this.sectionModel,
  });

  @override
  State<FlashcardSprintPage> createState() => FlashcardSprintPageState();
}

class FlashcardSprintPageState extends State<FlashcardSprintPage> {
  FlashcardSprintStage stage = FlashcardSprintStage.cards;
  int index = 0;
  bool showMeaning = false;
  bool isFlashcardsOverviewVisible = false;
  OverlayEntry? flashcardsOverviewEntry;
  final Set<int> _seenMeaning = {};
  final Set<int> _knownCards = {};
  final Set<int> _learningCards = {};
  final FlashcardStatusBloc statusBloc = sl<FlashcardStatusBloc>();
  FlashcardSprintResultStats? resultStats;
  final GlobalKey flashcardKey = GlobalKey(debugLabel: 'flashcard_card');
  final GlobalKey cardsButtonKey = GlobalKey(debugLabel: 'flashcard_cards_button');
  final GlobalKey previousButtonKey = GlobalKey(debugLabel: 'flashcard_previous');
  final GlobalKey mainButtonKey = GlobalKey(debugLabel: 'flashcard_main_action');
  final GlobalKey nextButtonKey = GlobalKey(debugLabel: 'flashcard_next');

  List<LearnFlashcardModel> get cards => widget.flashcardSetModel.flashcards;
  LearnFlashcardModel get current => cards[index];
  String get progress => 'Card {current} of {total}'
      .tr(namedArgs: {'current': cards.isEmpty ? '0' : '${index + 1}', 'total': '${cards.length}'});
  bool get hasSeenMeaning => _seenMeaning.contains(index);
  bool get isSubmitting => statusBloc.state.status.isLoading;
  bool get isCurrentMeaningLoading => isSubmitting && statusBloc.state.flashcardId == current.id;
  bool get shouldShowMeaning => showMeaning;
  bool get isSectionVocabulary => widget.sectionModel != null && !widget.isPractice;
  bool get isFirstCard => index == 0;
  bool get isLastCard => index == cards.length - 1;
  bool get isCurrentCardAnswered => isCardAnswered(index);
  int get reviewedCount => List.generate(cards.length, (cardIndex) => cardIndex)
      .where((cardIndex) => widget.isPractice
          ? isKnownCard(cardIndex) || isLearningCard(cardIndex)
          : isCardAnswered(cardIndex))
      .length;
  int get remainingCount => cards.length - reviewedCount;
  bool get allRequiredCardsAnswered => widget.isPractice || remainingCount == 0;

  @override
  void initState() {
    super.initState();
    if (widget.sectionModel?.progressState == SectionProgressState.completed) {
      stage = FlashcardSprintStage.result;
    }
  }

  @override
  void dispose() {
    flashcardsOverviewEntry?.remove();
    flashcardsOverviewEntry = null;
    statusBloc.close();
    super.dispose();
  }

  void toggleFace() {
    if (isSubmitting) return;
    if (isCurrentCardAnswered) {
      if (current.back == null) return;
      setState(() => showMeaning = !showMeaning);
      return;
    }
    final nextShow = !showMeaning;
    if (nextShow) {
      if (!hasSeenMeaning) {
        _submitStatus('revealed');
      }
    }
    setState(() {
      showMeaning = nextShow;
      if (showMeaning && !hasSeenMeaning) {
        _learningCards.add(index);
        _seenMeaning.add(index);
      }
    });
  }

  void onKnowIt() {
    if (isSubmitting) return;
    if (isCurrentCardAnswered) return;
    if (!showMeaning) {
      setState(() => showMeaning = true);
      if (!hasSeenMeaning) {
        _learningCards.add(index);
        _seenMeaning.add(index);
      }
    }
    if (!_knownCards.contains(index)) {
      _knownCards.add(index);
      _learningCards.remove(index);
    }
    _submitStatus('not_revealed');
  }

  void goNextCard() {
    if (isSubmitting) return;
    if (isLastCard) {
      finishFlashcardsIfComplete();
      return;
    }
    goToCard(index + 1);
  }

  void finishFlashcardsIfComplete() {
    if (!allRequiredCardsAnswered) {
      openFlashcardsOverview();
      return;
    }
    _finish();
  }

  void goPreviousCard() {
    if (isSubmitting || isFirstCard) return;
    goToCard(index - 1);
  }

  void goToCard(int nextIndex, {bool closeFlashcardsOverview = false}) {
    if (isSubmitting) return;
    if (nextIndex < 0 || nextIndex >= cards.length) return;
    setState(() {
      if (index != nextIndex) showMeaning = false;
      index = nextIndex;
    });
    if (closeFlashcardsOverview) this.closeFlashcardsOverview();
  }

  void openFlashcardsOverview() {
    if (isSubmitting) return;
    flashcardsOverviewEntry ??= OverlayEntry(builder: flashcardsOverviewOverlay);
    if (!flashcardsOverviewEntry!.mounted) {
      Overlay.of(context, rootOverlay: true).insert(flashcardsOverviewEntry!);
    }
    flashcardsOverviewEntry?.markNeedsBuild();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || flashcardsOverviewEntry == null) return;
      setState(() => isFlashcardsOverviewVisible = true);
      flashcardsOverviewEntry?.markNeedsBuild();
    });
  }

  void closeFlashcardsOverview() {
    if (!isFlashcardsOverviewVisible) return;
    setState(() => isFlashcardsOverviewVisible = false);
    flashcardsOverviewEntry?.markNeedsBuild();
    Future.delayed(const Duration(milliseconds: 260), () {
      if (!mounted || isFlashcardsOverviewVisible) return;
      flashcardsOverviewEntry?.remove();
      flashcardsOverviewEntry = null;
    });
  }

  void _finish() {
    final stats = FlashcardSprintResultStats(
        known: _knownCards.length, learning: _learningCards.length, total: cards.length);
    if (!mounted) return;
    closeFlashcardsOverview();
    setState(() {
      stage = FlashcardSprintStage.result;
      resultStats = stats;
      index = 0;
      _knownCards.clear();
      _learningCards.clear();
      showMeaning = false;
      _seenMeaning.clear();
    });
  }

  void _submitStatus(String status) {
    if (isCurrentCardAnswered) return;
    statusBloc.add(FlashcardStatusRequested(
        flashcardId: current.id, status: status, isPractice: widget.isPractice));
  }

  void _handleStatusUpdate(FlashcardStatusState state) {
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      return;
    }
    if (state.status.isSuccess) {
      final cardIndex = cards.indexWhere((card) => card.id == state.flashcardId);
      if (cardIndex == -1) return;
      final updatedBack = state.back;
      final updatedStatus = state.cardStatus;
      if (updatedBack != null || updatedStatus != null) {
        final card = cards[cardIndex];
        cards[cardIndex] = card.copyWith(
          back: updatedBack ?? card.back,
          status: updatedStatus ?? card.status,
          isAnswered: widget.isPractice ? card.isAnswered : state.isAnswered ?? true,
        );
      }
    }
  }

  /// --- Widgets ---

  Widget get header => Column(children: [
        Text(widget.flashcardSetModel.title, style: Style.body3w7(context)),
        const SizedBox(height: 4),
        Text(progress, style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget get flashCard => KeyedSubtree(
      key: flashcardKey,
      child: FlashcardView(
          flashcard: current,
          showMeaning: shouldShowMeaning,
          onToggle: toggleFace,
          isLoading: isCurrentMeaningLoading));

  String normalizedCardStatus(int cardIndex) => cards[cardIndex].status.toLowerCase();

  bool isCardAnswered(int cardIndex) {
    if (widget.isPractice) return false;
    return cards[cardIndex].isAnswered == true ||
        _knownCards.contains(cardIndex) ||
        _learningCards.contains(cardIndex) ||
        _seenMeaning.contains(cardIndex);
  }

  bool isKnownCard(int cardIndex) {
    if (!widget.isPractice && !isCardAnswered(cardIndex)) return false;
    final status = normalizedCardStatus(cardIndex);
    return _knownCards.contains(cardIndex) || status == 'not_revealed' || status == 'known';
  }

  bool isLearningCard(int cardIndex) {
    if (!widget.isPractice && !isCardAnswered(cardIndex)) return false;
    return !isKnownCard(cardIndex) &&
        (_learningCards.contains(cardIndex) ||
            _seenMeaning.contains(cardIndex) ||
            normalizedCardStatus(cardIndex) == 'revealed' ||
            normalizedCardStatus(cardIndex) == 'learning');
  }

  String flashcardStatusLabel(int cardIndex) {
    if (!widget.isPractice && !isCardAnswered(cardIndex)) return 'Not submitted';
    if (isKnownCard(cardIndex)) return 'Known';
    if (isLearningCard(cardIndex)) return 'Learning';
    return widget.isPractice ? 'New' : 'Submitted';
  }

  Color flashcardStatusColor(int cardIndex) {
    if (!widget.isPractice && !isCardAnswered(cardIndex)) return AppColors.orange12;
    if (isKnownCard(cardIndex)) return AppColors.primary;
    if (isLearningCard(cardIndex)) return AppColors.orange09;
    return AppColors.gray400;
  }

  Color flashcardStatusBackground(int cardIndex) {
    if (!widget.isPractice && !isCardAnswered(cardIndex)) return AppColors.orangeEB;
    if (isKnownCard(cardIndex)) return AppColors.greenE7;
    if (isLearningCard(cardIndex)) return AppColors.orangeEB;
    return AppColors.gray100;
  }

  Widget flashcardStatusBadge(BuildContext context, int cardIndex) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration:
          BoxDecoration(color: flashcardStatusBackground(cardIndex), borderRadius: Style.border8),
      child: Text(flashcardStatusLabel(cardIndex).tr(),
          style: Style.smallw6(context).copyWith(color: flashcardStatusColor(cardIndex))));

  String get mainActionText {
    if (isCurrentCardAnswered && isLastCard) {
      return allRequiredCardsAnswered ? 'Finish' : 'Cards';
    }
    if (isCurrentCardAnswered) return 'Next';
    return hasSeenMeaning ? 'Next' : 'I know it';
  }

  VoidCallback get mainActionTap => isCurrentCardAnswered || hasSeenMeaning ? goNextCard : onKnowIt;

  Widget get flashcardsOverviewButton => Material(
      key: cardsButtonKey,
      color: Colors.transparent,
      child: InkWell(
          onTap: openFlashcardsOverview,
          borderRadius: Style.border16,
          child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: Style.border16,
                  border: Border.all(color: AppColors.gray300)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.style_rounded, size: 18),
                const SizedBox(width: 6),
                Text('Cards'.tr(), style: Style.small2w5(context))
              ]))));

  Widget controls(BuildContext context) => Row(children: [
        SectionNavigationCircleButton(
            key: previousButtonKey,
            height: 44,
            width: 84,
            icon: Icons.chevron_left,
            onTap: goPreviousCard,
            isAvailable: !isFirstCard && !isSubmitting),
        const SizedBox(width: 8),
        Expanded(
            child: KeyedSubtree(
                key: mainButtonKey,
                child: Button.border(
                    onTap: mainActionTap,
                    height: 44,
                    text: mainActionText.tr(),
                    isAvialable: !isSubmitting))),
        const SizedBox(width: 8),
        SectionNavigationCircleButton(
            key: nextButtonKey,
            height: 44,
            width: 84,
            icon: isLastCard && !allRequiredCardsAnswered
                ? Icons.style_rounded
                : isLastCard
                    ? Icons.check_rounded
                    : Icons.chevron_right,
            onTap: goNextCard,
            isAvailable: !isSubmitting),
      ]);

  Widget flashcardListTile(BuildContext panelContext, int cardIndex) {
    final card = cards[cardIndex];
    final isCurrent = cardIndex == index;
    final statusColor = flashcardStatusColor(cardIndex);
    final isDone = widget.isPractice
        ? isKnownCard(cardIndex) || isLearningCard(cardIndex)
        : isCardAnswered(cardIndex);
    return Material(
        color: Colors.transparent,
        child: InkWell(
            onTap: () => goToCard(cardIndex, closeFlashcardsOverview: true),
            borderRadius: Style.border16,
            child: Ink(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: isCurrent ? AppColors.greenE7 : panelContext.cs.surface,
                    borderRadius: Style.border16,
                    border: Border.all(color: isCurrent ? AppColors.primary : AppColors.gray200)),
                child: Row(children: [
                  Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      child: Center(
                          child: Text('${cardIndex + 1}',
                              style:
                                  Style.small3w7(panelContext, color: TextColorRole.whiteColor)))),
                  const SizedBox(width: 12),
                  Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(card.front,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Style.bodyw6(panelContext)),
                    const SizedBox(height: 4),
                    flashcardStatusBadge(panelContext, cardIndex)
                  ])),
                  if (isCurrent)
                    const Icon(Icons.radio_button_checked_rounded,
                        color: AppColors.green36, size: 20)
                  else
                    Icon(isDone ? Icons.check_circle_rounded : Icons.circle_outlined,
                        color: isDone ? AppColors.green36 : AppColors.gray400, size: 20)
                ]))));
  }

  Widget flashcardListPanel(BuildContext panelContext) => Container(
      width: double.infinity,
      height: MediaQuery.of(panelContext).size.height * 0.72,
      decoration: BoxDecoration(
          color: panelContext.cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      child: SafeArea(
          top: false,
          child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
              child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                Center(
                    child: Container(
                        width: 46,
                        height: 5,
                        decoration: BoxDecoration(
                            color: panelContext.cs.outline.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(999)))),
                const SizedBox(height: 18),
                Row(children: [
                  Expanded(child: Text('Flashcards'.tr(), style: Style.body2w6(panelContext))),
                  IconButton(
                      onPressed: closeFlashcardsOverview, icon: const Icon(Icons.close_rounded))
                ]),
                const SizedBox(height: 4),
                Text('Choose a flashcard to review.'.tr(),
                    style: Style.small3w4(panelContext, color: TextColorRole.greyColor)),
                const SizedBox(height: 14),
                Container(
                    padding: const EdgeInsets.all(12),
                    decoration:
                        BoxDecoration(color: AppColors.gray100, borderRadius: Style.border16),
                    child: Row(children: [
                      Expanded(
                          child: Text(
                              (widget.isPractice
                                      ? 'Reviewed {count} of {total}'
                                      : 'Answered {count} of {total}')
                                  .tr(namedArgs: {
                                'count': '$reviewedCount',
                                'total': '${cards.length}'
                              }),
                              style: Style.small3w5(panelContext))),
                      Text('$remainingCount ${'left'.tr()}',
                          style: Style.small3w5(panelContext).copyWith(
                              color: remainingCount == 0 ? AppColors.green36 : AppColors.orange12))
                    ])),
                const SizedBox(height: 14),
                Expanded(
                    child: ListView.separated(
                        itemCount: cards.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, cardIndex) => flashcardListTile(panelContext, cardIndex)))
              ]))));

  Widget flashcardsOverviewOverlay(BuildContext context) => Positioned.fill(
      child: IgnorePointer(
          ignoring: !isFlashcardsOverviewVisible,
          child: Material(
              type: MaterialType.transparency,
              child: Stack(children: [
                AnimatedOpacity(
                    opacity: isFlashcardsOverviewVisible ? 1 : 0,
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    child: GestureDetector(
                        onTap: closeFlashcardsOverview,
                        child: Container(color: AppColors.black.withValues(alpha: 0.38)))),
                AnimatedSlide(
                    offset: isFlashcardsOverviewVisible ? Offset.zero : const Offset(0, 1),
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: Align(
                        alignment: Alignment.bottomCenter, child: flashcardListPanel(context)))
              ]))));

  Widget flashcardsContent(BuildContext context) => Stack(children: [
        Positioned.fill(
            child: Column(children: [
          const SizedBox(height: 24),
          flashCard,
          const SizedBox(height: 20),
          controls(context)
        ])),
        Positioned(top: 12, right: 12, child: flashcardsOverviewButton)
      ]);

  Widget get view => GuidedTutorialPage(
      pageId: '${TutorialPageIds.practiceSession}.flashcard_sprint',
      steps: TutorialPresets.flashcardPractice(
          cardKey: flashcardKey,
          cardsButtonKey: cardsButtonKey,
          previousKey: previousButtonKey,
          mainActionKey: mainButtonKey,
          nextKey: nextButtonKey),
      child: PrimaryBackground(
          header: header,
          headerTooltipText: widget.flashcardSetModel.title,
          child: flashcardsContent(context)));

  Widget get resultView {
    final sectionModel = widget.sectionModel;
    if (isSectionVocabulary && sectionModel != null) {
      return PrimaryBackground(
          isHeader: false,
          isScrollable: false,
          child: QuizResultComponent(sectionModel: sectionModel));
    }
    return FlashcardSprintResultView(stats: resultStats);
  }

  Widget get emptyView => PrimaryBackground(
      header: header,
      headerTooltipText: widget.flashcardSetModel.title,
      child: Center(
          child: Text('No flashcards found.'.tr(),
              style: Style.bodyw5(context, color: TextColorRole.greyColor))));

  @override
  Widget build(BuildContext context) => BlocConsumer<FlashcardStatusBloc, FlashcardStatusState>(
      bloc: statusBloc,
      listener: (context, state) => _handleStatusUpdate(state),
      builder: (context, state) => Scaffold(
          backgroundColor: context.cs.surface,
          body: PopScope(
              canPop: !isFlashcardsOverviewVisible,
              onPopInvokedWithResult: (didPop, _) {
                if (!didPop && isFlashcardsOverviewVisible) closeFlashcardsOverview();
              },
              child: stage == FlashcardSprintStage.result
                  ? resultView
                  : cards.isEmpty
                      ? emptyView
                      : view)));
}
