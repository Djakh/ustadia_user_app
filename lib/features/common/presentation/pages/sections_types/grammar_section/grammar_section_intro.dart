import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/translatable_section_content.dart';

class GrammarSectionIntro extends StatelessWidget {
  final SectionModel sectionModel;
  final Function() changeStage;
  final bool isLoading;
  const GrammarSectionIntro({
    super.key,
    required this.changeStage,
    required this.sectionModel,
    required this.isLoading,
  });

  /// --- Widgets ---

  Widget htmlContent(BuildContext context) => TranslatableSectionContent(
      data: sectionModel.content, textAlign: TextAlign.justify, textStyle: Style.bodyw4(context));

  Widget view(BuildContext context) => Column(children: [
        const SizedBox(height: 24),
        Expanded(child: SingleChildScrollView(child: htmlContent(context))),
        const SizedBox(height: 24),
        Button.primary(onTap: changeStage, text: 'Continue'.tr(), isAvialable: !isLoading)
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
