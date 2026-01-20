import 'package:equatable/equatable.dart';

abstract class TeacherEvent extends Equatable {
  const TeacherEvent();

  @override
  List<Object?> get props => [];
}

class TeachersRequested extends TeacherEvent {
  const TeachersRequested();
}

class TeacherSwapRequested extends TeacherEvent {
  final String? teacherId;

  const TeacherSwapRequested({required this.teacherId});

  @override
  List<Object?> get props => [teacherId];
}
