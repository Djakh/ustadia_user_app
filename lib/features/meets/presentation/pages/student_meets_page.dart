import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/listviews/paginated_list_view.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/meets/data/models/student_meet_model.dart';
import 'package:ustadia_user_app/features/meets/presentation/bloc/student_meets_bloc/student_meets_bloc.dart';
import 'package:ustadia_user_app/features/meets/presentation/bloc/student_meets_bloc/student_meets_event.dart';
import 'package:ustadia_user_app/features/meets/presentation/bloc/student_meets_bloc/student_meets_state.dart';
import 'package:ustadia_user_app/features/meets/presentation/widgets/student_meet_card.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentMeetsPage extends StatefulWidget {
  const StudentMeetsPage({super.key});

  @override
  State<StudentMeetsPage> createState() => StudentMeetsPageState();
}

class StudentMeetsPageState extends State<StudentMeetsPage> {
  static const Duration tabAnimationDuration = Duration(milliseconds: 260);
  static const Curve tabAnimationCurve = Curves.easeOutCubic;

  int selectedTabIndex = 0;
  final PageController tabController = PageController();
  final StudentMeetsBloc meetsBloc = sl<StudentMeetsBloc>();
  Timer? clockTimer;

  @override
  void initState() {
    super.initState();
    meetsBloc.add(const StudentMeetsRequested());
    clockTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    clockTimer?.cancel();
    tabController.dispose();
    meetsBloc.close();
    super.dispose();
  }

  bool get isActualTab => selectedTabIndex == 0;

  void onSelectedTabIndex(int index) {
    if (index == selectedTabIndex) return;
    setState(() => selectedTabIndex = index);
    if (!tabController.hasClients) return;
    tabController.animateToPage(index, duration: tabAnimationDuration, curve: tabAnimationCurve);
  }

  Future<void> reloadMeets() async {
    meetsBloc.add(const StudentMeetsRequested(showLoading: false));
  }

  void loadMoreMeets() {
    meetsBloc.add(const StudentMeetsLoadMoreRequested());
  }

  void showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> openMeetLink(StudentMeetModel meet) async {
    final link = meet.link.trim();
    final normalizedLink = link.contains('://') ? link : 'https://$link';
    final uri = Uri.tryParse(normalizedLink);
    if (uri == null || !uri.hasScheme) {
      showMessage('Meeting link is not available'.tr());
      return;
    }
    try {
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) showMessage('Could not open meeting link'.tr());
    } catch (_) {
      showMessage('Could not open meeting link'.tr());
    }
  }

  void onPageChanged(int index) {
    if (index == selectedTabIndex) return;
    setState(() => selectedTabIndex = index);
  }

  List<StudentMeetModel> tabMeets(StudentMeetsState state, bool isActual) {
    final now = DateTime.now();
    return isActual ? state.actualMeets(now) : state.historyMeets(now);
  }

  Widget tabLabel(String label, int index) {
    final selected = selectedTabIndex == index;
    return Expanded(
        child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onSelectedTabIndex(index),
            child: Center(
                child: AnimatedDefaultTextStyle(
                    duration: tabAnimationDuration,
                    curve: tabAnimationCurve,
                    style: Style.small2w5(context)
                        .copyWith(color: selected ? context.cs.onSurface : AppColors.gray8D),
                    child: Text(label)))));
  }

  Widget tabSelector() => Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(color: AppColors.grayEE, borderRadius: Style.border16),
      child: SizedBox(
          height: 38,
          child: LayoutBuilder(builder: (context, constraints) {
            final indicatorWidth = constraints.maxWidth / 2;
            return Stack(children: [
              AnimatedPositioned(
                  duration: tabAnimationDuration,
                  curve: tabAnimationCurve,
                  left: indicatorWidth * selectedTabIndex,
                  top: 0,
                  bottom: 0,
                  width: indicatorWidth,
                  child: DecoratedBox(
                      decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: Style.border12,
                          boxShadow: const [
                        BoxShadow(color: AppColors.shadow, blurRadius: 10, offset: Offset(0, 4))
                      ]))),
              Row(children: [tabLabel('Actual'.tr(), 0), tabLabel('History'.tr(), 1)])
            ]);
          })));

  Widget emptyState(BuildContext context, bool isActual) => Center(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                height: 68,
                width: 68,
                decoration: const BoxDecoration(color: AppColors.greenE7, shape: BoxShape.circle),
                child: const Icon(Icons.video_call_outlined, color: AppColors.green36, size: 34)),
            const SizedBox(height: 14),
            Text(isActual ? 'No actual meets'.tr() : 'No meet history'.tr(),
                textAlign: TextAlign.center, style: Style.bodyw6(context)),
            const SizedBox(height: 6),
            Text(
                isActual
                    ? 'Upcoming meetings will appear here'.tr()
                    : 'Finished meetings will appear here'.tr(),
                textAlign: TextAlign.center,
                style: Style.small3w4(context, color: TextColorRole.greyColor))
          ])));

  Widget meetsList(BuildContext context, List<StudentMeetModel> meets, StudentMeetsState state,
          bool isActual) =>
      meets.isEmpty
          ? RefreshIndicator(
              onRefresh: reloadMeets,
              child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: [emptyState(context, isActual)]))
          : PaginatedListView(
              items: meets,
              padding: Style.paddingPrimary,
              separatorHeight: 12,
              onRefresh: reloadMeets,
              hasMore: state.pagination.hasNext,
              isLoadingMore: state.isLoadingMore,
              onLoadMore: state.pagination.hasNext ? () async => loadMoreMeets() : null,
              itemBuilder: (meet) =>
                  StudentMeetCard(meet: meet, onOpenLink: () => openMeetLink(meet)));

  Widget tabsPageView(BuildContext context, StudentMeetsState state) =>
      PageView(controller: tabController, onPageChanged: onPageChanged, children: [
        meetsList(context, tabMeets(state, true), state, true),
        meetsList(context, tabMeets(state, false), state, false)
      ]);

  Widget get contentChecker =>
      BlocStatusView<StudentMeetsBloc, StudentMeetsState, List<StudentMeetModel>>(
          bloc: meetsBloc,
          statusOf: (state) => state.status,
          errorOf: (state) => state.errorMessage,
          data: (state) => state.meets,
          isEmpty: (meets) => meets.isEmpty,
          keepDataOnLoading: true,
          loading: ShimmerList(
              itemCount: 4,
              itemHeight: 158,
              padding: Style.paddingPrimary,
              borderRadius: Style.border20),
          empty: emptyState(context, isActualTab),
          builder: (context, meets) => tabsPageView(context, meetsBloc.state));

  Widget body(BuildContext context) => Column(children: [
        const SizedBox(height: 20),
        tabSelector(),
        const SizedBox(height: 4),
        Expanded(child: contentChecker)
      ]);

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: context.cs.surface,
      body: PrimaryBackground(title: 'Meets'.tr(), isScrollable: false, child: body(context)));
}
