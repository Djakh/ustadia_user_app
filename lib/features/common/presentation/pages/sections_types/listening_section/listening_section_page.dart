import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_state.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/sections_types/listening_section/listening_section_intro.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_quiz_component.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/audio_card.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum ListeningSectionStage { lesson, quiz, result }

class ListeningSectionPage extends StatefulWidget {
  final SectionModel sectionModel;

  const ListeningSectionPage({super.key, required this.sectionModel});

  @override
  State<ListeningSectionPage> createState() => ListeningSectionPageState();
}

class ListeningSectionPageState extends State<ListeningSectionPage> {
  final SectionDetailBloc detailBloc = sl<SectionDetailBloc>();
  ListeningSectionStage stage = ListeningSectionStage.lesson;
  int correctCount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.sectionModel.id.isNotEmpty) {
      detailBloc.add(SectionDetailRequested(
          sectionId: widget.sectionModel.id,
          source: widget.sectionModel.source,
          unitId: widget.sectionModel.unitId,
          lessonId: widget.sectionModel.lessonId));
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
    setState(() => stage = ListeningSectionStage.quiz);
  }

  void finishQuiz(int correct) => setState(() {
        correctCount = correct;
        stage = ListeningSectionStage.result;
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
    if (stage == ListeningSectionStage.lesson)
      return ListeningSectionIntro(
          sectionModel: widget.sectionModel,
          changeStage: () => changeStage(state),
          isLoading: isLoading);
    if (stage == ListeningSectionStage.quiz)
      return SectionQuizComponent(
          questions: state.detail?.questions ?? [],
          headerWidget: AudioCard(sectionModel: widget.sectionModel),
          onFinish: finishQuiz);
    if (stage == ListeningSectionStage.result) return const QuizResultComponent();
    return ListeningSectionIntro(
        sectionModel: widget.sectionModel,
        changeStage: () => changeStage(state),
        isLoading: isLoading);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          header: header,
          isHeader: stage != ListeningSectionStage.result,
          isScrollable: stage == ListeningSectionStage.quiz,
          child: BlocBuilder<SectionDetailBloc, SectionDetailState>(
              bloc: detailBloc, builder: (context, state) => body(context, state))));
}
