import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_models.dart';
import 'package:ustadia_user_app/features/assignments/presentation/pages/assignment_details_phase.dart';
import 'package:ustadia_user_app/features/assignments/presentation/widgets/assignment_audio_card.dart';
import 'package:ustadia_user_app/features/assignments/presentation/widgets/assignment_content_view.dart';
import 'package:ustadia_user_app/features/assignments/presentation/widgets/assignment_details_header.dart';
import 'package:ustadia_user_app/features/assignments/presentation/widgets/assignment_prompt_card.dart';
import 'package:ustadia_user_app/features/assignments/presentation/widgets/assignment_quiz_view.dart';
import 'package:ustadia_user_app/features/assignments/presentation/widgets/assignment_result_card.dart';
import 'package:ustadia_user_app/features/assignments/presentation/widgets/assignment_writing_view.dart';

class AssignmentDetailsPage extends StatefulWidget {
  final AssignmentDetailsParams params;

  const AssignmentDetailsPage({super.key, required this.params});

  @override
  State<AssignmentDetailsPage> createState() => AssignmentDetailsPageState();
}

class AssignmentDetailsPageState extends State<AssignmentDetailsPage> {
  late AssignmentDetailsPhase phase;
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    phase = initialPhase(widget.params.type);
  }

  AssignmentDetailsPhase initialPhase(AssignmentDetailType type) {
    switch (type) {
      case AssignmentDetailType.listening:
      case AssignmentDetailType.speaking:
        return AssignmentDetailsPhase.quiz;
      case AssignmentDetailType.reading:
      case AssignmentDetailType.grammar:
      case AssignmentDetailType.writing:
        return AssignmentDetailsPhase.content;
      case AssignmentDetailType.vocabulary:
        return AssignmentDetailsPhase.content;
    }
  }

  void showQuiz() => setState(() => phase = AssignmentDetailsPhase.quiz);

  void showResult() => setState(() => phase = AssignmentDetailsPhase.result);

  void toggleRecording() {
    if (isRecording) {
      setState(() => isRecording = false);
      showResult();
    } else {
      setState(() => isRecording = true);
    }
  }

  Widget header() => AssignmentDetailsHeader(
      title: widget.params.title, subtitle: widget.params.subtitle, phase: phase);

  Widget detailsBody() {
    if (phase == AssignmentDetailsPhase.result) {
      return AssignmentResultCard(onContinue: () => context.pop());
    }

    switch (widget.params.type) {
      case AssignmentDetailType.listening:
        return listeningView();
      case AssignmentDetailType.reading:
        return readingView();
      case AssignmentDetailType.speaking:
        return speakingView();
      case AssignmentDetailType.grammar:
        return grammarView();
      case AssignmentDetailType.writing:
        return writingView();
      case AssignmentDetailType.vocabulary:
        return vocabularyView();
    }
  }

  Widget listeningView() => AssignmentQuizView(
      question: 'Which sentence is correct?',
      options: const ['I wake up at 7.', 'I waking up at 7.', 'I wakes up at 7.'],
      onSelect: showResult,
      accentColor: AppColors.green6B);

  Widget speakingView() => Column(children: [
        const AssignmentPromptCard(title: 'Introduce yourself', subtitle: 'Tap to record'),
        const SizedBox(height: 24),
        GestureDetector(
            onTap: toggleRecording,
            child: Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(96),
                    boxShadow: const [
                      BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 6))
                    ]),
                child: Center(
                    child: Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                            color: isRecording ? AppColors.error : AppColors.primary,
                            shape: BoxShape.circle),
                        child: Icon(isRecording ? Icons.stop : Icons.mic,
                            color: AppColors.white, size: 28)))))
      ]);

  Widget readingView() {
    if (phase == AssignmentDetailsPhase.quiz) {
      return AssignmentQuizView(
          question: 'Why are morning routines important?',
          options: const [
            'They help people feel focused.',
            'They make people tired.',
            'They are only for weekends.'
          ],
          onSelect: showResult,
          accentColor: AppColors.blueD3);
    }

    return AssignmentContentView(
        title: 'Daily Routines',
        content: const [
          'Many people start their day with simple morning routines. These routines help them feel more focused, calm, and ready for the day ahead.',
          'A typical morning often begins with waking up early. Some people wake up at the same time every day to keep a stable schedule. After waking up, they usually wash their face, brush their teeth, and get dressed.',
          'Breakfast is an important part of the morning routine. Some people eat a light breakfast, such as fruit or yogurt, while others prefer a full meal with eggs, bread, or cereal. Eating in the morning gives energy and helps people concentrate better during the day.',
          'Many people also take time to read, exercise, or plan their day in the morning. Reading the news or a short book helps them stay informed. Light exercise helps the body feel more active.',
          'Although morning routines are different for everyone, having regular habits can make the day easier and more balanced.'
        ],
        actionLabel: 'Continue to Questions',
        onAction: showQuiz);
  }

  Widget grammarView() {
    if (phase == AssignmentDetailsPhase.quiz) {
      return AssignmentQuizView(
          question: '"By the time she arrived, the meeting ________ already."',
          options: const ['finished', 'has finished', 'had finished', 'finishes'],
          onSelect: showResult,
          accentColor: AppColors.purpleD6);
    }

    return AssignmentContentView(
        title: 'Present Simple',
        content: const [
          'We use the Present Simple to talk about habits, daily routines, and general facts. It describes things that happen regularly or are always true.',
          'For habits, the Present Simple shows what people do every day or often. For example, a person wakes up early, drinks coffee, and goes to work.',
          'We also use the Present Simple to talk about facts. Facts are things that do not change.',
          'For example, the sun rises in the east, and water boils at 100 degrees Celsius.',
          'With he, she, and it, we usually add -s or -es to the verb.'
        ],
        actionLabel: 'Start quiz',
        onAction: showQuiz,
        leadingCard: const AssignmentAudioCard());
  }

  Widget writingView() => AssignmentWritingView(onSubmit: showResult);

  Widget vocabularyView() => AssignmentQuizView(
      question: 'Choose the correct meaning of the word.',
      options: const ['A greeting', 'A type of fruit', 'A place to study'],
      onSelect: showResult,
      accentColor: AppColors.blueB3);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: AppColors.gray50,
      body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                header(),
                const SizedBox(height: 16),
                Expanded(
                    child: SingleChildScrollView(
                        child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: detailsBody())))
              ]))));
}
