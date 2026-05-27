import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_box.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/core/widgets/toggles/segmented_control.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_models.dart';
import 'package:ustadia_user_app/features/assignments/presentation/bloc/assignments_bloc/assignments_bloc.dart';
import 'package:ustadia_user_app/features/assignments/presentation/bloc/assignments_bloc/assignments_event.dart';
import 'package:ustadia_user_app/features/assignments/presentation/bloc/assignments_bloc/assignments_state.dart';
import 'package:ustadia_user_app/features/assignments/presentation/widgets/assignment_card.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class AssignmentsPage extends StatefulWidget {
  const AssignmentsPage({super.key});

  @override
  State<AssignmentsPage> createState() => AssignmentsPageState();
}

class AssignmentsPageState extends State<AssignmentsPage> {
  int selectedTabIndex = 0;
  final AssignmentsBloc assignmentsBloc = sl<AssignmentsBloc>();
  final GlobalKey tabsKey = GlobalKey(debugLabel: 'assignments_tabs');
  final GlobalKey listKey = GlobalKey(debugLabel: 'assignments_list');

  @override
  void initState() {
    super.initState();
    if (assignmentsBloc.state.assignments.isEmpty) {
      assignmentsBloc.add(const AssignmentsRequested());
    }
  }

  @override
  void dispose() => super.dispose();

  List<AssignmentModel> activeAssignments(List<AssignmentModel> list) =>
      list.where((assignment) => assignment.isActive).toList();

  List<AssignmentModel> newAssignments(List<AssignmentModel> list) =>
      activeAssignments(list).where((assignment) => assignment.progress == 0).toList();

  List<AssignmentModel> inProgressAssignments(List<AssignmentModel> list) =>
      activeAssignments(list).where((assignment) => assignment.progress > 0).toList();

  List<AssignmentModel> completedAssignments(List<AssignmentModel> list) =>
      list.where((assignment) => assignment.isCompleted).toList();

  void onSelectedTabIndex(int index) => setState(() => selectedTabIndex = index);

  Future<void> reloadAssignments() async {
    assignmentsBloc.add(const AssignmentsRequested());
  }

  Future<void> openAssignmentSections(AssignmentModel assignment) async {
    final result = await context.push(assignmentsSectionsRoute,
        extra: AssignmentSectionsParams(assignment: assignment));
    if (!mounted) return;
    if (result == true) assignmentsBloc.add(const AssignmentsRequested());
  }

  Widget tabSelector() => KeyedSubtree(
      key: tabsKey,
      child: SegmentedControl(
          labels: ['active'.tr(), 'Completed'.tr()],
          selectedIndex: selectedTabIndex,
          onChanged: onSelectedTabIndex));

  Widget sectionHeader(BuildContext context, String title) =>
      Text(title.tr(), style: Style.body2w6(context));

  Widget assignmentsList(List<AssignmentModel> list) => Column(
      children: list
          .map((assignment) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AssignmentCard(
                  assignment: assignment, onTap: () => openAssignmentSections(assignment))))
          .toList());

  Widget emptyState(BuildContext context, String label) => Center(
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Text(label.tr(), style: Style.bodyw4(context, color: TextColorRole.greyColor))));

  Widget activeTabView(BuildContext context, List<AssignmentModel> assignments) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sectionHeader(context, 'New Assignments'),
        const SizedBox(height: 12),
        if (newAssignments(assignments).isEmpty)
          emptyState(context, 'No new assignments yet')
        else
          assignmentsList(newAssignments(assignments)),
        const SizedBox(height: 16),
        sectionHeader(context, 'in_progress'),
        const SizedBox(height: 12),
        if (inProgressAssignments(assignments).isEmpty)
          emptyState(context, 'No assignments in progress')
        else
          assignmentsList(inProgressAssignments(assignments))
      ]);

  Widget completedTabView(BuildContext context, List<AssignmentModel> assignments) =>
      completedAssignments(assignments).isEmpty
          ? emptyState(context, 'No completed assignments yet')
          : assignmentsList(completedAssignments(assignments));

  Widget body(BuildContext context) => PrimaryBackground(
      title: 'Assignments'.tr(),
      isScrollable: false,
      child: BlocStatusView<AssignmentsBloc, AssignmentsState, List<AssignmentModel>>(
          bloc: assignmentsBloc,
          statusOf: (state) => state.status,
          errorOf: (state) => state.errorMessage,
          data: (state) => state.assignments,
          isEmpty: (data) => data.isEmpty,
          keepDataOnLoading: false,
          empty: emptyState(context, 'No assignments found'),
          loading: const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(height: 24),
            ShimmerBox(height: 40, width: 180, borderRadius: BorderRadius.all(Radius.circular(20))),
            SizedBox(height: 20),
            ShimmerList(
                itemCount: 3, itemHeight: 160, borderRadius: BorderRadius.all(Radius.circular(24)))
          ]),
          builder: (context, data) => RefreshIndicator(
              onRefresh: reloadAssignments,
              child: ListView(physics: const AlwaysScrollableScrollPhysics(), children: [
                const SizedBox(height: 24),
                tabSelector(),
                const SizedBox(height: 20),
                KeyedSubtree(
                    key: listKey,
                    child: selectedTabIndex == 0
                        ? activeTabView(context, data)
                        : completedTabView(context, data)),
                const SizedBox(height: 80)
              ]))));

  @override
  Widget build(BuildContext context) => GuidedTutorialPage(
      pageId: TutorialPageIds.assignments,
      steps: TutorialPresets.assignments(tabsKey: tabsKey, listKey: listKey),
      child: Scaffold(backgroundColor: context.cs.surface, body: SafeArea(child: body(context))));
}
