import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/sections_types/reading_section/reading_section_lesson.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_quiz_component.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_state.dart';
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
    if (widget.sectionModel.id.isNotEmpty) {
      detailBloc.add(SectionDetailRequested(
          sectionId: widget.sectionModel.id, source: widget.sectionModel.source));
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

  /// --- Widgets  ---

  /// --- Widgets ---

  Widget get header => Column(children: [
        Text(widget.sectionModel.title, style: Style.body2w6(context)),
        const SizedBox(height: 2),
        Text(widget.sectionModel.sectionType.name.toUpperCase(),
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget body(BuildContext context, SectionDetailState state) {
    final isLoading = state.status.isLoading || state.detail == null;
    if (stage == ReadingSectionStage.lesson)
      return ReadingSectionLesson(
          sectionModel: widget.sectionModel,
          changeStage: () => changeStage(state),
          isLoading: isLoading);
    if (stage == ReadingSectionStage.quiz)
      return SectionQuizComponent(questions: state.detail?.questions ?? [], onFinish: finishQuiz);
    if (stage == ReadingSectionStage.result) return const QuizResultComponent();
    return ReadingSectionLesson(
        sectionModel: widget.sectionModel,
        changeStage: () => changeStage(state),
        isLoading: isLoading);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          header: header,
          isHeader: stage != ReadingSectionStage.result,
          isScrollable: stage == ReadingSectionStage.quiz,
          child: BlocBuilder<SectionDetailBloc, SectionDetailState>(
              bloc: detailBloc, builder: (context, state) => body(context, state))));
}
