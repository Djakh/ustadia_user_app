import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/listen_tap_page.dart';
import 'package:ustadia_user_app/size_config.dart';

class ListenQuizView extends StatefulWidget {
  final FlutterTts tts;
  final ListenTapMode mode;
  final Function(ListenTapMode value) selectMode;
  const ListenQuizView(
      {super.key, required this.selectMode, required this.tts, required this.mode});

  @override
  State<ListenQuizView> createState() => _ListenQuizViewState();
}

class _ListenQuizViewState extends State<ListenQuizView> {
  int totalListenings = 3;
  int listeningIndex = 0;
  int? selectedIndex;
  bool answered = false;

  /// --- Getters ---

  List<ListenTapQuestion> get wordQuestions => const [
        ListenTapQuestion(
            prompt: 'skewer',
            options: ['Fountain', 'Mountain', 'Skewer', 'Casino', 'Capable'],
            answerIndex: 0),
        ListenTapQuestion(
            prompt: 'deliver',
            options: ['Defiance', 'Delicious', 'Deliver', 'Decide', 'Decision'],
            answerIndex: 1),
        ListenTapQuestion(
            prompt: 'liberty',
            options: ['Liberty', 'Library', 'Lightly', 'Likely'],
            answerIndex: 2),
      ];

  List<ListenTapQuestion> get sentenceQuestions => const [
        ListenTapQuestion(
            prompt: 'Where is the station?',
            options: [
              'Where is the station?',
              'Where is the vacation?',
              'Where is the bus station?'
            ],
            answerIndex: 0),
        ListenTapQuestion(
            prompt: 'I like coffee',
            options: ['I like coffee', "I'd like coffee", 'See you tomorrow'],
            answerIndex: 1),
        ListenTapQuestion(
            prompt: 'See you tomorrow',
            options: ['See you tomorrow', 'See you borrow', 'See you next summer'],
            answerIndex: 2),
      ];

  List<ListenTapQuestion> get questions =>
      widget.mode == ListenTapMode.sentences ? sentenceQuestions : wordQuestions;

  ListenTapQuestion get current => questions[listeningIndex];

  double get progress => (listeningIndex + 1) / questions.length;

  bool get isCorrect => selectedIndex != null && selectedIndex == current.answerIndex;

  String getNumberInWords(int number) {
    switch (number) {
      case 0:
        return 'First';
      case 1:
        return 'Second';
      case 2:
        return 'Third';

      default:
        return '';
    }
  }

  String get wordOrSentence => widget.mode == ListenTapMode.words ? "word" : "sentence";

  /// --- Methods ---

  Future<void> onPlay({double rate = 0.95}) async {
    try {
      await widget.tts.stop();
      await widget.tts.setLanguage('en-US');
      await widget.tts.setSpeechRate(rate);
      await widget.tts.speak(current.prompt);
    } catch (e) {
      print("My exception is $e");
      // Ignore missing plugin edge cases (e.g., when TTS channel is not available)
    }
  }

  void onSelectOption(int index) {
    if (answered) return;
    setState(() {
      selectedIndex = index;
      answered = true;
    });
  }

  void onNext() {
    if (listeningIndex == questions.length - 1) {
      setState(() {
        listeningIndex = 0;
        selectedIndex = null;
        answered = false;
      });
      return;
    }
    setState(() {
      listeningIndex++;
      selectedIndex = null;
      answered = false;
    });
  }

  /// --- Widgets ---

  Widget get indicator => PageIndicator(
      currentIndex: listeningIndex,
      total: 3,
      activeColor: context.cs.primary,
      inactiveColor: context.cs.onTertiary.withAlpha(89),
      isExpanded: true);

  Widget get currentListening => Text(
        "${getNumberInWords(listeningIndex)} $wordOrSentence",
        style: Style.small2w4(context, color: TextColorRole.greyColor),
      );

  Widget get totalListeningWidget => Text(
        "Total: $totalListenings ${wordOrSentence}s",
        style: Style.small2w4(context),
      );

  Widget get listeningInfo => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [currentListening, totalListeningWidget],
      );

  Widget get inkImage => Ink.image(
      image: const AssetImage(AppImages.listenButton), width: 120, height: 120, fit: BoxFit.cover);

  Widget get audioButton => Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onPlay,
          customBorder: const CircleBorder(),
          splashColor: Colors.white24, // чтобы точно было видно
          highlightColor: Colors.white10, // опционально
          child: inkImage));

  Widget get controlRow => Row(children: [
        Expanded(child: Button.border(onTap: () => onPlay(rate: 0.75), text: 'Slower')),
        const SizedBox(width: 8),
        Expanded(child: Button.border(onTap: () => onPlay(rate: 0.95), text: 'Again'))
      ]);

  Color optionColor(int index) {
    if (!answered) return context.cs.surface;
    if (index == current.answerIndex) return context.cs.primary;
    if (selectedIndex == index && !isCorrect) return context.cs.error;
    return context.cs.surface;
  }

  Color optionTextColor(int index) {
    final fill = optionColor(index);
    if (fill == context.cs.primary || fill == context.cs.error) return context.cs.onPrimary;
    return context.cs.onSurface;
  }

  Widget optionButton(int index) => Button.primary(
      onTap: () => onSelectOption(index),
      color: optionColor(index),
      text: current.options[index],
      textColor: optionTextColor(index));

  List<Widget> get optionsList => List.generate(
      current.options.length,
      (index) =>
          Padding(padding: const EdgeInsets.symmetric(vertical: 5), child: optionButton(index)));

  Widget get nextButton =>
      answered ? Button.primary(onTap: onNext, text: 'Next') : const SizedBox(height: 52);

  Widget get quizView => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          indicator,
          const SizedBox(height: 4),
          listeningInfo,
          SizedBox(height: SizeConfig.screenHeight / 14),
          audioButton,
          const SizedBox(height: 16),
          Text('Listen and tap what your hear',
              style: Style.small3w4(context, color: TextColorRole.greyColor)),
          const SizedBox(height: 24),
          controlRow,
          SizedBox(height: SizeConfig.screenHeight / 15),
          ...optionsList,
          const SizedBox(height: 10),
          nextButton,
        ],
      );

  @override
  Widget build(BuildContext context) => quizView;
}
