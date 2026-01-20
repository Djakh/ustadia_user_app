import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';

class LearnReadingLesson extends StatelessWidget {
  final LearnSectionModel sectionModel;
  final Function() changeStage;
  final bool isLoading;
  const LearnReadingLesson(
      {super.key, required this.sectionModel, required this.changeStage, required this.isLoading});

  /// --- Widgets ---

  Widget content(BuildContext context) => SingleChildScrollView(
        child: Text(
          sectionModel.content,
          style: Style.bodyw4(context),
        ),
      );

  Widget view(BuildContext context) => Column(children: [
        const SizedBox(height: 24),
        Expanded(child: content(context)),
        const SizedBox(height: 8),
        Button.primary(onTap: changeStage, text: 'Continue', isAvialable: !isLoading)
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
