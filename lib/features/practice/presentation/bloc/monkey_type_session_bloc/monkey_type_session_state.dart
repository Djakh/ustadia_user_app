import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/practice/data/models/monkey_type_model.dart';

class MonkeyTypeSessionState extends Equatable {
  final Status status;
  final MonkeyTypePracticeModel? practice;
  final List<MonkeyTypeTextModel> texts;
  final String? errorMessage;
  final Status submitStatus;
  final MonkeyTypeAnswerModel? answer;
  final String? submitErrorMessage;

  const MonkeyTypeSessionState({
    this.status = Status.initial,
    this.practice,
    this.texts = const [],
    this.errorMessage,
    this.submitStatus = Status.initial,
    this.answer,
    this.submitErrorMessage,
  });

  MonkeyTypeSessionState copyWith({
    Status? status,
    MonkeyTypePracticeModel? practice,
    List<MonkeyTypeTextModel>? texts,
    String? errorMessage,
    Status? submitStatus,
    MonkeyTypeAnswerModel? answer,
    String? submitErrorMessage,
  }) =>
      MonkeyTypeSessionState(
        status: status ?? this.status,
        practice: practice ?? this.practice,
        texts: texts ?? this.texts,
        errorMessage: errorMessage,
        submitStatus: submitStatus ?? this.submitStatus,
        answer: answer ?? this.answer,
        submitErrorMessage: submitErrorMessage,
      );

  @override
  List<Object?> get props =>
      [status, practice, texts, errorMessage, submitStatus, answer, submitErrorMessage];
}
