import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_question_answer_result_model.dart';

class LearnQuestionAnswerState extends Equatable {
  final Status status;
  final LearnQuestionAnswerResultModel? result;
  final String? errorMessage;

  const LearnQuestionAnswerState({
    this.status = Status.initial,
    this.result,
    this.errorMessage,
  });

  LearnQuestionAnswerState copyWith({
    Status? status,
    LearnQuestionAnswerResultModel? result,
    String? errorMessage,
  }) {
    return LearnQuestionAnswerState(
      status: status ?? this.status,
      result: result ?? this.result,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, result, errorMessage];
}
