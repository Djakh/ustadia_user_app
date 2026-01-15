import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_lesson_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_units_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_units_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_units_state.dart';
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

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    if (widget.learnLessonModel.id.isNotEmpty) {
      unitsBloc.add(LearnUnitsRequested(lessonId: widget.learnLessonModel.id));
    }
  }

  @override
  void dispose() {
    unitsBloc.close();
    super.dispose();
  }

  void openUnit(BuildContext context, LearnUnitModel unit) =>
      context.push(learnSectionsRoute, extra: unit);

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
            ? const Center(child: Text('Lesson not found'))
            : null,
        statusOf: (s) => s.status,
        errorOf: (s) => s.errorMessage,
        data: (s) => s.units,
        isEmpty: (units) => units.isEmpty,
        empty: const Center(child: Text('No units found')),
        builder: (context, units) => view(context, units),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: widget.learnLessonModel.name.isEmpty ? 'Learn' : widget.learnLessonModel.name,
          child: contentChecker));
}
