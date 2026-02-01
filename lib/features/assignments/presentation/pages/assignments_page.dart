import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
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

  @override
  void initState() {
    super.initState();
    assignmentsBloc.add(const AssignmentsRequested());
  }

  @override
  void dispose() {
    assignmentsBloc.close();
    super.dispose();
  }

  List<AssignmentModel> activeAssignments(List<AssignmentModel> list) =>
      list.where((assignment) => assignment.isActive).toList();

  List<AssignmentModel> newAssignments(List<AssignmentModel> list) =>
      activeAssignments(list).where((assignment) => assignment.progress == 0).toList();

  List<AssignmentModel> inProgressAssignments(List<AssignmentModel> list) =>
      activeAssignments(list).where((assignment) => assignment.progress > 0).toList();

  List<AssignmentModel> completedAssignments(List<AssignmentModel> list) =>
      list.where((assignment) => assignment.isCompleted).toList();

  void onSelectedTabIndex(int index) => setState(() => selectedTabIndex = index);

  Future<void> openAssignmentSections(AssignmentModel assignment) async {
    await context.push(assignmentsSectionsRoute, extra: AssignmentSectionsParams(assignment: assignment));
    if (!mounted) return;
    assignmentsBloc.add(const AssignmentsRequested());
  }

  Widget tabSelector() => SegmentedControl(
      labels: const ['Active', 'Completed'],
      selectedIndex: selectedTabIndex,
      onChanged: onSelectedTabIndex);

  Widget sectionHeader(BuildContext context, String title) =>
      Text(title, style: Style.body2w6(context));

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
          child: Text(label, style: Style.bodyw4(context, color: TextColorRole.greyColor))));

  Widget activeTabView(BuildContext context, List<AssignmentModel> assignments) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        sectionHeader(context, 'New Assignments'),
        const SizedBox(height: 12),
        if (newAssignments(assignments).isEmpty)
          emptyState(context, 'No new assignments yet')
        else
          assignmentsList(newAssignments(assignments)),
        const SizedBox(height: 16),
        sectionHeader(context, 'In Progress'),
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

  Widget content(BuildContext context, List<AssignmentModel> assignments) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        tabSelector(),
        const SizedBox(height: 20),
        if (selectedTabIndex == 0)
          activeTabView(context, assignments)
        else
          completedTabView(context, assignments),
        const SizedBox(height: 80)
      ]);

  Widget body(BuildContext context) => PrimaryBackground(
      title: 'Assignments',
      isScrollable: true,
      child: BlocStatusView<AssignmentsBloc, AssignmentsState, List<AssignmentModel>>(
          bloc: assignmentsBloc,
          statusOf: (state) => state.status,
          errorOf: (state) => state.errorMessage,
          data: (state) => state.assignments,
          isEmpty: (data) => data.isEmpty,
          empty: emptyState(context, 'No assignments found'),
          builder: (context, data) => content(context, data)));

  @override
  Widget build(BuildContext context) =>
      Scaffold(backgroundColor: context.cs.surface, body: SafeArea(child: body(context)));
}
