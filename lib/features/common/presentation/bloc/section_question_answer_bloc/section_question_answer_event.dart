import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_question_model.dart';

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
  final List<String> answerIds;
  final String? userInputText;
  final String? userAudioId;
  final List<SectionBlankAnswer> blankAnswers;
  final String? unitId;
  final String? lessonId;
  final SectionSource source;

  const QuestionAnswerSubmitted(
      {required this.sectionId,
      required this.questionId,
      this.assignmentId,
      this.answerId,
      this.answerIds = const [],
      this.userInputText,
      this.userAudioId,
      this.blankAnswers = const [],
      this.unitId,
      this.lessonId,
      this.source = SectionSource.learn});

  @override
  List<Object?> get props => [
        sectionId,
        questionId,
        assignmentId,
        answerId,
        answerIds,
        userInputText,
        userAudioId,
        blankAnswers,
        unitId,
        lessonId,
        source
      ];
}

class QuestionAnswerReset extends SectionQuestionAnswerEvent {
  const QuestionAnswerReset();
}
