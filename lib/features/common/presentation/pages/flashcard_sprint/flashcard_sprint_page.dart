import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_model.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/flashcard_status_bloc/flashcard_status_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/flashcard_status_bloc/flashcard_status_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/flashcard_status_bloc/flashcard_status_state.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/flashcard_sprint/flashcard_sprint_result_page.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/flashcard_view.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum FlashcardSprintStage { cards, result }

class FlashcardSprintParams {
  final LearnFlashcardSetModel set;
  final bool isPractice;

  const FlashcardSprintParams({required this.set, required this.isPractice});
}

class FlashcardSprintPage extends StatefulWidget {
  final LearnFlashcardSetModel flashcardSetModel;
  final bool isPractice;
  const FlashcardSprintPage({
    super.key,
    required this.flashcardSetModel,
    this.isPractice = false,
  });

  @override
  State<FlashcardSprintPage> createState() => FlashcardSprintPageState();
}

class FlashcardSprintPageState extends State<FlashcardSprintPage> {
  FlashcardSprintStage stage = FlashcardSprintStage.cards;
  int index = 0;
  bool showMeaning = false;
  final Set<int> _seenMeaning = {};
  final Set<int> _knownCards = {};
  final Set<int> _learningCards = {};
  final FlashcardStatusBloc statusBloc = sl<FlashcardStatusBloc>();
  FlashcardSprintResultStats? resultStats;

  List<LearnFlashcardModel> get cards => widget.flashcardSetModel.flashcards;
  LearnFlashcardModel get current => cards[index];
  String get progress => 'Card ${index + 1}/${cards.length}';
  bool get hasSeenMeaning => _seenMeaning.contains(index);
  bool get isSubmitting => statusBloc.state.status.isLoading;
  bool get shouldShowMeaning => showMeaning || isSubmitting;

  @override
  void dispose() {
    statusBloc.close();
    super.dispose();
  }

  void toggleFace() {
    if (isSubmitting) return;
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

  void onStudyAgain() => setState(() {
        showMeaning = false;
        index = 0;
        _knownCards.clear();
        _learningCards.clear();
        _seenMeaning.clear();
      });

  void _nextCard({required bool resetFace}) {
    if (isSubmitting) return;
    if (index == cards.length - 1) {
      _finish();
      return;
    }
    setState(() {
      if (resetFace) showMeaning = false;
      index = (index + 1) % cards.length;
    });
  }

  void _finish() {
    final stats = FlashcardSprintResultStats(
        known: _knownCards.length, learning: _learningCards.length, total: cards.length);
    if (!mounted) return;
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
    statusBloc.add(FlashcardStatusRequested(
        flashcardId: current.id, status: status, isPractice: widget.isPractice));
  }

  void _handleStatusUpdate(FlashcardStatusState state) {
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
      return;
    }
    if (state.status.isSuccess && state.flashcardId == current.id) {
      final updatedBack = state.back;
      final updatedStatus = state.cardStatus;
      if (updatedBack != null || updatedStatus != null) {
        final updated = LearnFlashcardModel(
          id: current.id,
          front: current.front,
          back: updatedBack ?? current.back,
          order: current.order,
          status: updatedStatus ?? current.status,
        );
        cards[index] = updated;
      }
    }
  }

  /// --- Widgets ---

  Widget get header => Column(children: [
        Text(widget.flashcardSetModel.title, style: Style.body3w7(context)),
        const SizedBox(height: 4),
        Text(progress, style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget get flashCard => FlashcardView(
      flashcard: current,
      showMeaning: shouldShowMeaning,
      onToggle: toggleFace,
      isLoading: isSubmitting);

  Widget controls(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(children: [
        Expanded(
            child: Button.border(
                onTap: hasSeenMeaning ? () => _nextCard(resetFace: true) : onKnowIt,
                text: hasSeenMeaning ? "Next" : "I know it",
                isAvialable: !isSubmitting)),
        const SizedBox(width: 12),
        Expanded(
            child: Button.border(
                onTap: onStudyAgain, text: 'Study again'.tr(), isAvialable: !isSubmitting)),
      ]));

  Widget get view => PrimaryBackground(
      header: header,
      headerTooltipText: widget.flashcardSetModel.title,
      child: Column(children: [
        const SizedBox(height: 24),
        flashCard,
        const SizedBox(height: 20),
        controls(context)
      ]));

  Widget get resultView => FlashcardSprintResultView(stats: resultStats);

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
          body: cards.isEmpty
              ? emptyView
              : stage == FlashcardSprintStage.result
                  ? resultView
                  : view));
}
