import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/sections_types/grammar_section/grammar_section_intro.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_quiz_component.dart';
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
          assignmentId: widget.sectionModel.assignmentId));
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

  void finishQuiz(int correct) => setState(() {
        correctCount = correct;
        stage = GrammarSectionStage.result;
      });

  /// --- Widgets ---
  Widget get header => Column(children: [
        Text(widget.sectionModel.title,
            maxLines: 1, overflow: TextOverflow.ellipsis, style: Style.body2w6(context)),
        const SizedBox(height: 2),
        Text(widget.sectionModel.sectionType.name.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget body(BuildContext context, SectionDetailState state) {
    final isLoading = state.status.isLoading || state.detail == null;
    if (stage == GrammarSectionStage.intro)
      return GrammarSectionIntro(
          sectionModel: widget.sectionModel,
          changeStage: () => changeStage(state),
          isLoading: isLoading);
    if (stage == GrammarSectionStage.quiz)
      return SectionQuizComponent(questions: state.detail?.questions ?? [], onFinish: finishQuiz);
    if (stage == GrammarSectionStage.result) {
      return QuizResultComponent(sectionModel: widget.sectionModel);
    }
    return GrammarSectionIntro(
        sectionModel: widget.sectionModel,
        changeStage: () => changeStage(state),
        isLoading: isLoading);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          header: header,
          headerTooltipText: widget.sectionModel.title,
          padding: stage == GrammarSectionStage.quiz ? EdgeInsets.zero : null,
          margin: stage == GrammarSectionStage.quiz
              ? const EdgeInsets.fromLTRB(8, 8, 8, 0)
              : null,
          applyBottomSafeArea: stage != GrammarSectionStage.quiz,
          isHeader: stage != GrammarSectionStage.result,
          isScrollable: false,
          alwaysScrollable: false,
          child: BlocBuilder<SectionDetailBloc, SectionDetailState>(
              bloc: detailBloc, builder: (context, state) => body(context, state))));
}
