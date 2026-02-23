import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_grid.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_lesson_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_sections_params.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_units_bloc/learn_units_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_units_bloc/learn_units_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_units_bloc/learn_units_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/learn_unit_card.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class LearnUnitsPage extends StatefulWidget {
  final LearnLessonModel learnLessonModel;

  const LearnUnitsPage({super.key, required this.learnLessonModel});

  @override
  State<LearnUnitsPage> createState() => LearnUnitsPageState();
}

class LearnUnitsPageState extends State<LearnUnitsPage> {
  final LearnUnitsBloc unitsBloc = sl<LearnUnitsBloc>();
  bool shouldRefreshParent = false;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    if (widget.learnLessonModel.id.isNotEmpty &&
        (unitsBloc.state.units.isEmpty ||
            unitsBloc.state.lessonId != widget.learnLessonModel.id)) {
      unitsBloc.add(LearnUnitsRequested(lessonId: widget.learnLessonModel.id));
    }
  }

  @override
  void dispose() => super.dispose();

  Future<void> openUnit(BuildContext context, LearnUnitModel unit) async {
    final result = await context.push<bool?>(learnSectionsRoute,
        extra: LearnSectionsParams(unit: unit, lessonId: widget.learnLessonModel.id));
    if (!context.mounted) return;
    if (result == true) {
      shouldRefreshParent = true;
      unitsBloc.add(LearnUnitsRequested(lessonId: widget.learnLessonModel.id));
    }
  }

  /// --- Widgets ---

  Widget get subtitle => Text(widget.learnLessonModel.description,
      style: Style.small3w5(context, color: TextColorRole.greyColor));

  Widget get subtitleCard => PrimaryBox(isTappable: false, width: double.infinity, child: subtitle);

  Widget grid(BuildContext context, List<LearnUnitModel> units) => GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: units.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.92),
      itemBuilder: (context, index) =>
          LearnUnitCard(unit: units[index], onTap: () => openUnit(context, units[index])));

  Widget view(BuildContext context, List<LearnUnitModel> units) => ListView(children: [
        const SizedBox(height: 24),
        subtitleCard,
        const SizedBox(height: 12),
        grid(context, units)
      ]);

  Widget get contentChecker =>
      BlocStatusView<LearnUnitsBloc, LearnUnitsState, List<LearnUnitModel>>(
        bloc: unitsBloc,
        invalid: widget.learnLessonModel.id.isEmpty
            ? Center(child: Text('Lesson not found'.tr()))
            : null,
        statusOf: (s) => s.status,
        errorOf: (s) => s.errorMessage,
        data: (s) => s.units,
        isEmpty: (units) => units.isEmpty,
        keepDataOnLoading: false,
        empty: Center(child: Text('No units found'.tr())),
        loading: Column(children: [
          const SizedBox(height: 24),
          const ShimmerList(
              itemCount: 1,
              itemHeight: 54,
              padding: EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.all(Radius.circular(12))),
          const SizedBox(height: 12),
          const ShimmerGrid(
              itemCount: 4,
              crossAxisCount: 2,
              childAspectRatio: 0.92,
              padding: EdgeInsets.symmetric(horizontal: 16),
              borderRadius: BorderRadius.all(Radius.circular(20)))
        ]),
        builder: (context, units) => view(context, units),
      );

  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: () async {
        if (!context.mounted) return false;
        context.pop(shouldRefreshParent ? true : null);
        return false;
      },
      child: Scaffold(
          backgroundColor: context.cs.surface,
          body: PrimaryBackground(
              title: widget.learnLessonModel.name.isEmpty ? 'Learn' : widget.learnLessonModel.name,
              onBack: () => context.pop(shouldRefreshParent ? true : null),
              child: contentChecker)));
}
