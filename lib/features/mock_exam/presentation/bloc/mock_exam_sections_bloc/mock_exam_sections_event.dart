import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_model.dart';

abstract class MockExamSectionsEvent extends Equatable {
  const MockExamSectionsEvent();

  @override
  List<Object?> get props => [];
}

class MockExamSectionsRequested extends MockExamSectionsEvent {
  final String mockExamId;
  final MockExamModel? exam;
  final bool showLoading;

  const MockExamSectionsRequested({required this.mockExamId, this.exam, this.showLoading = true});

  @override
  List<Object?> get props => [mockExamId, exam, showLoading];
}

class MockExamFinishRequested extends MockExamSectionsEvent {
  final String mockExamId;
  final String attemptId;

  const MockExamFinishRequested({required this.mockExamId, required this.attemptId});

  @override
  List<Object?> get props => [mockExamId, attemptId];
}
