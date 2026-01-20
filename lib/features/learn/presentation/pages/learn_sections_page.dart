import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/listviews/paginated_list_view.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_sections_bloc/learn_sections_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_sections_bloc/learn_sections_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_sections_bloc/learn_sections_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/learn_section_card.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class LearnSectionsPage extends StatefulWidget {
  final LearnUnitModel unit;

  const LearnSectionsPage({super.key, required this.unit});

  @override
  State<LearnSectionsPage> createState() => LearnSectionsPageState();
}

class LearnSectionsPageState extends State<LearnSectionsPage> {
  final LearnSectionsBloc sectionsBloc = sl<LearnSectionsBloc>();
  bool shouldRefreshParent = false;

  /// --- Life cycle ---
 
  @override
  void initState() {
    super.initState();
    if (widget.unit.id.isNotEmpty) {
      sectionsBloc.add(LearnSectionsRequested(unitId: widget.unit.id));
    }
  }

  @override
  void dispose() {
    sectionsBloc.close();
    super.dispose();
  }

  /// --- Methods ---

  Future<void> onSectionTap(BuildContext context, LearnSectionModel sectionModel) async {
    if (!context.mounted) return;
    final Future<bool?> navigation;
    switch (sectionModel.sectionType) {
      case LearnSectionType.listening:
        navigation = context.push(learnListeningRoute, extra: sectionModel);
        break;
      case LearnSectionType.reading:
        navigation = context.push(learnReadingRoute, extra: sectionModel);
        break;
      case LearnSectionType.speaking:
        navigation = context.push(learnSpeakingRoute, extra: sectionModel);
        break;
      case LearnSectionType.grammar:
        navigation = context.push(learnGrammarRoute, extra: sectionModel);
        break;
      case LearnSectionType.vocabulary:
        if (sectionModel.flashCardSet == null) return;
        navigation = context.push(flashcardSprintRoute, extra: sectionModel.flashCardSet!);
        break;
      case LearnSectionType.writing:
        navigation = context.push(learnWritingRoute, extra: sectionModel);
        break;
    }
    final result = await navigation;
    if (!context.mounted) return;
    if (result == true) {
      shouldRefreshParent = true;
      sectionsBloc.add(LearnSectionsRequested(unitId: widget.unit.id));
    }
  }

  /// --- Widgets ---
  PaginatedListView<LearnSectionModel> sectionsList(
          BuildContext context, List<LearnSectionModel> sections, LearnSectionsState state) =>
      PaginatedListView(
          items: sections,
          padding: Style.paddingPrimary,
          separatorHeight: 12,
          hasMore: state.pagination.hasNext,
          isLoadingMore: state.isLoadingMore,
          onLoadMore: state.pagination.hasNext
              ? () async {
                  sectionsBloc.add(LearnSectionsLoadMoreRequested(unitId: widget.unit.id));
                }
              : null,
          itemBuilder: (item) =>
              LearnSectionCard(sectionModel: item, onTap: () => onSectionTap(context, item)));

  Widget get contentChecker =>
      BlocStatusView<LearnSectionsBloc, LearnSectionsState, List<LearnSectionModel>>(
          bloc: sectionsBloc,
          invalid: widget.unit.id.isEmpty ? const Center(child: Text('Unit not found')) : null,
          statusOf: (s) => s.status,
          errorOf: (s) => s.errorMessage,
          data: (s) => s.sections,
          isEmpty: (sections) => sections.isEmpty,
          empty: const Center(child: Text('No sections found')),
          builder: (context, sections) => sectionsList(context, sections, sectionsBloc.state));

  @override
  Widget build(BuildContext context) => WillPopScope(
      onWillPop: () async {
        if (!context.mounted) return false;
        context.pop(shouldRefreshParent ? true : null);
        return false;
      },
      child: Scaffold(
          backgroundColor: context.cs.surface,
          body: PrimaryBackground(
              title: widget.unit.title.isEmpty ? 'Sections' : widget.unit.title,
              isScrollable: false,
              onBack: () => context.pop(shouldRefreshParent ? true : null),
              child: contentChecker)));
}
