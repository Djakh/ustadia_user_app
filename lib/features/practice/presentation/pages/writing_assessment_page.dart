import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/inputs/input_field.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/cards/promt_card.dart';

class WritingAssessmentPage extends StatefulWidget {
  const WritingAssessmentPage({super.key});

  @override
  State<WritingAssessmentPage> createState() => _WritingAssessmentPageState();
}

class _WritingAssessmentPageState extends State<WritingAssessmentPage> {
  final prompts = const [
    'Describe your daily routine',
    'Write about a teacher who helped you',
    'Explain your favorite hobby'
  ];

  final controller = TextEditingController();
  String? selectedPrompt;

  /// --- Life cycle ---

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// --- Methods ---

  void selectPrompt(String prompt) => setState(() {
        selectedPrompt = prompt;
        controller.clear();
      });

  int get wordCount {
    final text = controller.text.trim();
    if (text.isEmpty) return 0;
    return text.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length;
  }

  void onSubmit() {}

  /// --- Widgets ---

  List<Widget> get promptsList => prompts
      .map((prompt) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: PromtCard(prompt: prompt, selectPrompt: selectPrompt)))
      .toList();

  Widget promptContent(BuildContext context) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Choose a prompt', style: Style.bodyw5(context)),
        const SizedBox(height: 12),
        ...promptsList
      ]);

  Widget get responseTextField => InputField.textArea(
        controller: controller,
        borderColor: AppColors.white,
        hint: 'Type your response here...',
        hintStyle: Style.bodyw4(context, color: TextColorRole.greyColor),
        maxLines: 6,
        onChanged: (_) => setState(() {}),
      );

  Widget responseArea(BuildContext context) => Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(selectedPrompt ?? '', style: Style.bodyw5(context)),
        const SizedBox(height: 12),
        responseTextField,
        const SizedBox(height: 8),
        Text('$wordCount words', style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const Spacer(),
        Button.primary(onTap: onSubmit, text: 'Submit')
      ]));

  Widget get view => PrimaryBackground(
      title: 'Writing assessment',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        if (selectedPrompt == null) promptContent(context) else responseArea(context),
      ]));

  @override
  Widget build(BuildContext context) => Scaffold(backgroundColor: context.cs.surface, body: view);
}
