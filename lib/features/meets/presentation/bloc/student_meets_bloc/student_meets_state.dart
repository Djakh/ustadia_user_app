import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/features/meets/data/models/student_meet_model.dart';

class StudentMeetsState extends Equatable {
  final Status status;
  final List<StudentMeetModel> meets;
  final PaginationMeta pagination;
  final bool isLoadingMore;
  final String? errorMessage;

  const StudentMeetsState({
    this.status = Status.initial,
    this.meets = const [],
    this.pagination = const PaginationMeta(),
    this.isLoadingMore = false,
    this.errorMessage,
  });

  List<StudentMeetModel> actualMeets(DateTime now) =>
      meets.where((meet) => meet.isActual(now)).toList()
        ..sort((a, b) => (a.scheduledAt ?? DateTime(0)).compareTo(b.scheduledAt ?? DateTime(0)));

  List<StudentMeetModel> historyMeets(DateTime now) =>
      meets.where((meet) => !meet.isActual(now)).toList()
        ..sort((a, b) => (b.scheduledAt ?? DateTime(0)).compareTo(a.scheduledAt ?? DateTime(0)));

  StudentMeetsState copyWith({
    Status? status,
    List<StudentMeetModel>? meets,
    PaginationMeta? pagination,
    bool? isLoadingMore,
    String? errorMessage,
  }) {
    return StudentMeetsState(
        status: status ?? this.status,
        meets: meets ?? this.meets,
        pagination: pagination ?? this.pagination,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, meets, pagination, isLoadingMore, errorMessage];
}
