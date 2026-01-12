import 'package:flutter_bloc/flutter_bloc.dart';

class NextTaskState {
  final bool isCurrentTaskCompleted;
  final bool isAnswerCorrect;

  const NextTaskState({this.isCurrentTaskCompleted = false, this.isAnswerCorrect = false});

  NextTaskState copyWith({bool? isCurrentTaskCompleted, bool? isAnswerCorrect}) =>
      NextTaskState(
          isCurrentTaskCompleted: isCurrentTaskCompleted ?? this.isCurrentTaskCompleted,
          isAnswerCorrect: isAnswerCorrect ?? this.isAnswerCorrect);
}

class NextTaskBloc extends Cubit<NextTaskState> {
  NextTaskBloc() : super(const NextTaskState());

  /// --- Methods ---

  void setCurrentTaskCompleted(bool value, {bool isAnswerCorrect = false}) =>
      emit(state.copyWith(isCurrentTaskCompleted: value, isAnswerCorrect: isAnswerCorrect));
}
