import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model.dart';

class LearnSectionsState {
  final Status status;
  final List<LearnSectionModel> sections;
  final PaginationMeta pagination;
  final bool isLoadingMore;
  final String? errorMessage;

  const LearnSectionsState(
      {this.status = Status.initial,
      this.sections = const [],
      this.pagination = const PaginationMeta(),
      this.isLoadingMore = false,
      this.errorMessage});

  LearnSectionsState copyWith(
          {Status? status,
          List<LearnSectionModel>? sections,
          PaginationMeta? pagination,
          bool? isLoadingMore,
          String? errorMessage}) =>
      LearnSectionsState(
          status: status ?? this.status,
          sections: sections ?? this.sections,
          pagination: pagination ?? this.pagination,
          isLoadingMore: isLoadingMore ?? this.isLoadingMore,
          errorMessage: errorMessage);
}
