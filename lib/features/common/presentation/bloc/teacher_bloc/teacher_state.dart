import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/common/data/models/teacher_model.dart';

class TeacherState extends Equatable {
  final Status status;
  final List<TeacherModel> teachers;
  final String? errorMessage;
  final Status swapStatus;
  final String? swapErrorMessage;
  final String? swapMessage;
  final String? swappingTeacherId;

  const TeacherState({
    this.status = Status.initial,
    this.teachers = const [],
    this.errorMessage,
    this.swapStatus = Status.initial,
    this.swapErrorMessage,
    this.swapMessage,
    this.swappingTeacherId,
  });

  TeacherState copyWith({
    Status? status,
    List<TeacherModel>? teachers,
    String? errorMessage,
    Status? swapStatus,
    String? swapErrorMessage,
    String? swapMessage,
    String? swappingTeacherId,
  }) {
    return TeacherState(
      status: status ?? this.status,
      teachers: teachers ?? this.teachers,
      errorMessage: errorMessage,
      swapStatus: swapStatus ?? this.swapStatus,
      swapErrorMessage: swapErrorMessage,
      swapMessage: swapMessage,
      swappingTeacherId: swappingTeacherId,
    );
  }

  @override
  List<Object?> get props => [
        status,
        teachers,
        errorMessage,
        swapStatus,
        swapErrorMessage,
        swapMessage,
        swappingTeacherId
      ];
}
