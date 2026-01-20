import 'package:equatable/equatable.dart';

class LearnQuestionAnswerEvent extends Equatable {
  const LearnQuestionAnswerEvent();

  @override
  List<Object?> get props => [];
}

class LearnQuestionAnswerSubmitted extends LearnQuestionAnswerEvent {
  final String sectionId;
  final String questionId;
  final String? answerId;
  final String? userInputText;
  final String? userAudioId;

  const LearnQuestionAnswerSubmitted({
    required this.sectionId,
    required this.questionId,
    this.answerId,
    this.userInputText,
    this.userAudioId,
  });

  @override
  List<Object?> get props => [sectionId, questionId, answerId, userInputText, userAudioId];
}
