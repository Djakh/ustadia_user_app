import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_question_answer_result_model.dart';

class QuestionAnswerState extends Equatable {
  final Status status;
  final LearnQuestionAnswerResultModel? result;
  final String? errorMessage;

  const QuestionAnswerState({
    this.status = Status.initial,
    this.result,
    this.errorMessage,
  });

  QuestionAnswerState copyWith({
    Status? status,
    LearnQuestionAnswerResultModel? result,
    String? errorMessage,
    bool clearResult = false,
    bool clearErrorMessage = false,
  }) {
    return QuestionAnswerState(
      status: status ?? this.status,
      result: clearResult ? null : (result ?? this.result),
      errorMessage: clearErrorMessage ? null : errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, result, errorMessage];
}
