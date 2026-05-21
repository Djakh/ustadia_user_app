import 'package:equatable/equatable.dart';

abstract class StudentMeetsEvent extends Equatable {
  const StudentMeetsEvent();

  @override
  List<Object?> get props => [];
}

class StudentMeetsRequested extends StudentMeetsEvent {
  final int page;
  final int limit;
  final bool showLoading;

  const StudentMeetsRequested({this.page = 1, this.limit = 10, this.showLoading = true});

  @override
  List<Object?> get props => [page, limit, showLoading];
}

class StudentMeetsLoadMoreRequested extends StudentMeetsEvent {
  const StudentMeetsLoadMoreRequested();
}
