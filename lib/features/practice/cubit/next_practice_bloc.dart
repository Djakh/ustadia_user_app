import 'package:flutter_bloc/flutter_bloc.dart';

class NextPracticeState {
  final bool isCurrentTaskCompleted;
  final bool isAnswerCorrect;

  const NextPracticeState({this.isCurrentTaskCompleted = false, this.isAnswerCorrect = false});

  NextPracticeState copyWith({bool? isCurrentTaskCompleted, bool? isAnswerCorrect}) =>
      NextPracticeState(
          isCurrentTaskCompleted: isCurrentTaskCompleted ?? this.isCurrentTaskCompleted,
          isAnswerCorrect: isAnswerCorrect ?? this.isAnswerCorrect);
}

class NextPracticeBloc extends Cubit<NextPracticeState> {
  NextPracticeBloc() : super(const NextPracticeState());

  /// --- Methods ---

  void setCurrentTaskCompleted(bool value, {bool isAnswerCorrect = false}) =>
      emit(state.copyWith(isCurrentTaskCompleted: value, isAnswerCorrect: isAnswerCorrect));
}
