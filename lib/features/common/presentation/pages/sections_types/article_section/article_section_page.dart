import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_state.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/sections_types/article_section/article_section_intro.dart';
import 'package:ustadia_user_app/injection_container.dart';

class ArticleSectionPage extends StatefulWidget {
  final SectionModel sectionModel;

  const ArticleSectionPage({super.key, required this.sectionModel});

  @override
  State<ArticleSectionPage> createState() => _ArticleSectionPageState();
}

class _ArticleSectionPageState extends State<ArticleSectionPage> {
  final SectionDetailBloc detailBloc = sl<SectionDetailBloc>();

  @override
  void initState() {
    super.initState();
    if (widget.sectionModel.id.isNotEmpty) {
      detailBloc.add(SectionDetailRequested(
          sectionId: widget.sectionModel.id,
          source: widget.sectionModel.source,
          unitId: widget.sectionModel.unitId,
          lessonId: widget.sectionModel.lessonId,
          assignmentId: widget.sectionModel.assignmentId,
          mockExamId: widget.sectionModel.mockId,
          mockAttemptId: widget.sectionModel.mockAttemptId));
    }
  }

  @override
  void dispose() {
    detailBloc.close();
    super.dispose();
  }

  Widget get header => Column(children: [
        Text(widget.sectionModel.title,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: Style.body2w6(context)),
        const SizedBox(height: 2),
        Text(widget.sectionModel.sectionTypeLabel.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget body(SectionDetailState state) {
    final isLoading = state.status.isInitial || state.status.isLoading;
    // Articles are optional read-only material. Their completion flag is always
    // true, so they must never enter the shared quiz or result flow.
    return ArticleSectionIntro(
        sectionModel: state.detail ?? widget.sectionModel, isLoading: isLoading);
  }

  @override
  Widget build(BuildContext context) => GuidedTutorialPage(
      pageId: '${TutorialPageIds.section}.article',
      steps: TutorialPresets.section(sectionType: 'article'),
      child: Scaffold(
          backgroundColor: context.cs.surface,
          body: PrimaryBackground(
              header: header,
              headerTooltipText: widget.sectionModel.title,
              padding: const EdgeInsets.fromLTRB(4, 12, 4, 0),
              isScrollable: false,
              alwaysScrollable: false,
              child: BlocBuilder<SectionDetailBloc, SectionDetailState>(
                  bloc: detailBloc, builder: (context, state) => body(state)))));
}
