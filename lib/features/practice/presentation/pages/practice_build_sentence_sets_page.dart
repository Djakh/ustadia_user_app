import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_sentence_builder_set_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_sets_bloc/practice_sentence_builder_sets_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_sets_bloc/practice_sentence_builder_sets_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_sets_bloc/practice_sentence_builder_sets_state.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class PracticeBuildSentenceSetsPage extends StatefulWidget {
  const PracticeBuildSentenceSetsPage({super.key});

  @override
  State<PracticeBuildSentenceSetsPage> createState() => _PracticeBuildSentenceSetsPageState();
}

class _PracticeBuildSentenceSetsPageState extends State<PracticeBuildSentenceSetsPage> {
  final PracticeSentenceBuilderSetsBloc setsBloc = sl<PracticeSentenceBuilderSetsBloc>();

  @override
  void initState() {
    super.initState();
    setsBloc.add(const PracticeSentenceBuilderSetsRequested());
  }

  @override
  void dispose() {
    setsBloc.close();
    super.dispose();
  }

  void openSet(PracticeSentenceBuilderSetModel set) {
    context.push(buildSentenceRoute, extra: set);
  }

  Widget setCard(BuildContext context, PracticeSentenceBuilderSetModel set) => PrimaryBox(
      onTap: () => openSet(set),
      child: Row(children: [
        ClipRRect(
            borderRadius: Style.border12,
            child: Image.asset(AppImages.buildTheSentence, height: 56, width: 56, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(set.title, style: Style.body2w5(context)),
          const SizedBox(height: 4),
          Text(set.description, style: Style.small3w4(context, color: TextColorRole.greyColor))
        ]))
      ]));

  Widget setsList(BuildContext context, List<PracticeSentenceBuilderSetModel> sets) =>
      ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 12),
          itemCount: sets.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, index) => setCard(context, sets[index]));

  Widget get contentChecker =>
      BlocStatusView<PracticeSentenceBuilderSetsBloc, PracticeSentenceBuilderSetsState,
              List<PracticeSentenceBuilderSetModel>>(
          bloc: setsBloc,
          statusOf: (s) => s.status,
          errorOf: (s) => s.errorMessage,
          data: (s) => s.sets,
          isEmpty: (sets) => sets.isEmpty,
          empty: const Center(child: Text('No sentence builder sets found')),
          builder: (context, sets) => setsList(context, sets));

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: 'Build the sentence',
          child: ListView(children: [
            const SizedBox(height: 16),
            contentChecker,
            const SizedBox(height: 80),
          ])));
}
