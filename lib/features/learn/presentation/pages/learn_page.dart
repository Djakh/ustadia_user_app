import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/learn_unit_card.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  List<LearnUnitModel> get units => LearnUnitModel.sampleUnits;

  Widget grid(BuildContext context) => GridView.builder(
      padding: EdgeInsets.zero,
      itemCount: units.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.92),
      itemBuilder: (context, index) => LearnUnitCard(unit: units[index]));

  Widget body(BuildContext context) => Column(children: [
        const SizedBox(height: 12),
        grid(context),
        const SizedBox(height: 80)
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: 'Learn',
          isScrollable: true,
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 4), child: body(context))));
}
