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
import 'package:ustadia_user_app/core/widgets/text/html_text.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_detail_bloc/section_detail_state.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_state.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/sections_types/writing_section/writing_section_lesson.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_writing_method.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/bottom_sheets/learn_writing_bottom_sheet.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum WritingSectionStage { lesson, input, result }

class WritingSectionPage extends StatefulWidget {
  final SectionModel sectionModel;

  const WritingSectionPage({super.key, required this.sectionModel});

  @override
  State<WritingSectionPage> createState() => WritingSectionPageState();
}

class WritingSectionPageState extends State<WritingSectionPage> {
  final SectionDetailBloc detailBloc = sl<SectionDetailBloc>();
  final QuestionAnswerBloc answerBloc = sl<QuestionAnswerBloc>();
  WritingSectionStage stage = WritingSectionStage.lesson;
  LearnWritingMethodType? selectedMethod;
  final TextEditingController inputController = TextEditingController();
  static const String inputPlaceholder = 'Start writing here';

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

  void questionAnswerListener(context, state) {
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
    if (state.status.isSuccess) {
      setState(() => stage = WritingSectionStage.result);
    }
  }

  /// --- Methods ---

  void getSectionDetails() => detailBloc.add(SectionDetailRequested(
      sectionId: widget.sectionModel.id,
      source: widget.sectionModel.source,
      unitId: widget.sectionModel.unitId,
      lessonId: widget.sectionModel.lessonId,
      assignmentId: widget.sectionModel.assignmentId));

  Future<void> pickUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null) return;
      if (!mounted) return;
      setState(() => stage = WritingSectionStage.result);
    } on MissingPluginException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('File picker is not available on this device. Try a real device.'.tr())));
    }
  }

  void selectMethod(LearnWritingMethodType type) => setState(() {
        selectedMethod = type;
        stage = type == LearnWritingMethodType.inApp
            ? WritingSectionStage.input
            : WritingSectionStage.result;
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
          .showSnackBar(SnackBar(content: Text('Question is not available yet.'.tr())));
      return;
    }
    answerBloc.add(QuestionAnswerSubmitted(
        sectionId: widget.sectionModel.id,
        questionId: question.id,
        assignmentId: question.assignmentId,
        unitId: question.unitId,
        lessonId: question.lessonId,
        userInputText: inputController.text.trim(),
        source: question.source));
  }

  /// --- Showed Widgets ---
  Future<void> showMethodSheet() => showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => LearnWritingBottomSheet(
          onTap: (LearnWritingMethodType type) => onSelectMethod(sheetContext, type)));

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

  Widget get sectionContent => HtmlText(
      data: widget.sectionModel.content,
      textAlign: TextAlign.justify,
      textStyle: Style.small3w4(context, color: TextColorRole.greyColor));

  Widget get sectionContentView => SingleChildScrollView(child: sectionContent);

  Widget get inputField => InputField.textArea(
        controller: inputController,
        maxLines: 8,
        inputBorderRadius: Style.border24,
        hint: inputPlaceholder,
      );

  Widget get inputView => BlocBuilder<QuestionAnswerBloc, QuestionAnswerState>(
      bloc: answerBloc,
      builder: (context, state) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            inputField,
            const Spacer(),
            Button.primary(onTap: submit, isLoading: state.status.isLoading, text: 'Submit'.tr())
          ]));

  Widget get lessonView => BlocBuilder<SectionDetailBloc, SectionDetailState>(
      bloc: detailBloc,
      builder: (context, state) {
        if (state.status.isSuccess && state.detail != null)
          return WritingSectionLesson(
              sectionDetailModel: state.detail!, onTapContinue: showMethodSheet);
        if (state.status.isLoading) return const PrimaryLoadingIndicator();

        return ReloadConntectionButton(onReloadConnection: getSectionDetails);
      });

  Widget get bodyChecker {
    if (stage == WritingSectionStage.lesson) return lessonView;
    if (stage == WritingSectionStage.input) return inputView;
    if (stage == WritingSectionStage.result)
      return BlocBuilder<QuestionAnswerBloc, QuestionAnswerState>(
          bloc: answerBloc, builder: (context, state) => const QuizResultComponent());

    return const SizedBox();
  }

  Widget get view => Column(children: [
        const SizedBox(height: 24),
        if (stage != WritingSectionStage.result) ...[
          Flexible(child: sectionContentView),
          const SizedBox(height: 16),
        ],
        Expanded(child: bodyChecker)
      ]);

  @override
  Widget build(BuildContext context) => BlocListener<QuestionAnswerBloc, QuestionAnswerState>(
      bloc: answerBloc,
      listener: questionAnswerListener,
      child: Scaffold(
          backgroundColor: context.cs.surface,
          body: PrimaryBackground(
              header: header,
              headerTooltipText: widget.sectionModel.title,
              isHeader: stage != WritingSectionStage.result,
              isScrollable: false,
              child: view)));
}
