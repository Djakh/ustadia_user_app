import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/indicators/page_indicator.dart';
import 'package:ustadia_user_app/features/practice/cubit/next_practice_bloc.dart';
import 'package:ustadia_user_app/features/practice/data/models/listen_tap_question_model.dart';
import 'package:ustadia_user_app/features/practice/presentation/pages/listen_tap_pages/listen_tap_page.dart';
import 'package:ustadia_user_app/features/practice/presentation/widgets/contents/listen_quiz_view_content.dart';

class ListenQuizView extends StatefulWidget {
  final ListenTapMode mode;

  const ListenQuizView({super.key, required this.mode});

  @override
  State<ListenQuizView> createState() => _ListenQuizViewState();
}

class _ListenQuizViewState extends State<ListenQuizView> {
  final FlutterTts _tts = FlutterTts();

  int listeningIndex = 0;

  /// --- Getters ---

  List<ListenTapQuestionModel> get wordQuestions => const [
        ListenTapQuestionModel(
            prompt: 'skewer',
            options: ['Fountain', 'Mountain', 'Skewer', 'Casino', 'Capable'],
            answerIndex: 0),
        ListenTapQuestionModel(
            prompt: 'deliver',
            options: ['Defiance', 'Delicious', 'Deliver', 'Decide', 'Decision'],
            answerIndex: 1),
        ListenTapQuestionModel(
            prompt: 'liberty',
            options: ['Liberty', 'Library', 'Lightly', 'Likely'],
            answerIndex: 2),
      ];

  List<ListenTapQuestionModel> get sentenceQuestions => const [
        ListenTapQuestionModel(
            prompt: 'Where is the station?',
            options: [
              'Where is the station?',
              'Where is the vacation?',
              'Where is the bus station?'
            ],
            answerIndex: 0),
        ListenTapQuestionModel(
            prompt: 'I like coffee',
            options: ['I like coffee', "I'd like coffee", 'See you tomorrow'],
            answerIndex: 1),
        ListenTapQuestionModel(
            prompt: 'See you tomorrow',
            options: ['See you tomorrow', 'See you borrow', 'See you next summer'],
            answerIndex: 2),
      ];

  List<ListenTapQuestionModel> get questions =>
      widget.mode == ListenTapMode.sentences ? sentenceQuestions : wordQuestions;

  ListenTapQuestionModel get current => questions[listeningIndex];

  double get progress => (listeningIndex + 1) / questions.length;

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

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    context.read<NextPracticeBloc>().setCurrentTaskCompleted(false, isAnswerCorrect: false);
  }

  @override
  void dispose() {
    _safeStopTts();

    super.dispose();
  }

  Future<void> _safeStopTts() async {
    try {
      await _tts.stop();
    } catch (_) {
      // Ignore missing plugin when widget is disposed during hot-reload/navigation.
    }
  }

  /// --- Methods ---

  void onNext() {
    if (listeningIndex == questions.length - 1) {
      setState(() {
        listeningIndex = 0;
      });
      context.read<NextPracticeBloc>().setCurrentTaskCompleted(false, isAnswerCorrect: false);
      return;
    }
    setState(() {
      listeningIndex++;
    });
    context.read<NextPracticeBloc>().setCurrentTaskCompleted(false, isAnswerCorrect: false);
  }

  /// --- Widgets ---

  Widget get indicator => PageIndicator(
      currentIndex: listeningIndex,
      total: questions.length,
      activeColor: context.cs.primary,
      inactiveColor: context.cs.onTertiary.withAlpha(89),
      isExpanded: true);

  Widget get currentListening => Text(
        "${getNumberInWords(listeningIndex)} $wordOrSentence",
        style: Style.small2w4(context, color: TextColorRole.greyColor),
      );

  Widget get totalListeningWidget => Text(
        "Total: ${questions.length} ${wordOrSentence}s",
        style: Style.small2w4(context),
      );

  Widget get listeningInfo => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [currentListening, totalListeningWidget],
      );

  Widget nextButton(bool isEnabled) =>
      Button.primary(onTap: onNext, text: 'Next', isAvialable: isEnabled);

  Widget get quizView => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 24),
          indicator,
          const SizedBox(height: 4),
          listeningInfo,
          ListenQuizViewContent(question: current, tts: _tts),
          const SizedBox(height: 10),
          BlocBuilder<NextPracticeBloc, NextPracticeState>(
              builder: (context, state) => nextButton(state.isCurrentTaskCompleted)),
        ],
      );

  @override
  Widget build(BuildContext context) => quizView;
}
