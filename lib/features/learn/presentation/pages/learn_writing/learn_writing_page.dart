import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/inputs/input_field.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_writing_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/pages/learn_writing/learn_writing_lesson.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/bottom_sheets/learn_writing_bottom_sheet.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/components/learn_quiz_result_component.dart';

enum LearnWritingStage { lesson, input, result }

class LearnWritingPage extends StatefulWidget {
  final LearnSectionModel lesson;

  const LearnWritingPage({super.key, required this.lesson});

  @override
  State<LearnWritingPage> createState() => LearnWritingPageState();
}

class LearnWritingPageState extends State<LearnWritingPage> {
  LearnWritingStage stage = LearnWritingStage.lesson;
  LearnWritingLessonModel get lessonData => LearnWritingLessonModel.sample;
  LearnWritingMethodType? selectedMethod;
  final TextEditingController inputController = TextEditingController();
  int correctCount = 0;

  @override
  void dispose() {
    inputController.dispose();
    super.dispose();
  }

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
    correctCount = wordCount.length >= lessonData.minWords ? 1 : 0;
    setState(() => stage = LearnWritingStage.result);
  }

  /// --- Showed Widgets ---
  Future<void> showMethodSheet() => showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => LearnWritingBottomSheet(
          onTap: (LearnWritingMethodType type) => onSelectMethod(sheetContext, type)));

  /// --- Widgets ---

  Widget header(BuildContext context) => Column(children: [
        Text(lessonData.title, style: Style.body2w6(context)),
        const SizedBox(height: 2),
        Text(lessonData.subtitle, style: Style.small3w4(context, color: TextColorRole.greyColor))
      ]);

  Widget inputField(BuildContext context) => InputField.textArea(
        controller: inputController,
        maxLines: 8,
        inputBorderRadius: Style.border24,
        hint: 'Start writing here',
      );

  Text recommendedWordsAmount(BuildContext context) =>
      Text('Min ${lessonData.minWords} words recommended',
          style: Style.small3w4(context, color: TextColorRole.greyColor));

  Widget inputView(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        inputField(context),
        const SizedBox(height: 8),
        recommendedWordsAmount(context),
        const Spacer(),
        Button.primary(onTap: submit, text: 'Submit')
      ]);

  Widget body(BuildContext context) {
    if (stage == LearnWritingStage.lesson)
      return LearnWritingLesson(lessonDataModel: lessonData, onTapContinue: showMethodSheet);
    if (stage == LearnWritingStage.input) return inputView(context);
    return LearnQuizResultComponent(correctCount: correctCount, quizLength: 1);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          header: header(context),
          isHeader: stage != LearnWritingStage.result,
          isScrollable: false,
          child: body(context)));
}
