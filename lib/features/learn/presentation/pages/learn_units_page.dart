import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/learn_unit_card.dart';
import 'package:ustadia_user_app/router.dart';

class LearnUnitsPage extends StatelessWidget {
  const LearnUnitsPage({super.key});

  List<LearnUnitModel> get units => LearnUnitModel.sampleUnits;

  void openUnit(BuildContext context, LearnUnitModel unit) =>
      context.push(learnLessonsRoute, extra: unit);

  Widget grid(BuildContext context) => GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: units.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.92),
      itemBuilder: (context, index) =>
          LearnUnitCard(unit: units[index], onTap: () => openUnit(context, units[index])));

  Widget body(BuildContext context) =>
      Column(children: [const SizedBox(height: 12), grid(context), const SizedBox(height: 80)]);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: 'Learn',
          isScrollable: true,
          child:
              Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: body(context))));
}
