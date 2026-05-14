import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/flashcard_sprint/flashcard_sprint_page.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_attempt_model.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_model.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/bloc/mock_exam_sections_bloc/mock_exam_sections_bloc.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/bloc/mock_exam_sections_bloc/mock_exam_sections_event.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/bloc/mock_exam_sections_bloc/mock_exam_sections_state.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class MockExamSectionsPage extends StatefulWidget {
  final String mockExamId;
  final MockExamModel? exam;

  const MockExamSectionsPage({super.key, required this.mockExamId, this.exam});

  @override
  State<MockExamSectionsPage> createState() => MockExamSectionsPageState();
}

class MockExamSectionsPageState extends State<MockExamSectionsPage> {
  final MockExamSectionsBloc sectionsBloc = sl<MockExamSectionsBloc>();
  int selectedComponentIndex = 0;
  Timer? countdownTimer;
  DateTime? attemptDeadlineAt;
  String deadlineAttemptId = '';
  bool didNavigateAway = false;

  @override
  void initState() {
    super.initState();
    loadAttempt();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    sectionsBloc.close();
    super.dispose();
  }

  DateTime? get deadlineAt => attemptDeadlineAt ?? widget.exam?.deadlineAt;

  Duration get remainingDuration {
    final deadline = deadlineAt;
    if (deadline == null) return Duration.zero;
    final remaining = deadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get hasDeadline => deadlineAt != null;

  void startCountdownTimer() {
    if (!hasDeadline) return;
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tickCountdown());
  }

  void syncAttemptDeadline(MockExamAttemptModel attempt) {
    if (attempt.attemptId.isEmpty || attempt.isFinished) return;
    if (attempt.timeRemainingSeconds == null || deadlineAttemptId == attempt.attemptId) return;
    if (attempt.timeRemainingSeconds == 0) {
      openExamListAfterTimeout();
      return;
    }
    deadlineAttemptId = attempt.attemptId;
    attemptDeadlineAt = DateTime.now().add(Duration(seconds: attempt.timeRemainingSeconds!));
    startCountdownTimer();
    setState(() {});
  }

  void tickCountdown() {
    if (!mounted) return;
    if (remainingDuration == Duration.zero) {
      openExamListAfterTimeout();
      return;
    }
    setState(() {});
  }

  void openExamListAfterTimeout() {
    if (didNavigateAway || !mounted) return;
    didNavigateAway = true;
    countdownTimer?.cancel();
    context.go(mockExamRoute);
  }

  void openResultPage(String attemptId) {
    if (didNavigateAway || attemptId.isEmpty) return;
    didNavigateAway = true;
    countdownTimer?.cancel();
    context.pushReplacement(mockExamResultRoute(widget.mockExamId, attemptId), extra: widget.exam);
  }

  void loadAttempt() {
    if (widget.mockExamId.isEmpty) return;
    sectionsBloc.add(MockExamSectionsRequested(mockExamId: widget.mockExamId, exam: widget.exam));
  }

  Future<void> reloadAttempt() async => loadAttempt();

  String title(MockExamSectionsState state) {
    if (state.title.isNotEmpty) return state.title;
    if (widget.exam?.title.isNotEmpty == true) return widget.exam!.title;
    return 'Mock exam'.tr();
  }

  String description(MockExamSectionsState state) {
    if (state.description.isNotEmpty) return state.description;
    return widget.exam?.description ?? '';
  }

  Future<void> onSectionTap(SectionModel section) async {
    if (section.isLocked || !section.isAvailable) return;
    late final Future<bool?> navigation;
    switch (section.sectionType) {
      case SectionType.listening:
        navigation = context.push(learnListeningRoute, extra: section);
        break;
      case SectionType.reading:
        navigation = context.push(learnReadingRoute, extra: section);
        break;
      case SectionType.speaking:
        navigation = context.push(learnSpeakingRoute, extra: section);
        break;
      case SectionType.grammar:
        navigation = context.push(learnGrammarRoute, extra: section);
        break;
      case SectionType.vocabulary:
        if (section.flashCardSet == null) return;
        navigation = context.push(flashcardSprintRoute,
            extra: FlashcardSprintParams(
                set: section.flashCardSet ?? const LearnFlashcardSetModel.empty(),
                sectionModel: section));
        break;
      case SectionType.writing:
        navigation = context.push(learnWritingRoute, extra: section);
        break;
    }
    final result = await navigation;
    if (!mounted) return;
    if (result == true) loadAttempt();
  }

  void finishExam(MockExamSectionsState state) {
    final attempt = state.attempt;
    if (attempt == null || attempt.attemptId.isEmpty) return;
    sectionsBloc
        .add(MockExamFinishRequested(mockExamId: widget.mockExamId, attemptId: attempt.attemptId));
  }

  void listenState(BuildContext context, MockExamSectionsState state) {
    if (state.actionStatus.isError && state.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(state.errorMessage!)));
    }
    if (state.result != null && state.actionStatus.isSuccess) {
      openResultPage(state.result!.attemptId);
    }
    final attempt = state.attempt;
    if (state.status.isSuccess && attempt != null) {
      syncAttemptDeadline(attempt);
    }
    if (state.status.isSuccess && state.attempt?.isFinished == true) {
      final attemptId = state.attempt?.attemptId ?? '';
      openResultPage(attemptId);
    }
  }

  Widget descriptionText(BuildContext context, MockExamSectionsState state) {
    final text = description(state);
    if (text.isEmpty) return const SizedBox.shrink();
    return Text(text, style: Style.bodyw4(context, color: TextColorRole.greyColor));
  }

  String get countdownLabel {
    final duration = remainingDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  Widget countdownCard(BuildContext context) {
    if (!hasDeadline) return const SizedBox.shrink();
    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
            color: AppColors.blueFF,
            borderRadius: Style.border16,
            border: Border.all(color: AppColors.blueD3.withValues(alpha: 0.12))),
        child: Row(children: [
          const Icon(Icons.timer_outlined, color: AppColors.blueD3),
          const SizedBox(width: 10),
          Expanded(
              child: Text('Remaining time'.tr(),
                  style: Style.bodyw5(context).copyWith(color: AppColors.blueD3))),
          Text(countdownLabel, style: Style.bodyw7(context).copyWith(color: AppColors.blueD3))
        ]));
  }

  Widget componentsGrid(MockExamAttemptModel attempt) => GridView.builder(
      itemCount: attempt.components.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 1.05),
      itemBuilder: (context, index) => componentCard(
          attempt.components[index], colorForIndex(index), index == selectedComponentIndex, index));

  Color colorForIndex(int index) {
    const colors = [AppColors.orangeEB, AppColors.greenE7, AppColors.gray50, AppColors.blueFF];
    return colors[index % colors.length];
  }

  Color accentColorForIndex(int index) {
    const colors = [AppColors.orange12, AppColors.green36, AppColors.purpleD6, AppColors.blueD3];
    return colors[index % colors.length];
  }

  IconData iconForComponent(MockExamComponentModel component) {
    switch (component.type.toLowerCase()) {
      case 'listening':
        return Icons.headphones_rounded;
      case 'reading':
        return Icons.menu_book_rounded;
      case 'writing':
        return Icons.edit_rounded;
      case 'speaking':
        return Icons.mic_rounded;
      default:
        return Icons.school_rounded;
    }
  }

  void selectComponent(MockExamComponentModel component, int index) {
    if (component.isLocked) return;
    setState(() => selectedComponentIndex = index);
  }

  Widget componentCard(MockExamComponentModel component, Color color, bool isSelected, int index) =>
      InkWell(
          key: ValueKey('mock_exam_component_${component.id}'),
          onTap: () => selectComponent(component, index),
          borderRadius: Style.border20,
          child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: component.isLocked ? AppColors.gray100 : color,
                  borderRadius: Style.border20,
                  border: Border.all(
                      color: isSelected ? accentColorForIndex(index) : AppColors.gray100,
                      width: isSelected ? 1.6 : 1),
                  boxShadow: [
                    BoxShadow(
                        color: isSelected
                            ? accentColorForIndex(index).withValues(alpha: 0.16)
                            : AppColors.shadow,
                        blurRadius: isSelected ? 18 : 8,
                        offset: const Offset(0, 6))
                  ]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                          color: AppColors.white.withValues(alpha: component.isLocked ? 0.5 : 0.9),
                          borderRadius: Style.border12),
                      child: Icon(iconForComponent(component),
                          size: 18,
                          color:
                              component.isLocked ? AppColors.gray400 : accentColorForIndex(index))),
                  const SizedBox(width: 10),
                  Expanded(child: Text(component.label, style: Style.bodyw6(context))),
                  statusIcon(component)
                ]),
                const SizedBox(height: 8),
                Text(component.statusLabel,
                    style: Style.small2w5(context, color: TextColorRole.greyColor)),
                const Spacer(),
                if (component.timeRemainingSeconds != null)
                  Text(timeLabel(component.timeRemainingSeconds!),
                      style: Style.small2w5(context).copyWith(color: AppColors.gray700)),
                if (component.bandScore != null)
                  Text('Band {band}'.tr(namedArgs: {'band': '${component.bandScore}'}),
                      style: Style.small2w5(context).copyWith(color: AppColors.success))
              ])));

  Widget statusIcon(MockExamComponentModel component) {
    if (component.isCompleted) {
      return const Icon(Icons.check_circle, size: 20, color: AppColors.success);
    }
    if (component.isLocked) return const Icon(Icons.lock, size: 20, color: AppColors.gray400);
    return const Icon(Icons.play_circle, size: 20, color: AppColors.primary);
  }

  String timeLabel(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final hours = duration.inHours;
    final remainingSeconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$remainingSeconds';
    return '$minutes:$remainingSeconds';
  }

  List<SectionModel> sectionsForComponent(MockExamComponentModel component) {
    if (component.subSections.isNotEmpty) return component.subSections;
    if (component.directSection.id.isEmpty) return const [];
    return [component.directSection];
  }

  Widget selectedSectionsPanel(MockExamAttemptModel attempt) {
    final safeIndex = selectedComponentIndex.clamp(0, attempt.components.length - 1).toInt();
    final component = attempt.components[safeIndex];
    final sections = sectionsForComponent(component);
    return AnimatedSwitcher(
        duration: const Duration(milliseconds: 260),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
                    .animate(animation),
                child: child)),
        child: Container(
            key: ValueKey(component.id),
            margin: const EdgeInsets.only(top: 24),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: Style.border24,
                border: Border.all(color: AppColors.gray100),
                boxShadow: const [
                  BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 6))
                ]),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(child: Text(component.label, style: Style.body2w6(context))),
                Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(color: AppColors.gray50, borderRadius: Style.border8),
                    child: Text(component.statusLabel,
                        style: Style.small2w5(context, color: TextColorRole.greyColor)))
              ]),
              const SizedBox(height: 4),
              Text('Choose a part to continue'.tr(),
                  style: Style.small2w4(context, color: TextColorRole.greyColor)),
              const SizedBox(height: 14),
              if (sections.isEmpty)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('No sections yet'.tr())))
              else
                ...sections.map((section) => Padding(
                    padding: const EdgeInsets.only(bottom: 10), child: subSectionTile(section)))
            ])));
  }

  Widget subSectionTile(SectionModel section) => InkWell(
      key: ValueKey('mock_exam_section_${section.id}'),
      onTap: section.isLocked ||
              !section.isAvailable ||
              section.progressState == SectionProgressState.completed
          ? null
          : () => onSectionTap(section),
      borderRadius: Style.border16,
      child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: Style.border16,
              border: Border.all(color: AppColors.gray100)),
          child: Row(children: [
            Icon(
                section.progressState == SectionProgressState.completed
                    ? Icons.check_circle
                    : section.isLocked || !section.isAvailable
                        ? Icons.lock
                        : Icons.play_circle,
                color: section.progressState == SectionProgressState.completed
                    ? AppColors.success
                    : section.isLocked || !section.isAvailable
                        ? AppColors.gray400
                        : AppColors.primary),
            const SizedBox(width: 12),
            Expanded(child: Text(section.sectionTypeLabel, style: Style.bodyw5(context))),
            Text(section.status.isEmpty ? '' : SectionModel.formatTypeLabel(section.status),
                style: Style.small2w5(context, color: TextColorRole.greyColor))
          ])));

  Widget content(MockExamSectionsState state) {
    if (state.status.isLoading || state.status.isInitial) {
      return const ShimmerList(
          itemCount: 4,
          itemHeight: 120,
          separatorHeight: 12,
          borderRadius: BorderRadius.all(Radius.circular(20)));
    }
    if (state.status.isError) {
      return Center(child: Text(state.errorMessage ?? 'Request failed. Please try again.'.tr()));
    }
    final attempt = state.attempt;
    if (attempt == null || attempt.components.isEmpty) {
      return Center(child: Text('No sections yet'.tr()));
    }
    if (selectedComponentIndex >= attempt.components.length) {
      selectedComponentIndex = 0;
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      componentsGrid(attempt),
      selectedSectionsPanel(attempt),
      const SizedBox(height: 24),
      Button.primary(
          key: const ValueKey('mock_exam_finish_button'),
          onTap: () => finishExam(state),
          text: 'Finish exam'.tr(),
          isLoading: state.actionStatus.isLoading)
    ]);
  }

  Widget body(BuildContext context, MockExamSectionsState state) => PrimaryBackground(
      title: title(state),
      isScrollable: false,
      child: RefreshIndicator(
          onRefresh: reloadAttempt,
          child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
            descriptionText(context, state),
            if (hasDeadline) ...[const SizedBox(height: 14), countdownCard(context)],
            const SizedBox(height: 20),
            content(state),
            const SizedBox(height: 80)
          ])));

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: BlocConsumer<MockExamSectionsBloc, MockExamSectionsState>(
          bloc: sectionsBloc,
          listener: listenState,
          builder: (context, state) => body(context, state)));
}
