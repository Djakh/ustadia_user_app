import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/translatable_section_content.dart';

class ReadingSectionIntro extends StatelessWidget {
  final SectionModel sectionModel;
  final Function() changeStage;
  final bool isLoading;
  const ReadingSectionIntro(
      {super.key, required this.sectionModel, required this.changeStage, required this.isLoading});

  /// --- Widgets ---

  Widget content(BuildContext context) => SingleChildScrollView(
        child: TranslatableSectionContent(
            data: sectionModel.content, textStyle: Style.bodyw4(context)),
      );

  Widget view(BuildContext context) => Column(children: [
        const SizedBox(height: 24),
        Expanded(child: content(context)),
        const SizedBox(height: 8),
        Button.primary(onTap: changeStage, text: 'Continue'.tr(), isAvialable: !isLoading)
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
