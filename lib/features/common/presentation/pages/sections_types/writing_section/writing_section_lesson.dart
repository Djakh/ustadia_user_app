import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_question_model.dart';

class WritingSectionLesson extends StatelessWidget {
  final SectionModel sectionDetailModel;
  final Function() onTapContinue;
  const WritingSectionLesson(
      {super.key, required this.sectionDetailModel, required this.onTapContinue});

  /// --- Getters ---

  SectionQuestionModel? get question =>
      sectionDetailModel.questions.isNotEmpty ? sectionDetailModel.questions.first : null;

  /// --- Widgets ---

  Widget lessonTitle(BuildContext context) =>
      Text(question?.title ?? "", style: Style.body2w5(context));

  Widget get lessonParagraph => Builder(
      builder: (context) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(question?.description?.trim() ?? "",
              textAlign: TextAlign.justify, style: Style.bodyw4(context))));

  Widget lessonContent(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [lessonTitle(context), const SizedBox(height: 12), lessonParagraph]);

  Widget view(BuildContext context) => Column(children: [
        Expanded(child: SingleChildScrollView(child: lessonContent(context))),
        const SizedBox(height: 16),
        Button.primary(onTap: onTapContinue, text: 'Continue'.tr())
      ]);

  @override
  Widget build(BuildContext context) => view(context);
}
