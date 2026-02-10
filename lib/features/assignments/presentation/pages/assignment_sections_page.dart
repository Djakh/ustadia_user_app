import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/assignments/data/services/assignment_sections_store.dart';
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
  final AssignmentSectionsStore sectionsStore = sl<AssignmentSectionsStore>();
  late AssignmentModel assignment;
  List<SectionModel> sections = [];
  bool isLoading = false;
  String? errorMessage;
  bool shouldRefreshParent = false;

  @override
  void initState() {
    super.initState();
    assignment = widget.params.assignment;
    loadSections();
  }

  Future<void> loadSections({bool forceRefresh = false}) async {
    if (assignment.id.isEmpty) return;
    setState(() {
      isLoading = sections.isEmpty;
      errorMessage = null;
    });
    try {
      final list = await sectionsStore.loadSections(assignment.id, forceRefresh: forceRefresh);
      list.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      if (!mounted) return;
      setState(() => sections = list);
    } catch (error) {
      if (!mounted) return;
      setState(() => errorMessage = error.toString());
    } finally {
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  Future<void> openSectionDetails(SectionModel sectionModel) async {
    late final Future<bool?> navigation;
    switch (sectionModel.sectionType) {
      case SectionType.listening:
        navigation = context.push(learnListeningRoute, extra: sectionModel);
        break;
      case SectionType.reading:
        navigation = context.push(learnReadingRoute, extra: sectionModel);
        break;
      case SectionType.speaking:
        navigation = context.push(learnSpeakingRoute, extra: sectionModel);
        break;
      case SectionType.grammar:
        navigation = context.push(learnGrammarRoute, extra: sectionModel);
        break;
      case SectionType.vocabulary:
        navigation = context.push(learnReadingRoute, extra: sectionModel);
        break;
      case SectionType.writing:
        navigation = context.push(learnWritingRoute, extra: sectionModel);
        break;
    }
    final result = await navigation;
    if (!mounted) return;
    if (result == true) {
      shouldRefreshParent = true;
      await loadSections(forceRefresh: true);
    }
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
        if (isLoading)
          const ShimmerList(
              itemCount: 4,
              itemHeight: 110,
              separatorHeight: 12,
              borderRadius: BorderRadius.all(Radius.circular(24)))
        else if (errorMessage != null)
          Center(
              child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  child: Text(errorMessage!,
                      style: Style.bodyw4(context, color: TextColorRole.greyColor))))
        else if (sections.isEmpty)
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
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: () async {
        if (!context.mounted) return false;
        context.pop(shouldRefreshParent ? true : null);
        return false;
      },
      child: Scaffold(
          backgroundColor: context.cs.surface,
          body: SafeArea(child: body(context))));
}
