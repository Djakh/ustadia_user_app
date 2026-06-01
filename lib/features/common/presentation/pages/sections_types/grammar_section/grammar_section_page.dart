import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/text/html_text.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/sections_types/grammar_section/grammar_section_intro.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_quiz_component.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_quiz_panel_action_button.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_timer_badge.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_state.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum GrammarSectionStage { intro, quiz, result }

class GrammarSectionPage extends StatefulWidget {
  final SectionModel sectionModel;

  const GrammarSectionPage({super.key, required this.sectionModel});

  @override
  State<GrammarSectionPage> createState() => GrammarSectionPageState();
}

class GrammarSectionPageState extends State<GrammarSectionPage> {
  final SectionDetailBloc detailBloc = sl<SectionDetailBloc>();
  GrammarSectionStage stage = GrammarSectionStage.intro;
  int correctCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.sectionModel.progressState == SectionProgressState.completed) {
      stage = GrammarSectionStage.result;
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

  /// --- Methods ---

  void changeStage(SectionDetailState state) {
    if (state.status.isLoading || state.detail == null) return;
    setState(() => stage = GrammarSectionStage.quiz);
  }

  void finishQuiz(int correct) {
    if (widget.sectionModel.source == SectionSource.mockExam) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      correctCount = correct;
      stage = GrammarSectionStage.result;
    });
  }

  void closeMockExamSectionOnTimerExpired() {
    if (widget.sectionModel.source != SectionSource.mockExam || !mounted) return;
    Navigator.of(context).pop(true);
  }

  Future<void> showGrammarSheet(String content) => showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => Container(
          height: MediaQuery.of(sheetContext).size.height * 0.78,
          decoration: BoxDecoration(
              color: sheetContext.cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
          child: SafeArea(
              top: false,
              child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                    Center(
                        child: Container(
                            width: 46,
                            height: 5,
                            decoration: BoxDecoration(
                                color: sheetContext.cs.outline.withValues(alpha: 0.25),
                                borderRadius: BorderRadius.circular(999)))),
                    const SizedBox(height: 18),
                    Row(children: [
                      Expanded(
                          child: Text('Grammar rules'.tr(), style: Style.body2w6(sheetContext))),
                      IconButton(
                          onPressed: () => Navigator.of(sheetContext).pop(),
                          icon: const Icon(Icons.close_rounded))
                    ]),
                    const SizedBox(height: 8),
                    Expanded(
                        child: SingleChildScrollView(
                            child: HtmlText(
                                data: content,
                                textStyle: Style.bodyw4(sheetContext),
                                textAlign: TextAlign.justify)))
                  ])))));

  Widget? quizHeaderWidget(SectionDetailState state) {
    final detail = state.detail;
    if (detail?.timeRemainingSeconds == null) return null;
    return SectionTimerBadge(
        timeRemainingSeconds: detail?.timeRemainingSeconds,
        onExpired: closeMockExamSectionOnTimerExpired);
  }

  Widget timerBadge(SectionDetailState state) {
    final detail = state.detail;
    if (detail?.timeRemainingSeconds == null) {
      return const SizedBox.shrink();
    }
    return Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 12),
        child: SectionTimerBadge(
            timeRemainingSeconds: detail?.timeRemainingSeconds,
            onExpired: closeMockExamSectionOnTimerExpired));
  }

  Widget introView(SectionDetailState state, bool isLoading) => Column(children: [
        timerBadge(state),
        Expanded(
            child: GrammarSectionIntro(
                sectionModel: state.detail ?? widget.sectionModel,
                changeStage: () => changeStage(state),
                isLoading: isLoading))
      ]);

  /// --- Widgets ---
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
    if (stage == GrammarSectionStage.intro) return introView(state, isLoading);
    if (stage == GrammarSectionStage.quiz)
      return SectionQuizComponent(
          questions: state.detail?.questions ?? [],
          sectionContent: state.detail?.content ?? widget.sectionModel.content,
          headerWidget: quizHeaderWidget(state),
          panelActionBuilder: (context, isResultState, panelColor) => SectionQuizPanelActionButton(
              onTap: () => showGrammarSheet(state.detail?.content ?? widget.sectionModel.content),
              isResultState: isResultState,
              panelColor: panelColor,
              label: 'Read'),
          onFinish: finishQuiz);
    if (stage == GrammarSectionStage.result) {
      return QuizResultComponent(sectionModel: widget.sectionModel);
    }
    return introView(state, isLoading);
  }

  @override
  Widget build(BuildContext context) => GuidedTutorialPage(
      pageId: '${TutorialPageIds.section}.grammar',
      steps: TutorialPresets.section(sectionType: 'grammar'),
      child: Scaffold(
          backgroundColor: context.cs.surface,
          body: PrimaryBackground(
              header: header,
              headerTooltipText: widget.sectionModel.title,
              padding: stage == GrammarSectionStage.quiz ? EdgeInsets.zero : null,
              margin:
                  stage == GrammarSectionStage.quiz ? const EdgeInsets.fromLTRB(8, 8, 8, 0) : null,
              applyBottomSafeArea: stage != GrammarSectionStage.quiz,
              isHeader: stage != GrammarSectionStage.result,
              isScrollable: false,
              alwaysScrollable: false,
              child: BlocBuilder<SectionDetailBloc, SectionDetailState>(
                  bloc: detailBloc, builder: (context, state) => body(context, state)))));
}
