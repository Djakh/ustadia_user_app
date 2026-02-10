import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class LearnSectionsState {
  final Status status;
  final List<SectionModel> sections;
  final PaginationMeta pagination;
  final bool isLoadingMore;
  final String? errorMessage;
  final String? unitId;

  const LearnSectionsState(
      {this.status = Status.initial,
      this.sections = const [],
      this.pagination = const PaginationMeta(),
      this.isLoadingMore = false,
      this.errorMessage,
      this.unitId});

  LearnSectionsState copyWith(
          {Status? status,
          List<SectionModel>? sections,
          PaginationMeta? pagination,
          bool? isLoadingMore,
          String? errorMessage,
          String? unitId}) =>
      LearnSectionsState(
          status: status ?? this.status,
          sections: sections ?? this.sections,
          pagination: pagination ?? this.pagination,
          isLoadingMore: isLoadingMore ?? this.isLoadingMore,
          errorMessage: errorMessage,
          unitId: unitId ?? this.unitId);
}
