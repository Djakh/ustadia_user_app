import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/text/html_text.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_state.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/sections_types/reading_section/reading_section_intro.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_quiz_component.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum ReadingSectionStage { lesson, quiz, result }

class ReadingSectionPage extends StatefulWidget {
  final SectionModel sectionModel;

  const ReadingSectionPage({super.key, required this.sectionModel});

  @override
  State<ReadingSectionPage> createState() => ReadingSectionPageState();
}

class ReadingSectionPageState extends State<ReadingSectionPage> {
  final SectionDetailBloc detailBloc = sl<SectionDetailBloc>();
  ReadingSectionStage stage = ReadingSectionStage.lesson;
  int correctCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.sectionModel.progressState == SectionProgressState.completed) {
      stage = ReadingSectionStage.result;
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
    setState(() => stage = ReadingSectionStage.quiz);
  }

  void finishQuiz(int correct) => setState(() {
        correctCount = correct;
        stage = ReadingSectionStage.result;
      });

  Future<void> showReadingPassageSheet(String content) => showModalBottomSheet(
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
                          child:
                              Text('Read passage'.tr(), style: Style.body2w6(sheetContext))),
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

  Widget readingPassageButton(String content, bool isResultState, Color panelColor) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: () => showReadingPassageSheet(content),
          borderRadius: BorderRadius.circular(18),
          child: Ink(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                  color: isResultState ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: isResultState
                          ? Colors.white.withValues(alpha: 0.9)
                          : context.cs.outline.withValues(alpha: 0.2))),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.menu_book_rounded,
                    size: 18, color: isResultState ? panelColor : context.cs.primary),
                const SizedBox(width: 6),
                Text('Read'.tr(),
                    style: Style.bodyw5(context)
                        .copyWith(color: isResultState ? panelColor : context.cs.primary))
              ]))));

  /// --- Widgets  ---

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
    if (stage == ReadingSectionStage.lesson)
      return ReadingSectionIntro(
          sectionModel: widget.sectionModel,
          changeStage: () => changeStage(state),
          isLoading: isLoading);
    if (stage == ReadingSectionStage.quiz)
      return SectionQuizComponent(
          questions: state.detail?.questions ?? [],
          onFinish: finishQuiz,
          panelActionBuilder: (context, isResultState, panelColor) => readingPassageButton(
              state.detail?.content ?? widget.sectionModel.content, isResultState, panelColor));
    if (stage == ReadingSectionStage.result) {
      return QuizResultComponent(sectionModel: widget.sectionModel);
    }
    return ReadingSectionIntro(
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
          padding: stage == ReadingSectionStage.quiz ? EdgeInsets.zero : null,
          margin: stage == ReadingSectionStage.quiz ? const EdgeInsets.fromLTRB(8, 8, 8, 0) : null,
          applyBottomSafeArea: stage != ReadingSectionStage.quiz,
          isHeader: stage != ReadingSectionStage.result,
          isScrollable: false,
          alwaysScrollable: false,
          child: BlocBuilder<SectionDetailBloc, SectionDetailState>(
              bloc: detailBloc, builder: (context, state) => body(context, state))));
}
