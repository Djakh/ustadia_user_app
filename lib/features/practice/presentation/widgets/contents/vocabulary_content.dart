import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/practice/cubit/next_practice_bloc.dart';
import 'package:ustadia_user_app/features/practice/data/models/vocabulary_question.dart';
import 'package:ustadia_user_app/size_config.dart';

class VocabularyContent extends StatefulWidget {
  final VocabularyModel vocabularyModel;
  const VocabularyContent({super.key, required this.vocabularyModel});

  @override
  State<VocabularyContent> createState() => _VocabularyContentState();
}

class _VocabularyContentState extends State<VocabularyContent> {
  int? selectedIndex;
  late VocabularyModel vocabularyModel;

  /// --- Life cycle ---

  @override
  void initState() {
    vocabularyModel = widget.vocabularyModel;
    super.initState();
  }

  @override
  void didUpdateWidget(covariant VocabularyContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.vocabularyModel != widget.vocabularyModel) {
      selectedIndex = null;
      vocabularyModel = widget.vocabularyModel;
    }
  }

  /// --- Methods ---

  void onSelect(int index) {
    final bloc = context.read<NextPracticeBloc>();
    if (bloc.state.isCurrentTaskCompleted) return;
    selectedIndex = index;
    bloc.setCurrentTaskCompleted(true, isAnswerCorrect: index == vocabularyModel.answerIndex);
  }

  /// --- Widgets ---

  Column promptCardBody() => Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Text(vocabularyModel.category,
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 12),
        Text(vocabularyModel.prompt, style: Style.headline5w7(context))
      ]);

  Widget get promptCard => Container(
      height: SizeConfig.screenHeight / 2.2,
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border20),
      child: promptCardBody());

  Color optionColor(BuildContext context, int index) {
    if (selectedIndex == null) return context.cs.surface;
    if (index == vocabularyModel.answerIndex) return context.cs.primary;
    if (selectedIndex == index && index != vocabularyModel.answerIndex) {
      return context.cs.error;
    }
    return context.cs.surface;
  }

  Color optionTextColor(BuildContext context, int index) {
    final fill = optionColor(context, index);
    if (fill == context.cs.primary || fill == context.cs.error) return context.cs.onPrimary;
    return context.cs.onSurface;
  }

  List<Widget> get optionsList => List.generate(
      vocabularyModel.options.length,
      (index) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Button.primary(
                onTap: () => onSelect(index),
                color: optionColor(context, index),
                textColor: optionTextColor(context, index),
                text: vocabularyModel.options[index]),
          ));

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
      promptCard,
      const SizedBox(height: 16),
      Text('Answer as many as you can!',
          style: Style.small3w4(context, color: TextColorRole.greyColor)),
      const SizedBox(height: 16),
      ...optionsList
    ]);
  }
}
