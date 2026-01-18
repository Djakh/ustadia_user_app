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
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_writing_method.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_section_detail_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_writing_section/learn_writing_section_lesson.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/bottom_sheets/learn_writing_bottom_sheet.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_result_component.dart';
import 'package:ustadia_user_app/injection_container.dart';

enum LearnWritingStage { lesson, input, result }

class LearnWritingPage extends StatefulWidget {
  final LearnSectionModel lesson;

  const LearnWritingPage({super.key, required this.lesson});

  @override
  State<LearnWritingPage> createState() => LearnWritingPageState();
}

class LearnWritingPageState extends State<LearnWritingPage> {
  final LearnSectionDetailBloc detailBloc = sl<LearnSectionDetailBloc>();
  LearnWritingStage stage = LearnWritingStage.lesson;
  LearnWritingMethodType? selectedMethod;
  final TextEditingController inputController = TextEditingController();
  int correctCount = 0;
  static const int _defaultMinWords = 20;
  static const String _inputPlaceholder = 'Start writing here';

  @override
  void dispose() {
    inputController.dispose();
    detailBloc.close();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.lesson.id.isNotEmpty) {
      getSectionDetails();
    }
  }

  /// --- Methods ---

  void getSectionDetails() =>
      detailBloc.add(LearnSectionDetailRequested(sectionId: widget.lesson.id));

  Future<void> pickUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(withData: true);
      if (result == null) return;
      correctCount = 1;
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
    final wordCount = inputController.text.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty);
    correctCount = wordCount.length >= _defaultMinWords ? 1 : 0;
    setState(() => stage = LearnWritingStage.result);
  }

  /// --- Showed Widgets ---
  Future<void> showMethodSheet() => showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => LearnWritingBottomSheet(
          onTap: (LearnWritingMethodType type) => onSelectMethod(sheetContext, type)));

  /// --- Widgets ---

  Widget get header => Column(children: [
        Text(widget.lesson.title, style: Style.body2w6(context)),
      ]);

  Widget get inputField => InputField.textArea(
        controller: inputController,
        maxLines: 8,
        inputBorderRadius: Style.border24,
        hint: _inputPlaceholder,
      );

  Text get recommendedWordsAmount => Text('Min $_defaultMinWords words recommended',
      style: Style.small3w4(context, color: TextColorRole.greyColor));

  Widget get inputView => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        inputField,
        const SizedBox(height: 8),
        recommendedWordsAmount,
        const Spacer(),
        Button.primary(onTap: submit, text: 'Submit')
      ]);

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
      return LearnQuizResultComponent(correctCount: correctCount, quizLength: 1);

    return const SizedBox();
  }

  Widget get view => Column(children: [
        const SizedBox(height: 24),
        Text(widget.lesson.subtitle,
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 16),
        Expanded(child: bodyChecker)
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: widget.lesson.title,
          isHeader: stage != LearnWritingStage.result,
          isScrollable: false,
          child: view));
}
