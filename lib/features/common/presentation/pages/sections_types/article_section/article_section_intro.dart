import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/section_image_links_view.dart';

/// Article introductions intentionally contain only the teacher-uploaded image.
class ArticleSectionIntro extends StatelessWidget {
  final SectionModel sectionModel;
  final VoidCallback changeStage;
  final bool isLoading;

  const ArticleSectionIntro({
    super.key,
    required this.sectionModel,
    required this.changeStage,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        const SizedBox(height: 24),
        Expanded(
            child: SingleChildScrollView(child: SectionImageLinksView(sectionModel: sectionModel))),
        const SizedBox(height: 24),
        Button.primary(onTap: changeStage, text: 'Continue'.tr(), isAvialable: !isLoading)
      ]);
}
