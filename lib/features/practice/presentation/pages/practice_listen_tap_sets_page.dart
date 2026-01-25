import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_listen_tap_set_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_sets_bloc/practice_listen_tap_sets_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_sets_bloc/practice_listen_tap_sets_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_sets_bloc/practice_listen_tap_sets_state.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class PracticeListenTapSetsPage extends StatefulWidget {
  const PracticeListenTapSetsPage({super.key});

  @override
  State<PracticeListenTapSetsPage> createState() => _PracticeListenTapSetsPageState();
}

class _PracticeListenTapSetsPageState extends State<PracticeListenTapSetsPage> {
  final PracticeListenTapSetsBloc setsBloc = sl<PracticeListenTapSetsBloc>();

  @override
  void initState() {
    super.initState();
    setsBloc.add(const PracticeListenTapSetsRequested());
  }

  @override
  void dispose() {
    setsBloc.close();
    super.dispose();
  }

  void openSet(PracticeListenTapSetModel set) {
    context.push(listenTapRoute, extra: set);
  }

  Widget setCard(BuildContext context, PracticeListenTapSetModel set) => PrimaryBox(
      onTap: () => openSet(set),
      child: Row(children: [
        ClipRRect(
            borderRadius: Style.border12,
            child: Image.asset(AppImages.listenTap, height: 56, width: 56, fit: BoxFit.cover)),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(set.title, style: Style.body2w5(context)),
          const SizedBox(height: 4),
          Text(set.description, style: Style.small3w4(context, color: TextColorRole.greyColor))
        ]))
      ]));

  Widget setsList(BuildContext context, List<PracticeListenTapSetModel> sets) => ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: sets.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => setCard(context, sets[index]));

  Widget get contentChecker => BlocStatusView<PracticeListenTapSetsBloc, PracticeListenTapSetsState,
          List<PracticeListenTapSetModel>>(
      bloc: setsBloc,
      statusOf: (s) => s.status,
      errorOf: (s) => s.errorMessage,
      data: (s) => s.sets,
      isEmpty: (sets) => sets.isEmpty,
      empty: const Center(child: Text('No listen & tap sets found')),
      builder: (context, sets) => setsList(context, sets));

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: 'Listen & Tap',
          child: ListView(children: [
            const SizedBox(height: 16),
            contentChecker,
            const SizedBox(height: 80),
          ])));
}
