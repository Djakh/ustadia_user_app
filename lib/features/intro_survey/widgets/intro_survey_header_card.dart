import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';

class IntroSurveyHeaderCard extends StatelessWidget {
  final int stepIndex;
  final int totalSteps;
  final String title;
  final String subtitle;

  const IntroSurveyHeaderCard(
      {super.key,
      required this.stepIndex,
      required this.totalSteps,
      required this.title,
      required this.subtitle});

  /// --- Methods ---

  /// --- Widgets ---

  Widget indicator(BuildContext context) => PageIndicator(
      currentIndex: stepIndex,
      total: totalSteps,
      activeColor: context.cs.primary,
      inactiveColor: context.cs.onTertiary.withAlpha(89),
      itemWidth: 44);

  Widget stepText(BuildContext context) => Text('Step ${stepIndex + 1} of $totalSteps',
      style: Style.small2w4(context, color: TextColorRole.greyColor));

  Widget titleText(BuildContext context) => Text(title, style: Style.body2w6(context));

  Widget subtitleText(BuildContext context) =>
      Text(subtitle, style: Style.small3w4(context, color: TextColorRole.greyColor));

  Widget get spacerBelowTopRow => const SizedBox(height: 14);

  Widget get spacerBelowTitle => const SizedBox(height: 6);

  Widget view(BuildContext context) => Container(
          padding: const EdgeInsets.all(16),
          decoration:
              BoxDecoration(color: context.cs.secondaryContainer, borderRadius: Style.border20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: indicator(context)),
              stepText(context)
            ]),
            spacerBelowTopRow,
            titleText(context),
            spacerBelowTitle,
            subtitleText(context)
          ]));

  @override
  Widget build(BuildContext context) => view(context);
}
