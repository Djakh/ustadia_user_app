import 'package:equatable/equatable.dart';

abstract class MockExamListEvent extends Equatable {
  const MockExamListEvent();

  @override
  List<Object?> get props => [];
}

class MockExamListRequested extends MockExamListEvent {
  final int page;
  final int limit;
  final bool showLoading;

  const MockExamListRequested({this.page = 1, this.limit = 10, this.showLoading = true});

  @override
  List<Object?> get props => [page, limit, showLoading];
}

class MockExamListLoadMoreRequested extends MockExamListEvent {
  const MockExamListLoadMoreRequested();
}
