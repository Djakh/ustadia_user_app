import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/flashcard_sprint/flashcard_sprint_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_flashcard_sets_bloc/practice_flashcard_sets_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_flashcard_sets_bloc/practice_flashcard_sets_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_flashcard_sets_bloc/practice_flashcard_sets_state.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class PracticeFlashcardSetsPage extends StatefulWidget {
  const PracticeFlashcardSetsPage({super.key});

  @override
  State<PracticeFlashcardSetsPage> createState() => _PracticeFlashcardSetsPageState();
}

class _PracticeFlashcardSetsPageState extends State<PracticeFlashcardSetsPage> {
  final PracticeFlashcardSetsBloc setsBloc = sl<PracticeFlashcardSetsBloc>();

  @override
  void initState() {
    super.initState();
    if (setsBloc.state.sets.isEmpty) {
      setsBloc.add(const PracticeFlashcardSetsRequested());
    }
  }

  @override
  void dispose() => super.dispose();

  void openSet(LearnFlashcardSetModel set) {
    context.push(flashcardSprintRoute, extra: FlashcardSprintParams(set: set, isPractice: true));
  }

  Future<void> reloadSets() async {
    setsBloc.add(const PracticeFlashcardSetsRequested());
  }

  Widget setCard(BuildContext context, LearnFlashcardSetModel set) => PrimaryBox(
      onTap: () => openSet(set),
      child: Row(children: [
        ClipRRect(
            borderRadius: Style.border12,
            child:
                Image.asset(AppImages.flashcardSprint, height: 56, width: 56, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(set.title, style: Style.body2w5(context)),
          const SizedBox(height: 4),
          Text(set.description, style: Style.small3w4(context, color: TextColorRole.greyColor))
        ]))
      ]));

  Widget setsList(BuildContext context, List<LearnFlashcardSetModel> sets) => ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: sets.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => setCard(context, sets[index]));

  Widget get contentChecker => BlocStatusView<PracticeFlashcardSetsBloc, PracticeFlashcardSetsState,
          List<LearnFlashcardSetModel>>(
      bloc: setsBloc,
      statusOf: (s) => s.status,
      errorOf: (s) => s.errorMessage,
      data: (s) => s.sets,
      isEmpty: (sets) => sets.isEmpty,
      keepDataOnLoading: true,
      loading: const ShimmerList(
          itemCount: 5,
          itemHeight: 92,
          padding: EdgeInsets.symmetric(vertical: 12),
          borderRadius: BorderRadius.all(Radius.circular(20))),
      empty: Center(child: Text('No flashcard sets found'.tr())),
      builder: (context, sets) => setsList(context, sets));

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: 'Flashcard sprint'.tr(),
          child: RefreshIndicator(
              onRefresh: reloadSets,
              child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                const SizedBox(height: 16),
                contentChecker,
                const SizedBox(height: 80),
              ]))));
}
