import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class SectionQuestionAnswerEvent extends Equatable {
  const SectionQuestionAnswerEvent();

  @override
  List<Object?> get props => [];
}

class QuestionAnswerSubmitted extends SectionQuestionAnswerEvent {
  final String sectionId;
  final String questionId;
  final String? assignmentId;
  final String? answerId;
  final String? userInputText;
  final String? userAudioId;
  final SectionSource source;

  const QuestionAnswerSubmitted(
      {required this.sectionId,
      required this.questionId,
      this.assignmentId,
      this.answerId,
      this.userInputText,
      this.userAudioId,
      this.source = SectionSource.learn});

  @override
  List<Object?> get props =>
      [sectionId, questionId, assignmentId, answerId, userInputText, userAudioId, source];
}
