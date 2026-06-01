import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
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
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/file_upload_bloc/file_upload_state.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_state.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/components/section_timer_badge.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/sections_types/writing_section/writing_section_lesson.dart';
import 'package:ustadia_user_app/features/common/presentation/widgets/result_components/quiz_result_component.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_writing_method.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/bottom_sheets/learn_writing_bottom_sheet.dart';
import 'package:ustadia_user_app/features/mock_exam/data/datasources/mock_exam_remote_data_source.dart';
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
  final FileUploadBloc uploadBloc = sl<FileUploadBloc>();
  WritingSectionStage stage = WritingSectionStage.lesson;
  LearnWritingMethodType? selectedMethod;
  final TextEditingController inputController = TextEditingController();
  static const String inputPlaceholder = 'Start writing here';

  @override
  void dispose() {
    inputController.dispose();
    detailBloc.close();
    answerBloc.close();
    uploadBloc.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    inputController.addListener(updateSubmitAvailability);
    if (widget.sectionModel.progressState == SectionProgressState.completed) {
      stage = WritingSectionStage.result;
    }
    if (widget.sectionModel.id.isNotEmpty) {
      getSectionDetails();
    }
  }

  /// --- Listeners ---

  void questionAnswerListener(context, state) async {
    if (state.status.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
    if (state.status.isSuccess) {
      await finishMockExamSectionIfNeeded();
      if (widget.sectionModel.source == SectionSource.mockExam && mounted) {
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => stage = WritingSectionStage.result);
    }
  }

  Future<void> finishMockExamSectionIfNeeded() async {
    if (widget.sectionModel.source != SectionSource.mockExam) return;
    final mockExamId = widget.sectionModel.mockId;
    final attemptId = widget.sectionModel.mockAttemptId;
    if (mockExamId == null || mockExamId.isEmpty || attemptId == null || attemptId.isEmpty) return;
    try {
      await sl<MockExamRemoteDataSource>().finishMockExamSection(
          mockExamId: mockExamId, attemptId: attemptId, sectionId: widget.sectionModel.id);
    } catch (_) {}
  }

  void closeMockExamSectionOnTimerExpired() {
    if (widget.sectionModel.source != SectionSource.mockExam || !mounted) return;
    Navigator.of(context).pop(true);
  }

  void fileUploadListener(context, FileUploadState state) {
    if (state.status.isError && state.errorMessage != null) {
      final message = state.errorMessage == 'Selected file is not available.'
          ? 'Selected file is not available.'.tr()
          : state.errorMessage!;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    if (mounted) setState(() {});
  }

  /// --- Methods ---

  void getSectionDetails() => detailBloc.add(SectionDetailRequested(
      sectionId: widget.sectionModel.id,
      source: widget.sectionModel.source,
      unitId: widget.sectionModel.unitId,
      lessonId: widget.sectionModel.lessonId,
      assignmentId: widget.sectionModel.assignmentId,
      mockExamId: widget.sectionModel.mockId,
      mockAttemptId: widget.sectionModel.mockAttemptId));

  Future<void> pickUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null) return;
      if (!mounted) return;
      final file = result.files.single;
      setState(() {
        selectedMethod = LearnWritingMethodType.upload;
        stage = WritingSectionStage.input;
      });
      uploadBloc.add(
        ImageUploadRequested(filePath: file.path, fileName: file.name, bytes: file.bytes),
      );
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

  void updateSubmitAvailability() {
    if (selectedMethod == LearnWritingMethodType.inApp && mounted) setState(() {});
  }

  bool canSubmit(QuestionAnswerState answerState, FileUploadState uploadState) {
    if (answerState.status.isLoading) return false;
    if (selectedMethod == LearnWritingMethodType.inApp) {
      return inputController.text.trim().isNotEmpty;
    }
    if (selectedMethod == LearnWritingMethodType.upload) {
      return uploadState.status.isSuccess && uploadState.uploadedFile?.id.isNotEmpty == true;
    }
    return false;
  }

  void submit() {
    final detail = detailBloc.state.detail;
    final question = detail != null && detail.questions.isNotEmpty ? detail.questions.first : null;
    if (question == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Question is not available yet.'.tr())));
      return;
    }
    final uploadedFile = uploadBloc.state.uploadedFile;
    if (selectedMethod == LearnWritingMethodType.inApp && inputController.text.trim().isEmpty) {
      return;
    }
    if (selectedMethod == LearnWritingMethodType.upload &&
        (uploadedFile == null || uploadedFile.id.isEmpty)) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Please upload a file first.'.tr())));
      return;
    }
    answerBloc.add(QuestionAnswerSubmitted(
        sectionId: widget.sectionModel.id,
        questionId: question.id,
        assignmentId: question.assignmentId,
        mockExamId: question.mockExamId,
        mockAttemptId: question.mockAttemptId,
        unitId: question.unitId,
        lessonId: question.lessonId,
        userInputText:
            selectedMethod == LearnWritingMethodType.inApp ? inputController.text.trim() : null,
        userFileId: selectedMethod == LearnWritingMethodType.upload ? uploadedFile?.id : null,
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
        Text(widget.sectionModel.sectionTypeLabel.toUpperCase(),
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
        hint: inputPlaceholder.tr(),
      );

  Widget get inputView => BlocBuilder<QuestionAnswerBloc, QuestionAnswerState>(
      bloc: answerBloc,
      builder: (context, answerState) => BlocBuilder<FileUploadBloc, FileUploadState>(
          bloc: uploadBloc,
          builder: (context, uploadState) {
            final isUpload = selectedMethod == LearnWritingMethodType.upload;
            return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              if (isUpload) uploadView(uploadState) else inputField,
              const Spacer(),
              Button.primary(
                  onTap: submit,
                  isLoading: answerState.status.isLoading,
                  isAvialable: canSubmit(answerState, uploadState),
                  text: 'Submit'.tr())
            ]);
          }));

  Widget uploadView(FileUploadState state) {
    final uploadedFile = state.uploadedFile;
    final title = state.status.isLoading
        ? 'Uploading file...'.tr()
        : uploadedFile != null
            ? 'File uploaded'.tr()
            : 'No file uploaded'.tr();
    final subtitle = state.status.isLoading
        ? 'Please wait until the upload finishes.'.tr()
        : uploadedFile?.filename ?? 'Choose an image or document to submit.'.tr();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border24),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Style.body2w6(context)),
            const SizedBox(height: 8),
            Text(subtitle, style: Style.bodyw4(context, color: TextColorRole.greyColor)),
            const SizedBox(height: 16),
            Button.border(
                onTap: pickUploadFile,
                isLoading: state.status.isLoading,
                text: uploadedFile == null ? 'Choose file'.tr() : 'Choose another file'.tr(),
                borderColor: context.cs.primary,
                textColor: context.cs.primary)
          ]),
    );
  }

  Widget get lessonView => BlocBuilder<SectionDetailBloc, SectionDetailState>(
      bloc: detailBloc,
      builder: (context, state) {
        if (state.detail?.progressState == SectionProgressState.completed) {
          return QuizResultComponent(sectionModel: widget.sectionModel);
        }
        if (state.status.isSuccess && state.detail != null)
          return WritingSectionLesson(
              sectionDetailModel: state.detail!, onTapContinue: showMethodSheet);
        if (state.status.isLoading) return const PrimaryLoadingIndicator();

        return ReloadConntectionButton(onReloadConnection: getSectionDetails);
      });

  Widget bodyChecker(SectionDetailState detailState) {
    if (stage == WritingSectionStage.lesson) return lessonView;
    if (stage == WritingSectionStage.input) return inputView;
    if (stage == WritingSectionStage.result)
      return BlocBuilder<QuestionAnswerBloc, QuestionAnswerState>(
          bloc: answerBloc,
          builder: (context, state) => QuizResultComponent(
              sectionModel: widget.sectionModel,
              aiFeedback: state.result?.aiFeedback,
              feedback: state.result?.error));

    return const SizedBox();
  }

  Widget timerBadge(SectionDetailState state) {
    final detail = state.detail;
    if (detail?.timeRemainingSeconds == null) {
      return const SizedBox.shrink();
    }
    return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: SectionTimerBadge(
            timeRemainingSeconds: detail?.timeRemainingSeconds,
            onExpired: closeMockExamSectionOnTimerExpired));
  }

  Widget view(SectionDetailState detailState) => Column(children: [
        const SizedBox(height: 24),
        timerBadge(detailState),
        if (stage != WritingSectionStage.result) ...[
          Flexible(child: sectionContentView),
          const SizedBox(height: 16),
        ],
        Expanded(child: bodyChecker(detailState))
      ]);

  @override
  Widget build(BuildContext context) => GuidedTutorialPage(
      pageId: '${TutorialPageIds.section}.writing',
      steps: TutorialPresets.section(sectionType: 'writing'),
      child: MultiBlocListener(
          listeners: [
            BlocListener<QuestionAnswerBloc, QuestionAnswerState>(
                bloc: answerBloc, listener: questionAnswerListener),
            BlocListener<FileUploadBloc, FileUploadState>(
                bloc: uploadBloc, listener: fileUploadListener),
          ],
          child: Scaffold(
              backgroundColor: context.cs.surface,
              body: PrimaryBackground(
                  header: header,
                  headerTooltipText: widget.sectionModel.title,
                  isHeader: stage != WritingSectionStage.result,
                  isScrollable: false,
                  child: BlocBuilder<SectionDetailBloc, SectionDetailState>(
                      bloc: detailBloc, builder: (context, state) => view(state))))));
}
