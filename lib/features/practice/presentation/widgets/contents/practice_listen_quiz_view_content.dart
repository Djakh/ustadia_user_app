import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/features/practice/data/models/listen_tap_question_model.dart';
import 'package:ustadia_user_app/core/cubit/next_task_bloc.dart';
import 'package:ustadia_user_app/size_config.dart';

class PracticeListenQuizViewContent extends StatefulWidget {
  final ListenTapQuestionModel question;
  final FlutterTts tts;
  const PracticeListenQuizViewContent({super.key, required this.question, required this.tts});

  @override
  State<PracticeListenQuizViewContent> createState() => PracticeListenQuizViewContentState();
}

class PracticeListenQuizViewContentState extends State<PracticeListenQuizViewContent> {
  int? selectedIndex;

  /// --- Life cycle ---

  @override
  void didUpdateWidget(covariant PracticeListenQuizViewContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.question != widget.question) {
      selectedIndex = null;
      context.read<NextTaskBloc>().setCurrentTaskCompleted(false, isAnswerCorrect: false);
    }
  }

  /// --- Methods ---

  Future<void> onPlay({double rate = 0.6}) async {
    await widget.tts.stop();
    await widget.tts.setLanguage('en-US');
    await widget.tts.setSpeechRate(rate);
    await widget.tts.setPitch(1.0);
    await widget.tts.setVolume(1.0);
    await widget.tts.awaitSpeakCompletion(true);
    await widget.tts.speak(widget.question.prompt);
  }

  void onSelect(int index) {
    final bloc = context.read<NextTaskBloc>();
    if (bloc.state.isCurrentTaskCompleted) return;
    setState(() => selectedIndex = index);
    bloc.setCurrentTaskCompleted(true, isAnswerCorrect: index == widget.question.answerIndex);
  }

  /// --- Widgets ---

  Widget get inkImage => Ink.image(
      image: const AssetImage(AppImages.listenButton), width: 120, height: 120, fit: BoxFit.cover);

  Widget get audioButton => Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onPlay,
          customBorder: const CircleBorder(),
          splashColor: Colors.white24,
          highlightColor: Colors.white10,
          child: inkImage));

  Widget get controlRow => Row(children: [
        Expanded(child: Button.border(onTap: () => onPlay(rate: 0.45), text: 'Slower')),
        const SizedBox(width: 8),
        Expanded(child: Button.border(onTap: () => onPlay(rate: 0.6), text: 'Again'))
      ]);

  Color optionColor(BuildContext context, int index) {
    if (selectedIndex == null) return context.cs.surface;
    if (index == widget.question.answerIndex) return context.cs.primary;
    if (selectedIndex == index && index != widget.question.answerIndex) return context.cs.error;
    return context.cs.surface;
  }

  Color optionTextColor(BuildContext context, int index) {
    final fill = optionColor(context, index);
    if (fill == context.cs.primary || fill == context.cs.error) return context.cs.onPrimary;
    return context.cs.onSurface;
  }

  List<Widget> get optionsList => List.generate(
      widget.question.options.length,
      (index) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Button.primary(
              onTap: () => onSelect(index),
              color: optionColor(context, index),
              text: widget.question.options[index],
              textColor: optionTextColor(context, index))));

  Widget get view => Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(height: SizeConfig.screenHeight / 14),
        audioButton,
        const SizedBox(height: 16),
        Text('Listen and tap what your hear',
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 24),
        controlRow,
        SizedBox(height: SizeConfig.screenHeight / 15),
        ...optionsList
      ]);

  @override
  Widget build(BuildContext context) => view;
}
