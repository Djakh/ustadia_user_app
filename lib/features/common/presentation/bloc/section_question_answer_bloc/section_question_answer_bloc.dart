import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/assignments/data/datasources/assignments_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_state.dart';

class QuestionAnswerBloc extends Bloc<SectionQuestionAnswerEvent, QuestionAnswerState> {
  final LearnRemoteDataSource learnRemoteDataSource;
  final AssignmentsRemoteDataSource assignmentsRemoteDataSource;

  QuestionAnswerBloc(
      {required this.learnRemoteDataSource, required this.assignmentsRemoteDataSource})
      : super(const QuestionAnswerState()) {
    on<QuestionAnswerSubmitted>(handleQuestionAnswerSubmitted);
  }

  Future<void> handleQuestionAnswerSubmitted(
      QuestionAnswerSubmitted event, Emitter<QuestionAnswerState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      if (event.source == SectionSource.assignment) {
        final assignmentId = event.assignmentId;
        if (assignmentId == null || assignmentId.isEmpty) {
          emit(state.copyWith(
              status: Status.error, errorMessage: 'Assignment id is missing.'));
          return;
        }
        final Map<String, dynamic> answerItem = {
          'questionId': event.questionId,
        };
        if (event.userInputText != null && event.userInputText!.trim().isNotEmpty) {
          answerItem['answer_text'] = event.userInputText!.trim();
        } else if (event.answerId != null && event.answerId!.isNotEmpty) {
          answerItem['selectedAnswerId'] = event.answerId;
        }
        final success = await assignmentsRemoteDataSource.submitAssignmentAnswers(
            assignmentId: assignmentId, answers: [answerItem]);
        if (success) {
          emit(state.copyWith(status: Status.success, errorMessage: null));
        } else {
          emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
        }
        return;
      }

      final result = await learnRemoteDataSource.submitQuestionAnswer(
          sectionId: event.sectionId,
          questionId: event.questionId,
          answerId: event.answerId,
          userInputText: event.userInputText,
          userAudioId: event.userAudioId);
      emit(state.copyWith(status: Status.success, result: result, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
