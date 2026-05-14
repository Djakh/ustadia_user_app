import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_attempt_model.dart';

class MockExamSectionsState extends Equatable {
  final Status status;
  final Status actionStatus;
  final String title;
  final String description;
  final List<SectionModel> sections;
  final MockExamAttemptModel? attempt;
  final MockExamResultModel? result;
  final String? errorMessage;

  const MockExamSectionsState(
      {this.status = Status.initial,
      this.actionStatus = Status.initial,
      this.title = '',
      this.description = '',
      this.sections = const [],
      this.attempt,
      this.result,
      this.errorMessage});

  MockExamSectionsState copyWith(
      {Status? status,
      Status? actionStatus,
      String? title,
      String? description,
      List<SectionModel>? sections,
      MockExamAttemptModel? attempt,
      MockExamResultModel? result,
      String? errorMessage}) {
    return MockExamSectionsState(
        status: status ?? this.status,
        actionStatus: actionStatus ?? this.actionStatus,
        title: title ?? this.title,
        description: description ?? this.description,
        sections: sections ?? this.sections,
        attempt: attempt ?? this.attempt,
        result: result ?? this.result,
        errorMessage: errorMessage);
  }

  @override
  List<Object?> get props =>
      [status, actionStatus, title, description, sections, attempt, result, errorMessage];
}
