import 'package:flutter/material.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/section_image_links_view.dart';

/// Read-only article content containing the teacher-uploaded image and links.
class ArticleSectionIntro extends StatelessWidget {
  final SectionModel sectionModel;
  final bool isLoading;

  const ArticleSectionIntro({
    super.key,
    required this.sectionModel,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = sectionModel.image?.url.isNotEmpty == true;
    if (isLoading && !hasImage) {
      return const Center(child: CircularProgressIndicator());
    }
    return SingleChildScrollView(
        padding: const EdgeInsets.only(top: 24),
        child: SectionImageLinksView(sectionModel: sectionModel));
  }
}
