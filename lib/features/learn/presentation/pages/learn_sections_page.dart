import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/tutorial/guided_tutorial_page.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_models.dart';
import 'package:ustadia_user_app/core/tutorial/tutorial_presets.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/listviews/paginated_list_view.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/presentation/pages/flashcard_sprint/flashcard_sprint_page.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_sections_params.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_sections_bloc/learn_sections_bloc.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_sections_bloc/learn_sections_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_sections_bloc/learn_sections_state.dart';
import 'package:ustadia_user_app/features/learn/presentation/widgets/cards/learn_section_card.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class LearnSectionsPage extends StatefulWidget {
  final LearnSectionsParams params;

  const LearnSectionsPage({super.key, required this.params});

  @override
  State<LearnSectionsPage> createState() => LearnSectionsPageState();
}

class LearnSectionsPageState extends State<LearnSectionsPage> {
  final LearnSectionsBloc sectionsBloc = sl<LearnSectionsBloc>();
  final GlobalKey sectionsListKey = GlobalKey(debugLabel: 'learn_sections_list');
  bool shouldRefreshParent = false;

  /// --- Life cycle ---

  @override
  void initState() {
    super.initState();
    if (widget.params.unit.id.isNotEmpty) {
      sectionsBloc.add(LearnSectionsRequested(unitId: widget.params.unit.id));
    }
  }

  @override
  void dispose() => super.dispose();

  /// --- Methods ---

  Future<void> onSectionTap(BuildContext context, SectionModel sectionModel) async {
    if (!context.mounted) return;
    final Future<bool?> navigation;
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
        if (sectionModel.flashCardSet == null &&
            sectionModel.progressState != SectionProgressState.completed) {
          return;
        }
        navigation = context.push(
          flashcardSprintRoute,
          extra: FlashcardSprintParams(
            set: sectionModel.flashCardSet ?? const LearnFlashcardSetModel.empty(),
            sectionModel: sectionModel,
          ),
        );
        break;
      case SectionType.writing:
        navigation = context.push(learnWritingRoute, extra: sectionModel);
        break;
    }
    final result = await navigation;
    if (!context.mounted) return;
    if (result == true) {
      shouldRefreshParent = true;
      sectionsBloc.add(LearnSectionsRequested(unitId: widget.params.unit.id));
    }
  }

  /// --- Widgets ---
  List<SectionModel> sectionsWithLesson(List<SectionModel> sections) => sections
      .map((section) => section.lessonId?.isNotEmpty == true
          ? section
          : section.copyWith(
              unitId: widget.params.unit.id,
              lessonId: widget.params.lessonId,
              questions: section.questions
                  .map((question) => question.copyWith(
                      unitId: widget.params.unit.id, lessonId: widget.params.lessonId))
                  .toList()))
      .toList();

  PaginatedListView<SectionModel> sectionsList(
          BuildContext context, List<SectionModel> sections, LearnSectionsState state) =>
      PaginatedListView(
          items: sectionsWithLesson(sections),
          padding: Style.paddingPrimary,
          separatorHeight: 12,
          onRefresh: () async {
            if (widget.params.unit.id.isNotEmpty) {
              sectionsBloc.add(LearnSectionsRequested(unitId: widget.params.unit.id));
            }
          },
          hasMore: state.pagination.hasNext,
          isLoadingMore: state.isLoadingMore,
          onLoadMore: state.pagination.hasNext
              ? () async {
                  sectionsBloc.add(LearnSectionsLoadMoreRequested(unitId: widget.params.unit.id));
                }
              : null,
          itemBuilder: (item) =>
              LearnSectionCard(sectionModel: item, onTap: () => onSectionTap(context, item)));

  Widget get contentChecker =>
      BlocStatusView<LearnSectionsBloc, LearnSectionsState, List<SectionModel>>(
          bloc: sectionsBloc,
          invalid:
              widget.params.unit.id.isEmpty ? Center(child: Text('Unit not found'.tr())) : null,
          statusOf: (s) => s.status,
          errorOf: (s) => s.errorMessage,
          data: (s) => s.sections,
          isEmpty: (sections) => sections.isEmpty,
          keepDataOnLoading: false,
          empty: Center(child: Text('No sections found'.tr())),
          loading: ShimmerList(
              itemCount: 6,
              itemHeight: 96,
              padding: Style.paddingPrimary,
              borderRadius: Style.border20),
          builder: (context, sections) => KeyedSubtree(
              key: sectionsListKey, child: sectionsList(context, sections, sectionsBloc.state)));

  @override
  Widget build(BuildContext context) => PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !context.mounted) return;
        context.pop(shouldRefreshParent ? true : null);
      },
      child: GuidedTutorialPage(
          pageId: TutorialPageIds.lessonSections,
          steps: TutorialPresets.lessonSections(listKey: sectionsListKey),
          child: Scaffold(
              backgroundColor: context.cs.surface,
              body: PrimaryBackground(
                  title: widget.params.unit.title.isEmpty ? 'Sections' : widget.params.unit.title,
                  isScrollable: false,
                  onBack: () => context.pop(shouldRefreshParent ? true : null),
                  child: contentChecker))));
}
