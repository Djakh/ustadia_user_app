import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_word_match_set_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_word_match_status_bloc/practice_word_match_status_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_word_match_status_bloc/practice_word_match_status_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_word_match_status_bloc/practice_word_match_status_state.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/cards/practice_word_match_card.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/practice_word_match_content.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';
import 'package:ustadia_user_app/injection_container.dart';

class PracticeWordMatchPage extends StatefulWidget {
  final PracticeWordMatchSetModel set;
  const PracticeWordMatchPage({super.key, required this.set});

  @override
  State<PracticeWordMatchPage> createState() => _PracticeWordMatchPageState();
}

class _PracticeWordMatchPageState extends State<PracticeWordMatchPage> {
  final PracticeWordMatchStatusBloc statusBloc = sl<PracticeWordMatchStatusBloc>();
  final ProfileStatisticsStore statisticsStore = sl<ProfileStatisticsStore>();
  final GlobalKey cardsKey = GlobalKey(debugLabel: 'word_match_cards');
  bool showResult = false;
  int wrongAttempts = 0;

  /// --- Data ---

  List<PracticeWordMatchCardData> get sources => widget.set.options
      .where((option) => option.isSource)
      .map((option) => PracticeWordMatchCardData(pairId: option.pairId, text: option.word))
      .toList();

  List<PracticeWordMatchCardData> get targets => widget.set.options
      .where((option) => !option.isSource)
      .map((option) => PracticeWordMatchCardData(pairId: option.pairId, text: option.word))
      .toList();

  int get totalPairs => sources.length;

  @override
  void dispose() {
    statusBloc.close();
    super.dispose();
  }

  void submitCompleted() {
    statusBloc.add(PracticeWordMatchStatusRequested(
        wordMatchId: widget.set.id,
        status: 'completed',
        correctAnswers: 1,
        wrongAnswers: wrongAttempts));
  }

  void onWrongAttempt() => setState(() => wrongAttempts++);

  /// --- Widgets ---

  Widget get view => PrimaryBackground(
      title: widget.set.title.isEmpty ? 'Word match' : widget.set.title,
      isScrollable: true,
      child: Column(children: [
        const SizedBox(height: 24),
        KeyedSubtree(
            key: cardsKey,
            child: PracticeWordMatchContent(
                sources: sources,
                targets: targets,
                onCompleted: submitCompleted,
                onWrongAttempt: onWrongAttempt)),
      ]));

  @override
  Widget build(BuildContext context) =>
      BlocListener<PracticeWordMatchStatusBloc, PracticeWordMatchStatusState>(
          bloc: statusBloc,
          listener: (context, state) {
            if (state.status.isError && state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
            if (state.status.isSuccess) {
              statisticsStore.refresh();
              setState(() => showResult = true);
            }
          },
          child: Scaffold(
              backgroundColor: context.cs.surface,
              body: SafeArea(
                  child: showResult
                      ? QuizResultComponent(all: totalPairs, correctOnes: totalPairs)
                      : GuidedTutorialPage(
                          pageId: '${TutorialPageIds.practiceSession}.word_match',
                          steps: TutorialPresets.wordMatchPractice(cardsKey: cardsKey),
                          child: view))));
}
