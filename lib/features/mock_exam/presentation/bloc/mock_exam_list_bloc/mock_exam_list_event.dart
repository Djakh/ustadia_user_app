import 'package:equatable/equatable.dart';

abstract class MockExamListEvent extends Equatable {
  const MockExamListEvent();

  @override
  List<Object?> get props => [];
}

class MockExamListRequested extends MockExamListEvent {
  final int page;
  final int limit;

  const MockExamListRequested({this.page = 1, this.limit = 10});

  @override
  List<Object?> get props => [page, limit];
}

class MockExamListLoadMoreRequested extends MockExamListEvent {
  const MockExamListLoadMoreRequested();
}
