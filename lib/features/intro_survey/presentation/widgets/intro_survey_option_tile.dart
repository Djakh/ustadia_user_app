import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/boxes/primary_box.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_models.dart';

class IntroSurveyOptionTile extends StatelessWidget {
  final IntroSurveyOptionModel option;
  final bool selected;
  final VoidCallback onTap;

  const IntroSurveyOptionTile(
      {super.key, required this.option, required this.selected, required this.onTap});

  /// --- Methods ---

  Color borderColor(BuildContext context) =>
      selected ? context.cs.primary : context.cs.onTertiary.withAlpha(64);

  Color fillColor(BuildContext context) => selected ? context.cs.primary.withAlpha(15) : context.cs.surface;

  /// --- Widgets ---

  Widget leading(BuildContext context) => selected
      ? Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: context.cs.primary, shape: BoxShape.circle),
          child: const Center(child: Icon(Icons.check, size: 12, color: Colors.white)))
      : Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(
              border: Border.all(color: context.cs.onTertiary.withAlpha(140), width: 1.4),
              shape: BoxShape.circle));

  Widget titleText(BuildContext context) => Text(option.title, style: Style.small3w5(context));

  Widget descriptionText(BuildContext context) =>
      Text(option.description, style: Style.small2w4(context, color: TextColorRole.greyColor));

  Widget content(BuildContext context) => Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        leading(context),
        const SizedBox(width: 12),
        Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          titleText(context),
          const SizedBox(height: 2),
          descriptionText(context),
        ]))
      ]);

  Widget view(BuildContext context) =>
   PrimaryBox(
      onTap: onTap,
      padding: const EdgeInsets.all( 14),
      borderRadius: Style.border14,
      backgroundColor: fillColor(context),
      border: Border.all(color: borderColor(context), width: selected ? 1.5 : 1),
      child: content(context));
  

  @override
  Widget build(BuildContext context) => view(context);
}

