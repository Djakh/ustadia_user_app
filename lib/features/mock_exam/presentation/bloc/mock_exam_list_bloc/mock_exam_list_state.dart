import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_model.dart';

class MockExamListState extends Equatable {
  final Status status;
  final List<MockExamModel> exams;
  final PaginationMeta pagination;
  final bool isLoadingMore;
  final String? errorMessage;

  const MockExamListState(
      {this.status = Status.initial,
      this.exams = const [],
      this.pagination = const PaginationMeta(),
      this.isLoadingMore = false,
      this.errorMessage});

  MockExamListState copyWith(
      {Status? status,
      List<MockExamModel>? exams,
      PaginationMeta? pagination,
      bool? isLoadingMore,
      String? errorMessage}) {
    return MockExamListState(
        status: status ?? this.status,
        exams: exams ?? this.exams,
        pagination: pagination ?? this.pagination,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, exams, pagination, isLoadingMore, errorMessage];
}
