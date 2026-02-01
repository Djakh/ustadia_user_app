import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/assignments/data/datasources/assignments_remote_data_source.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_sections_params.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_model.dart';
import 'package:ustadia_user_app/features/assignments/presentation/widgets/assignment_section_card.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class AssignmentSectionsPage extends StatefulWidget {
  final AssignmentSectionsParams params;

  const AssignmentSectionsPage({super.key, required this.params});

  @override
  State<AssignmentSectionsPage> createState() => AssignmentSectionsPageState();
}

class AssignmentSectionsPageState extends State<AssignmentSectionsPage> {
  final AssignmentsRemoteDataSource assignmentsRemoteDataSource =
      sl<AssignmentsRemoteDataSource>();
  late AssignmentModel assignment;

  @override
  void initState() {
    super.initState();
    assignment = widget.params.assignment;
  }

  List<SectionModel> get sections {
    final list = [...assignment.sections];
    list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return list;
  }

  Future<void> refreshAssignment() async {
    final list = await assignmentsRemoteDataSource.fetchAssignments();
    final updated = list.where((item) => item.id == assignment.id).toList();
    if (updated.isEmpty) return;
    if (!mounted) return;
    setState(() => assignment = updated.first);
  }

  Future<void> openSectionDetails(SectionModel sectionModel) async {
    switch (sectionModel.sectionType) {
      case SectionType.listening:
        await context.push(learnListeningRoute, extra: sectionModel);
        break;
      case SectionType.reading:
        await context.push(learnReadingRoute, extra: sectionModel);
        break;
      case SectionType.speaking:
        await context.push(learnSpeakingRoute, extra: sectionModel);
        break;
      case SectionType.grammar:
        await context.push(learnGrammarRoute, extra: sectionModel);
        break;
      case SectionType.vocabulary:
        await context.push(learnReadingRoute, extra: sectionModel);
        break;
      case SectionType.writing:
        await context.push(learnWritingRoute, extra: sectionModel);
        break;
    }
    await refreshAssignment();
  }

  Widget sectionList() => Column(
      children: sections
          .map((section) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: AssignmentSectionCard(
                  section: section, onTap: () => openSectionDetails(section))))
          .toList());

  Widget body(BuildContext context) => PrimaryBackground(
      title: assignment.title,
      isScrollable: true,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const SizedBox(height: 24),
        Text(assignment.description,
            style: Style.bodyw4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 20),
        if (sections.isEmpty)
          Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text('No sections yet',
                      style: Style.bodyw4(context, color: TextColorRole.greyColor))))
        else
          sectionList(),
        const SizedBox(height: 80)
      ]));

  @override
  Widget build(BuildContext context) =>
      Scaffold(backgroundColor: context.cs.surface, body: SafeArea(child: body(context)));
}
