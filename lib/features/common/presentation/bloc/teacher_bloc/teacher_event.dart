import 'package:equatable/equatable.dart';

abstract class TeacherEvent extends Equatable {
  const TeacherEvent();

  @override
  List<Object?> get props => [];
}

class TeachersRequested extends TeacherEvent {
  const TeachersRequested();
}

class TeachersReset extends TeacherEvent {
  const TeachersReset();
}

class TeacherSwapRequested extends TeacherEvent {
  final String? teacherId;

  const TeacherSwapRequested({required this.teacherId});

  @override
  List<Object?> get props => [teacherId];
}
