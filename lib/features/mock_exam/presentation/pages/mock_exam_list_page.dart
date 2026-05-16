import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/listviews/paginated_list_view.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_model.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/bloc/mock_exam_list_bloc/mock_exam_list_bloc.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/bloc/mock_exam_list_bloc/mock_exam_list_event.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/bloc/mock_exam_list_bloc/mock_exam_list_state.dart';
import 'package:ustadia_user_app/features/mock_exam/presentation/widgets/mock_exam_card.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class MockExamListPage extends StatefulWidget {
  const MockExamListPage({super.key});

  @override
  State<MockExamListPage> createState() => MockExamListPageState();
}

class MockExamListPageState extends State<MockExamListPage> {
  final MockExamListBloc examsBloc = sl<MockExamListBloc>();
  Timer? countdownTimer;
  DateTime? lastExpiredRefreshAt;
  GoRouter? router;
  bool wasVisible = false;

  @override
  void initState() {
    super.initState();
    examsBloc.add(const MockExamListRequested());
    startCountdownTimer();
  }

  @override
  void dispose() {
    countdownTimer?.cancel();
    router?.routerDelegate.removeListener(onRouteChanged);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final currentRouter = GoRouter.of(context);
    if (router == currentRouter) return;
    router?.routerDelegate.removeListener(onRouteChanged);
    router = currentRouter;
    wasVisible = isCurrentRoute;
    router?.routerDelegate.addListener(onRouteChanged);
  }

  bool get isCurrentRoute {
    final location = router?.routerDelegate.currentConfiguration.uri.path ?? '';
    return location == mockExamRoute;
  }

  void onRouteChanged() {
    if (!mounted) return;
    final isVisible = isCurrentRoute;
    if (isVisible && !wasVisible) refreshExams();
    wasVisible = isVisible;
  }

  void startCountdownTimer() {
    countdownTimer?.cancel();
    countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) => tickCountdown());
  }

  void tickCountdown() {
    if (!mounted) return;
    final hasActiveDeadline = examsBloc.state.exams.any((exam) => exam.hasDeadline);
    if (hasActiveDeadline) setState(() {});
    final hasExpired = examsBloc.state.exams.any((exam) => exam.isExpired);
    if (!hasExpired) {
      lastExpiredRefreshAt = null;
      return;
    }
    final now = DateTime.now();
    final canRefresh = lastExpiredRefreshAt == null ||
        now.difference(lastExpiredRefreshAt!) >= const Duration(seconds: 5);
    if (canRefresh) {
      lastExpiredRefreshAt = now;
      refreshExams(resetExpiredRefreshAt: false);
    }
  }

  Future<void> reloadExams() async {
    lastExpiredRefreshAt = null;
    examsBloc.add(const MockExamListRequested());
  }

  Future<void> refreshExams({bool resetExpiredRefreshAt = true}) async {
    if (resetExpiredRefreshAt) lastExpiredRefreshAt = null;
    examsBloc.add(const MockExamListRequested(showLoading: false));
  }

  void loadMoreExams() {
    examsBloc.add(const MockExamListLoadMoreRequested());
  }

  void openHistory() => context.push(mockExamHistoryRoute);

  Future<void> openExam(MockExamModel exam) async {
    if (exam.isFinished) {
      final attemptId = exam.resultAttemptId;
      if (attemptId.isEmpty) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Result is not available yet'.tr())));
        return;
      }
      await context.push(mockExamResultRoute(exam.id, attemptId), extra: exam);
      return;
    }
    await context.push(mockExamSectionsRoute(exam.id), extra: exam);
    if (!mounted) return;
    refreshExams();
  }

  Widget examsList(BuildContext context, List<MockExamModel> exams, MockExamListState state) =>
      PaginatedListView(
          items: exams,
          padding: Style.paddingPrimary,
          separatorHeight: 12,
          onRefresh: reloadExams,
          hasMore: state.pagination.hasNext,
          isLoadingMore: state.isLoadingMore,
          onLoadMore: state.pagination.hasNext ? () async => loadMoreExams() : null,
          itemBuilder: (exam) => MockExamCard(exam: exam, onTap: () => openExam(exam)));

  Widget
      get contentChecker =>
          BlocStatusView<MockExamListBloc, MockExamListState, List<MockExamModel>>(
              bloc: examsBloc,
              statusOf: (state) => state.status,
              errorOf: (state) => state.errorMessage,
              data: (state) => state.exams,
              isEmpty: (exams) => exams.isEmpty,
              keepDataOnLoading: true,
              loading: ShimmerList(
                  itemCount: 5,
                  itemHeight: 96,
                  padding: Style.paddingPrimary,
                  borderRadius: Style.border20),
              empty: Center(child: Text('No mock exams found'.tr())),
              builder: (context, exams) => examsList(context, exams, examsBloc.state));

  Widget historyButton(BuildContext context) => Align(
      alignment: Alignment.centerRight,
      child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
          child: InkWell(
              onTap: openHistory,
              borderRadius: Style.border12,
              child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: Style.border12,
                      border: Border.all(color: AppColors.gray100)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Icon(Icons.history, size: 18, color: AppColors.gray700),
                    const SizedBox(width: 6),
                    Text('History'.tr(), style: Style.small2w5(context))
                  ])))));

  Widget bodyContent(BuildContext context) =>
      Column(children: [historyButton(context), Expanded(child: contentChecker)]);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(
          title: 'Mock exam'.tr(), isScrollable: false, child: bodyContent(context)));
}
