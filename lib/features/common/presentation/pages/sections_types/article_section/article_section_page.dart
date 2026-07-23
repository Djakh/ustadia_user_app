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
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_quiz_component.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_timer_badge.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum ArticleSectionStage { intro, quiz, result }

class ArticleSectionPage extends StatefulWidget {
  final SectionModel sectionModel;

  const ArticleSectionPage({super.key, required this.sectionModel});

  @override
  State<ArticleSectionPage> createState() => _ArticleSectionPageState();
}

class _ArticleSectionPageState extends State<ArticleSectionPage> {
  final SectionDetailBloc detailBloc = sl<SectionDetailBloc>();
  ArticleSectionStage stage = ArticleSectionStage.intro;

  @override
  void initState() {
    super.initState();
    if (widget.sectionModel.progressState == SectionProgressState.completed) {
      stage = ArticleSectionStage.result;
    }
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

  void changeStage(SectionDetailState state) {
    if (state.status.isLoading || state.detail == null) return;
    setState(() => stage = ArticleSectionStage.quiz);
  }

  void finishQuiz(int correct) {
    if (widget.sectionModel.source == SectionSource.mockExam) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() => stage = ArticleSectionStage.result);
  }

  void closeMockExamSectionOnTimerExpired() {
    if (widget.sectionModel.source != SectionSource.mockExam || !mounted) return;
    Navigator.of(context).pop(true);
  }

  Widget? quizHeaderWidget(SectionDetailState state) {
    final timeRemaining = state.detail?.timeRemainingSeconds;
    if (timeRemaining == null) return null;
    return SectionTimerBadge(
        timeRemainingSeconds: timeRemaining, onExpired: closeMockExamSectionOnTimerExpired);
  }

  Widget timerBadge(SectionDetailState state) {
    final timeRemaining = state.detail?.timeRemainingSeconds;
    if (timeRemaining == null) return const SizedBox.shrink();
    return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 12),
        child: SectionTimerBadge(
            timeRemainingSeconds: timeRemaining, onExpired: closeMockExamSectionOnTimerExpired));
  }

  Widget introView(SectionDetailState state, bool isLoading) => Column(children: [
        timerBadge(state),
        Expanded(
            child: ArticleSectionIntro(
                sectionModel: state.detail ?? widget.sectionModel,
                changeStage: () => changeStage(state),
                isLoading: isLoading))
      ]);

  Widget get header => Column(children: [
        Text(widget.sectionModel.title,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: Style.body2w6(context)),
        const SizedBox(height: 2),
        Text(widget.sectionModel.sectionTypeLabel.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget body(BuildContext context, SectionDetailState state) {
    final isLoading = state.status.isLoading || state.detail == null;
    if (widget.sectionModel.source == SectionSource.mockExam &&
        state.detail?.progressState == SectionProgressState.completed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.of(context).pop(true);
      });
      return const SizedBox.shrink();
    }
    if (state.detail?.progressState == SectionProgressState.completed) {
      return QuizResultComponent(sectionModel: widget.sectionModel);
    }
    if (stage == ArticleSectionStage.intro) return introView(state, isLoading);
    if (stage == ArticleSectionStage.quiz) {
      return SectionQuizComponent(
          questions: state.detail?.questions ?? [],
          sectionContent: state.detail?.content ?? widget.sectionModel.content,
          headerWidget: quizHeaderWidget(state),
          onFinish: finishQuiz);
    }
    return QuizResultComponent(sectionModel: widget.sectionModel);
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
              padding: stage == ArticleSectionStage.quiz ? EdgeInsets.zero : null,
              margin:
                  stage == ArticleSectionStage.quiz ? const EdgeInsets.fromLTRB(8, 8, 8, 0) : null,
              applyBottomSafeArea: stage != ArticleSectionStage.quiz,
              isHeader: stage != ArticleSectionStage.result,
              isScrollable: false,
              alwaysScrollable: false,
              child: BlocBuilder<SectionDetailBloc, SectionDetailState>(
                  bloc: detailBloc, builder: (context, state) => body(context, state)))));
}
