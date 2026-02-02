import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_sentence_builder_set_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_status_bloc/practice_sentence_builder_status_bloc.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_status_bloc/practice_sentence_builder_status_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_status_bloc/practice_sentence_builder_status_state.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/practice_build_sentence_content.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';
import 'package:ustadia_user_app/injection_container.dart';

class PracticeBuildSentencePage extends StatefulWidget {
  final PracticeSentenceBuilderSetModel set;
  const PracticeBuildSentencePage({super.key, required this.set});

  @override
  State<PracticeBuildSentencePage> createState() => _PracticeBuildSentencePageState();
}

class _PracticeBuildSentencePageState extends State<PracticeBuildSentencePage> {
  final PracticeSentenceBuilderStatusBloc statusBloc = sl<PracticeSentenceBuilderStatusBloc>();
  final ProfileStatisticsStore statisticsStore = sl<ProfileStatisticsStore>();
  bool showResult = false;

  /// --- Data ---

  PracticeSentenceBuilderQuestionModel? get firstQuestion =>
      widget.set.questions.isNotEmpty ? widget.set.questions.first : null;

  List<String> get correctOrder => firstQuestion?.correctOrder ?? const [];

  int get totalQuestions =>
      widget.set.totalQuestions > 0 ? widget.set.totalQuestions : widget.set.questions.length;

  @override
  void dispose() {
    statusBloc.close();
    super.dispose();
  }

  void submitCompleted() {
    statusBloc.add(PracticeSentenceBuilderStatusRequested(
        sentenceBuilderId: widget.set.id, status: 'completed'));
  }

  /// --- Widgets ---

  Widget get view => PrimaryBackground(
      title: widget.set.title.isEmpty ? 'Build the sentence' : widget.set.title,
      child: Center(
          child: correctOrder.isEmpty
              ? const Text('No questions found')
              : PracticeBuildSentenceContent(
                  correctOrder: correctOrder, onCompleted: submitCompleted)));

  @override
  Widget build(BuildContext context) => BlocListener<PracticeSentenceBuilderStatusBloc,
          PracticeSentenceBuilderStatusState>(
      bloc: statusBloc,
      listener: (context, state) {
        if (state.status.isError && state.errorMessage != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
        }
        if (state.status.isSuccess) {
          statisticsStore.refresh();
          setState(() => showResult = true);
        }
      },
      child: Scaffold(
          backgroundColor: context.cs.surface,
          body: SafeArea(
              child: showResult
                  ? QuizResultComponent(all: totalQuestions, correctOnes: totalQuestions)
                  : view)));
}
