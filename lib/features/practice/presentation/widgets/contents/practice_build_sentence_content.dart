import 'package:dotted_border/dotted_border.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/cubit/next_task_bloc.dart';

class PracticeBuildSentenceContent extends StatefulWidget {
  final List<String> correctOrder;
  const PracticeBuildSentenceContent({super.key, required this.correctOrder});

  @override
  State<PracticeBuildSentenceContent> createState() => PracticeBuildSentenceContentState();
}

class PracticeBuildSentenceContentState extends State<PracticeBuildSentenceContent> {
  late List<String> pool;
  final List<String> selected = [];
  bool showError = false;
  bool showSuccess = false;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    pool = List<String>.from(widget.correctOrder)..shuffle();
    context.read<NextTaskBloc>().setCurrentTaskCompleted(false, isAnswerCorrect: false);
  }

  /// --- Methods ---

  void onSelect(String word) {
    setState(() {
      pool.remove(word);
      selected.add(word);
      showError = false;
      showSuccess = false;
    });
    if (selected.length == widget.correctOrder.length) _checkAnswer();
  }

  void onRemove(String word) {
    setState(() {
      selected.remove(word);
      pool.add(word);
      showError = false;
      showSuccess = false;
    });
    context.read<NextTaskBloc>().setCurrentTaskCompleted(false, isAnswerCorrect: false);
  }

  void _checkAnswer() {
    final isCorrect = selected.length == widget.correctOrder.length &&
        selected.join(' ') == widget.correctOrder.join(' ');
    setState(() {
      showError = !isCorrect;
      showSuccess = isCorrect;
    });
    context.read<NextTaskBloc>().setCurrentTaskCompleted(true, isAnswerCorrect: isCorrect);
  }

  /// --- Widgets ---

  Widget chip(BuildContext context, String word, bool selectedChip) => GestureDetector(
      onTap: () => selectedChip ? onRemove(word) : onSelect(word),
      child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: selectedChip
                  ? (showError ? AppColors.redE2 : AppColors.greenE7)
                  : context.cs.surface,
              borderRadius: Style.border20,
              border: Border.all(
                  color: selectedChip
                      ? (showError ? AppColors.redA9 : AppColors.greenA8)
                      : AppColors.transparent,
                  width: selectedChip ? 1 : 0)),
          child: Text(word, style: Style.body2w5(context))));

  Container dropZone(BuildContext context) => Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 128),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: showError ? AppColors.redE2 : AppColors.white, borderRadius: Style.border20),
      child: selected.isEmpty
          ? Center(
              child: Text('Tap a word to build the sentence.',
                  style: Style.small3w4(context, color: TextColorRole.greyColor)))
          : Wrap(
              spacing: 8,
              runSpacing: 8,
              children: selected.map((w) => chip(context, w, true)).toList()));

  Widget dropZoneDottedBorder(BuildContext context) => DottedBorder(
      options: RoundedRectDottedBorderOptions(
          radius: const Radius.circular(20),
          dashPattern: const [3, 4],
          strokeWidth: 1.2,
          padding: EdgeInsets.zero,
          color: showError ? AppColors.redA9 : context.cs.onTertiary),
      child: dropZone(context));

  Widget poolWrap(BuildContext context) => Wrap(
        spacing: 8,
        runSpacing: 8,
        children: pool.map((w) => chip(context, w, false)).toList()
          ..sort((a, b) => a.toString().compareTo(b.toString())),
      );

  Widget get errorText => Center(
      child: Text('Not quite. Try a different order.',
          style: Style.body2w4(context).copyWith(color: context.cs.error)));

  Widget get successText => Center(
      child: Text('Great! Your sentence looks correct.',
          style: Style.body2w4(context).copyWith(color: context.cs.primary)));

  @override
  Widget build(BuildContext context) => Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            dropZoneDottedBorder(context),
            const SizedBox(height: 24),
            poolWrap(context),
            const SizedBox(height: 12),
            if (showError) errorText,
            if (showSuccess) successText,
          ]);
}
