import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/loading/primary_circular_progress_indicator.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/features/intro_survey/data/intro_survey_models.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/bloc/intro_survey_bloc.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/bloc/intro_survey_event.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/bloc/intro_survey_state.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/widgets/intro_survey_header_card.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/widgets/steps/intro_survey_multiple_choice.dart';
import 'package:ustadia_user_app/features/intro_survey/presentation/widgets/steps/intro_survey_single_choice.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';
import 'package:easy_localization/easy_localization.dart';

class IntroSurveyPage extends StatefulWidget {
  const IntroSurveyPage({super.key});

  @override
  State<IntroSurveyPage> createState() => IntroSurveyPageState();
}

class IntroSurveyPageState extends State<IntroSurveyPage> {
  final PageController controller = PageController();
  int pageIndex = 0;
  int lastAllowedIndex = 0;
  bool isSubmitting = false;
  bool isSubmittingAnswer = false;

  final Map<String, Set<String>> selectedAnswerIdsByQuestion = {};
  final Set<String> submittedQuestionIds = {};

  final UserBloc userBloc = sl<UserBloc>();
  final IntroSurveyBloc introSurveyBloc = sl<IntroSurveyBloc>();

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    if (userBloc.state.profile == null) {
      userBloc.add(const UserProfileRequested());
    }
    introSurveyBloc.add(const IntroSurveyRequested());
  }

  @override
  void dispose() {
    controller.dispose();
    introSurveyBloc.close();
    super.dispose();
  }

  /// --- Listeners ---

  void userListener(BuildContext context, UserState state) {
    syncPager(filteredQuestions(introSurveyBloc.state.questions, state));
    if (!isSubmitting) return;
    if (state.status == Status.success) {
      setState(() => isSubmitting = false);
      final profile = state.profile;
      if (profile != null && profile.introCompleted) {
        context.go(dashboardRoute);
        return;
      }
      context.go(loginRoute);
    }
    if (state.status == Status.error && state.errorMessage != null) {
      setState(() => isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
  }

  void introSurveyListener(BuildContext context, IntroSurveyState state) {
    if (!isSubmittingAnswer) return;
    if (state.submissionStatus == Status.error) {
      setState(() => isSubmittingAnswer = false);
      final message = state.submissionErrorMessage ?? 'Submission failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
    if (state.submissionStatus == Status.success) {
      final currentQuestionId = state.submissionQuestionId;
      setState(() {
        isSubmittingAnswer = false;
        if (currentQuestionId != null && currentQuestionId.isNotEmpty) {
          submittedQuestionIds.add(currentQuestionId);
        }
      });
      final questions = filteredQuestions(state.questions, userBloc.state);
      syncPager(questions);
      if (questions.isNotEmpty) return;
      setState(() => isSubmitting = true);
      userBloc.add(const UserProfileRequested());
    }
  }

  /// --- Methods ---
  Set<String> answeredQuestionIds(UserState userState) => userState.profile?.introAnswers
          .map((item) => item.questionId)
          .where((id) => id.isNotEmpty)
          .toSet() ??
      {};

  List<IntroSurveyQuestionModel> filteredQuestions(
      List<IntroSurveyQuestionModel> questions, UserState userState) {
    final answeredIds = answeredQuestionIds(userState);
    return questions
        .where((question) =>
            !answeredIds.contains(question.id) && !submittedQuestionIds.contains(question.id))
        .toList();
  }

  void syncPager(List<IntroSurveyQuestionModel> questions) {
    if (questions.isEmpty) {
      if (pageIndex != 0 || lastAllowedIndex != 0) {
        setState(() {
          pageIndex = 0;
          lastAllowedIndex = 0;
        });
      }
      return;
    }
    final nextIndex = pageIndex >= questions.length ? questions.length - 1 : pageIndex;
    final nextAllowedIndex =
        lastAllowedIndex >= questions.length ? questions.length - 1 : lastAllowedIndex;
    if (nextIndex == pageIndex && nextAllowedIndex == lastAllowedIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !controller.hasClients) return;
        if (controller.page?.round() == nextIndex) return;
        controller.jumpToPage(nextIndex);
      });
      return;
    }
    setState(() {
      pageIndex = nextIndex;
      lastAllowedIndex = nextAllowedIndex;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !controller.hasClients) return;
      controller.jumpToPage(nextIndex);
    });
  }

  bool canContinueFor(int index, List<IntroSurveyQuestionModel> questions) {
    if (index < 0 || index >= questions.length) return false;
    final question = questions[index];
    final selected = selectedAnswerIdsByQuestion[question.id];
    return selected != null && selected.isNotEmpty;
  }

  bool canContinue(List<IntroSurveyQuestionModel> questions) =>
      canContinueFor(pageIndex, questions);

  void goToNext(List<IntroSurveyQuestionModel> questions) {
    if (!canContinue(questions)) return;
    final question = questions[pageIndex];
    final selectedIds = selectedAnswerIdsByQuestion[question.id] ?? <String>{};
    if (selectedIds.isEmpty) return;
    setState(() => isSubmittingAnswer = true);
    introSurveyBloc
        .add(IntroSurveyAnswerSubmitted(questionId: question.id, answerIds: selectedIds.toList()));
  }

  void onPageChanged(int index, List<IntroSurveyQuestionModel> questions) {
    final isForward = index > lastAllowedIndex;
    if (isForward && !canContinueFor(lastAllowedIndex, questions)) {
      controller.animateToPage(lastAllowedIndex,
          duration: const Duration(milliseconds: 220), curve: Curves.easeOutCubic);
      return;
    }

    setState(() {
      pageIndex = index;
      lastAllowedIndex = index;
    });
  }

  void toggleAnswer(String questionId, String answerId) {
    final current = selectedAnswerIdsByQuestion[questionId] ?? <String>{};
    if (current.contains(answerId)) {
      current.remove(answerId);
    } else {
      current.add(answerId);
    }
    setState(() => selectedAnswerIdsByQuestion[questionId] = current);
  }

  void selectAnswer(String questionId, String answerId) =>
      setState(() => selectedAnswerIdsByQuestion[questionId] = {answerId});

  String? selectedAnswerIdFor(String questionId) {
    final selected = selectedAnswerIdsByQuestion[questionId];
    if (selected == null || selected.isEmpty) return null;
    return selected.first;
  }

  String headerSubtitleFor(IntroSurveyQuestionType type) =>
      type == IntroSurveyQuestionType.multiple ? 'Select all that apply' : 'Select one';

  /// --- Widgets ---

  int fullQuestionIndex(
      IntroSurveyQuestionModel question, List<IntroSurveyQuestionModel> allQuestions) {
    final index = allQuestions.indexWhere((item) => item.id == question.id);
    if (index == -1) return pageIndex;
    return index;
  }

  Widget buildHeader(
      List<IntroSurveyQuestionModel> questions, List<IntroSurveyQuestionModel> allQuestions) {
    final question = questions[pageIndex];
    final originalIndex = fullQuestionIndex(question, allQuestions);
    return Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
        child: IntroSurveyHeaderCard(
            stepIndex: originalIndex,
            totalSteps: allQuestions.length,
            title: question.description,
            subtitle: headerSubtitleFor(question.type)));
  }

  Widget buildQuestions(List<IntroSurveyQuestionModel> questions) => Expanded(
        child: PageView(
            key: ValueKey(questions.map((item) => item.id).join(',')),
            controller: controller,
            onPageChanged: (index) => onPageChanged(index, questions),
            physics: const PageScrollPhysics(),
            children: questions
                .map((question) => question.type == IntroSurveyQuestionType.multiple
                    ? IntroSurveyMultipleChoice(
                        answers: question.answers,
                        selectedAnswerIds: selectedAnswerIdsByQuestion[question.id] ?? {},
                        onToggleAnswer: (answerId) => toggleAnswer(question.id, answerId))
                    : IntroSurveySingleChoice(
                        answers: question.answers,
                        selectedAnswerId: selectedAnswerIdFor(question.id),
                        onSelectAnswer: (answerId) => selectAnswer(question.id, answerId)))
                .toList()),
      );

  Widget buildContinueButton(List<IntroSurveyQuestionModel> questions) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Button.primary(
            onTap: () => goToNext(questions),
            text: 'Continue'.tr(),
            isAvialable: canContinue(questions) && !isSubmitting && !isSubmittingAnswer,
            isLoading: isSubmitting || isSubmittingAnswer),
      );

  Widget buildErrorState(String message) => Center(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Button.primary(
                onTap: () => introSurveyBloc.add(const IntroSurveyRequested()),
                text: 'Retry'.tr())
          ])));

  Widget buildContent(IntroSurveyState state, UserState userState) {
    if (state.status == Status.loading || state.status == Status.initial) {
      return const PrimaryLoadingIndicator();
    }
    if (state.status == Status.error) {
      return buildErrorState(state.errorMessage ?? 'Failed to load questions');
    }
    final questions = filteredQuestions(state.questions, userState);
    if (state.questions.isEmpty) {
      return buildErrorState('No questions found');
    }
    if (questions.isEmpty) {
      if (!isSubmitting && userState.status != Status.loading) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted || isSubmitting) return;
          setState(() => isSubmitting = true);
          userBloc.add(const UserProfileRequested());
        });
      }
      return const PrimaryLoadingIndicator();
    }
    return Column(children: [
      buildHeader(questions, state.questions),
      buildQuestions(questions),
      SafeArea(top: false, child: buildContinueButton(questions))
    ]);
  }

  @override
  Widget build(BuildContext context) => MultiBlocListener(
          listeners: [
            BlocListener<UserBloc, UserState>(bloc: userBloc, listener: userListener),
            BlocListener<IntroSurveyBloc, IntroSurveyState>(
                bloc: introSurveyBloc, listener: introSurveyListener)
          ],
          child: Scaffold(
              backgroundColor: context.cs.surface,
              body: SafeArea(
                  child: BlocBuilder<IntroSurveyBloc, IntroSurveyState>(
                      bloc: introSurveyBloc,
                      builder: (context, introState) => BlocBuilder<UserBloc, UserState>(
                          bloc: userBloc,
                          builder: (context, userState) => buildContent(introState, userState))))));
}
