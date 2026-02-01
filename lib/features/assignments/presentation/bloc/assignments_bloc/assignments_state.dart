import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_model.dart';

class AssignmentsState {
  final Status status;
  final List<AssignmentModel> assignments;
  final String? errorMessage;

  const AssignmentsState({
    this.status = Status.initial,
    this.assignments = const [],
    this.errorMessage
  });

  AssignmentsState copyWith({
    Status? status,
    List<AssignmentModel>? assignments,
    String? errorMessage
  }) => AssignmentsState(
      status: status ?? this.status,
      assignments: assignments ?? this.assignments,
      errorMessage: errorMessage);
}
