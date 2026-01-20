import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_lesson_model.dart';

class LearnLessonsState {
  final Status status;
  final List<LearnLessonModel> lessons;
  final String? errorMessage;

  const LearnLessonsState({
    this.status = Status.initial,
    this.lessons = const [],
    this.errorMessage
  });

  LearnLessonsState copyWith({Status? status, List<LearnLessonModel>? lessons, String? errorMessage}) =>
      LearnLessonsState(
          status: status ?? this.status,
          lessons: lessons ?? this.lessons,
          errorMessage: errorMessage);
}
