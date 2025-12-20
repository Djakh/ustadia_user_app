import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';

class BuildSentencePage extends StatefulWidget {
  const BuildSentencePage({super.key});

  @override
  State<BuildSentencePage> createState() => _BuildSentencePageState();
}

class _BuildSentencePageState extends State<BuildSentencePage> {
  final List<String> correctOrder = const ['I', 'go', 'to', 'school', 'every', 'day'];
  late List<String> pool;
  final List<String> selected = [];
  bool showError = false;
  bool showSuccess = false;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    pool = List<String>.from(correctOrder)..shuffle();
  }

  /// --- Methods ---

  void onSelect(String word) {
    setState(() {
      pool.remove(word);
      selected.add(word);
      showError = false;
    });
  }

  void onRemove(String word) {
    setState(() {
      selected.remove(word);
      pool.add(word);
    });
  }

  void onCheck() {
    final isCorrect =
        selected.length == correctOrder.length && selected.join(' ') == correctOrder.join(' ');
    setState(() {
      showError = !isCorrect;
      showSuccess = isCorrect;
    });
  }

  /// --- Widgets ---

  Widget chip(BuildContext context, String word, bool selectedChip) => GestureDetector(
      onTap: () => selectedChip ? onRemove(word) : onSelect(word),
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: selectedChip ? AppColors.greenE7 : context.cs.surface,
              borderRadius: Style.border20,
              border: Border.all(
                  color: selectedChip ? AppColors.greenA8 : AppColors.transparent,
                  width: selectedChip ? 1 : 0)),
          child: Text(word, style: Style.body2w5(context))));

  Container dropZone(BuildContext context) => Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.white, borderRadius: Style.border20),
      child: selected.isEmpty
          ? Center(
              child: Text('Tap a word to build the sentence.',
                  style: Style.small3w4(context, color: TextColorRole.greyColor)))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selected.map((w) => chip(context, w, true)).toList()));

  Widget dropZoneDottedBorder(BuildContext context) => DottedBorder(
      options: const RoundedRectDottedBorderOptions(
          radius: Radius.circular(20),
          dashPattern: [3, 4], // dash, gap
          strokeWidth: 1.2,
          padding: EdgeInsets.zero),
      child: dropZone(context));

  Widget poolWrap(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: pool.map((w) => chip(context, w, false)).toList()
          ..sort((a, b) => a.toString().compareTo(b.toString())),
      );

  Widget get instruction => Text(
        'Tap a word to build the sentence.',
        style: Style.small3w4(context, color: TextColorRole.greyColor),
      );

  Widget get errorText => Center(
        child: Text(
          'Not quite. Try a different order.',
          style: Style.body2w4(context).copyWith(color: context.cs.error),
        ),
      );

  Widget get successText => Center(
        child: Text(
          'Great! Your sentence looks correct.',
          style: Style.body2w4(context).copyWith(color: context.cs.primary),
        ),
      );

  Widget get view => PrimaryBackground(
      title: 'Build the sentence',
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        dropZoneDottedBorder(context),
        const SizedBox(height: 24),
        poolWrap(context),
        const SizedBox(height: 12),
        if (showError) errorText,
        if (showSuccess) successText,
        const Spacer(),
        Button.primary(onTap: onCheck, text: 'Check answer'),
      ]));

  @override
  Widget build(BuildContext context) =>
      Scaffold(backgroundColor: context.cs.surface, body: SafeArea(child: view));
}
