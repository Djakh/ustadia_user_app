import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/connection/reload_conntection_button.dart';
import 'package:ustadia_user_app/core/widgets/inputs/input_field.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_writing_method.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_question_answer_bloc/learn_question_answer_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_question_answer_bloc/learn_question_answer_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_question_answer_bloc/learn_question_answer_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc/learn_section_detail_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_writing_section/learn_writing_section_lesson.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/bottom_sheets/learn_writing_bottom_sheet.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum LearnWritingStage { lesson, input, result }

class LearnWritingPage extends StatefulWidget {
  final LearnSectionModel sectionModel;

  const LearnWritingPage({super.key, required this.sectionModel});

  @override
  State<LearnWritingPage> createState() => LearnWritingPageState();
}

class LearnWritingPageState extends State<LearnWritingPage> {
  final LearnSectionDetailBloc detailBloc = sl<LearnSectionDetailBloc>();
  final LearnQuestionAnswerBloc answerBloc = sl<LearnQuestionAnswerBloc>();
  LearnWritingStage stage = LearnWritingStage.lesson;
  LearnWritingMethodType? selectedMethod;
  final TextEditingController inputController = TextEditingController();
  static const String _inputPlaceholder = 'Start writing here';

  @override
  void dispose() {
    inputController.dispose();
    detailBloc.close();
    answerBloc.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.sectionModel.id.isNotEmpty) {
      getSectionDetails();
    }
  }

  /// --- Listeners ---

  void learnQuestionAnswerListener(context, state) {
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
    if (state.status.isSuccess) {
      setState(() => stage = LearnWritingStage.result);
    }
  }

  /// --- Methods ---

  void getSectionDetails() =>
      detailBloc.add(LearnSectionDetailRequested(sectionId: widget.sectionModel.id));

  Future<void> pickUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null) return;
      if (!mounted) return;
      setState(() => stage = LearnWritingStage.result);
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('File picker is not available on this device. Try a real device.')));
    }
  }

  void selectMethod(LearnWritingMethodType type) => setState(() {
        selectedMethod = type;
        stage = type == LearnWritingMethodType.inApp
            ? LearnWritingStage.input
            : LearnWritingStage.result;
      });

  void onSelectMethod(BuildContext sheetContext, LearnWritingMethodType methodType) async {
    Navigator.of(sheetContext).pop();
    if (methodType == LearnWritingMethodType.upload) {
      await pickUploadFile();
      return;
    }
    selectMethod(methodType);
  }

  void submit() {
    final detail = detailBloc.state.detail;
    final question = detail != null && detail.questions.isNotEmpty ? detail.questions.first : null;
    if (question == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Question is not available yet.')));
      return;
    }
    answerBloc.add(LearnQuestionAnswerSubmitted(
      sectionId: widget.sectionModel.id,
      questionId: question.id,
      userInputText: inputController.text.trim(),
    ));
  }

  /// --- Showed Widgets ---
  Future<void> showMethodSheet() => showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => LearnWritingBottomSheet(
          onTap: (LearnWritingMethodType type) => onSelectMethod(sheetContext, type)));

  /// --- Widgets ---

  Widget get header => Column(children: [
        Text(widget.sectionModel.title, style: Style.body2w6(context)),
        const SizedBox(height: 2),
        Text(widget.sectionModel.sectionType.name.toUpperCase(),
            style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Text get sectionContent => Text(widget.sectionModel.content,
      textAlign: TextAlign.justify, style: Style.small3w4(context, color: TextColorRole.greyColor));

  Widget get inputField => InputField.textArea(
        controller: inputController,
        maxLines: 8,
        inputBorderRadius: Style.border24,
        hint: _inputPlaceholder,
      );

  Widget get inputView => BlocBuilder<LearnQuestionAnswerBloc, LearnQuestionAnswerState>(
      bloc: answerBloc,
      builder: (context, state) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            inputField,
            const Spacer(),
            Button.primary(onTap: submit, isLoading: state.status.isLoading, text: 'Submit')
          ]));

  Widget get lessonView => BlocBuilder<LearnSectionDetailBloc, LearnSectionDetailState>(
      bloc: detailBloc,
      builder: (context, state) {
        if (state.status.isSuccess && state.detail != null)
          return LearnWritingLesson(
              sectionDetailModel: state.detail!, onTapContinue: showMethodSheet);
        if (state.status.isLoading) return const PrimaryLoadingIndicator();

        return ReloadConntectionButton(onReloadConnection: getSectionDetails);
      });

  Widget get bodyChecker {
    if (stage == LearnWritingStage.lesson) return lessonView;
    if (stage == LearnWritingStage.input) return inputView;
    if (stage == LearnWritingStage.result)
      return BlocBuilder<LearnQuestionAnswerBloc, LearnQuestionAnswerState>(
          bloc: answerBloc, builder: (context, state) => const QuizResultComponent());

    return const SizedBox();
  }

  Widget get view => Column(children: [
        const SizedBox(height: 24),
        if (stage != LearnWritingStage.result) sectionContent,
        const SizedBox(height: 16),
        Expanded(child: bodyChecker)
      ]);

  @override
  Widget build(
          BuildContext context) =>
      BlocListener<LearnQuestionAnswerBloc, LearnQuestionAnswerState>(
          bloc: answerBloc,
          listener: learnQuestionAnswerListener,
          child: Scaffold(
              backgroundColor: context.cs.surface,
              body: PrimaryBackground(
                  header: header,
                  isHeader: stage != LearnWritingStage.result,
                  isScrollable: false,
                  child: view)));
}
