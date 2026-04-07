import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/assignments/data/datasources/assignments_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/dashboard/data/services/current_unit_store.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_question_answer_result_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/section_question_answer_bloc/section_question_answer_state.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';

class QuestionAnswerBloc extends Bloc<SectionQuestionAnswerEvent, QuestionAnswerState> {
  final LearnRemoteDataSource learnRemoteDataSource;
  final AssignmentsRemoteDataSource assignmentsRemoteDataSource;
  final ProfileStatisticsStore profileStatisticsStore;
  final CurrentUnitStore currentUnitStore;

  QuestionAnswerBloc(
      {required this.learnRemoteDataSource,
      required this.assignmentsRemoteDataSource,
      required this.profileStatisticsStore,
      required this.currentUnitStore})
      : super(const QuestionAnswerState()) {
    on<QuestionAnswerSubmitted>(handleQuestionAnswerSubmitted);
    on<QuestionAnswerReset>(handleQuestionAnswerReset);
  }

  void handleQuestionAnswerReset(QuestionAnswerReset event, Emitter<QuestionAnswerState> emit) {
    emit(const QuestionAnswerState());
  }

  Future<void> handleQuestionAnswerSubmitted(
      QuestionAnswerSubmitted event, Emitter<QuestionAnswerState> emit) async {
    emit(state.copyWith(
      status: Status.loading,
      clearResult: true,
      clearErrorMessage: true,
    ));
    try {
      if (event.source == SectionSource.assignment) {
        final assignmentId = event.assignmentId;
        if (assignmentId == null || assignmentId.isEmpty) {
          emit(state.copyWith(
            status: Status.error,
            errorMessage: 'Assignment id is missing.',
            clearResult: true,
          ));
          return;
        }
        final answersPayload = buildAssignmentAnswersPayload(event);
        final response = await assignmentsRemoteDataSource.submitAssignmentAnswers(
            assignmentId: assignmentId, answers: answersPayload);
        final extracted = _extractLearnResult(response, event.questionId);
        final hasResults = response['results'] is List;
        if (hasResults || extracted != null) {
          markDerivedDataStale();
          if (extracted != null && extracted.success == false) {
            emit(state.copyWith(
              status: Status.error,
              result: extracted,
              errorMessage: extracted.error ?? 'Request failed.',
            ));
          } else {
            emit(state.copyWith(
              status: Status.success,
              result: extracted,
              clearErrorMessage: true,
            ));
          }
        } else {
          emit(state.copyWith(
            status: Status.error,
            errorMessage: 'Request failed.',
            clearResult: true,
          ));
        }
        return;
      }

      final unitId = event.unitId;
      final lessonId = event.lessonId;
      if (unitId == null || unitId.isEmpty || lessonId == null || lessonId.isEmpty) {
        emit(state.copyWith(
          status: Status.error,
          errorMessage: 'Lesson or unit id is missing.',
          clearResult: true,
        ));
        return;
      }
      final answersPayload = buildLessonAnswersPayload(event);
      final response = await learnRemoteDataSource.submitLessonAnswers(
          lessonId: lessonId, unitId: unitId, answers: answersPayload);
      markDerivedDataStale();
      final extracted = _extractLearnResult(response, event.questionId);
      emit(state.copyWith(
        status: Status.success,
        result: extracted,
        clearErrorMessage: true,
      ));
    } on DioException catch (error) {
      emit(state.copyWith(
        status: Status.error,
        errorMessage: DioErrorMessage.from(error),
        clearResult: true,
      ));
    } catch (_) {
      emit(state.copyWith(
        status: Status.error,
        errorMessage: 'Request failed.',
        clearResult: true,
      ));
    }
  }

  void markDerivedDataStale() {
    profileStatisticsStore.markStale();
    currentUnitStore.markStale();
  }

  List<Map<String, dynamic>> buildLessonAnswersPayload(QuestionAnswerSubmitted event) {
    final answers = <Map<String, dynamic>>[];
    final blankAnswers = event.blankAnswers
        .map((item) => {'position': item.position, 'answer': item.answer ?? ''})
        .toList();
    if (blankAnswers.isNotEmpty) {
      answers.add({'questionId': event.questionId, 'blank_answers': blankAnswers});
      return answers;
    }
    if (event.answerIds.isNotEmpty) {
      for (final answerId in event.answerIds) {
        answers.add({'questionId': event.questionId, 'answer_id': answerId});
      }
      return answers;
    }
    if (event.answerId != null && event.answerId!.isNotEmpty) {
      answers.add({'questionId': event.questionId, 'answer_id': event.answerId});
      return answers;
    }
    final payload = <String, dynamic>{'questionId': event.questionId};
    if (event.userInputText != null && event.userInputText!.trim().isNotEmpty) {
      payload['user_input_text'] = event.userInputText!.trim();
    }
    if (event.userAudioId != null && event.userAudioId!.trim().isNotEmpty) {
      payload['user_audio_id'] = event.userAudioId!.trim();
    }
    answers.add(payload);
    return answers;
  }

  List<Map<String, dynamic>> buildAssignmentAnswersPayload(QuestionAnswerSubmitted event) {
    final answers = <Map<String, dynamic>>[];
    final blankAnswers = event.blankAnswers
        .map((item) => {'position': item.position, 'answer': item.answer ?? ''})
        .toList();
    if (blankAnswers.isNotEmpty) {
      answers.add({'questionId': event.questionId, 'blank_answers': blankAnswers});
      return answers;
    }
    if (event.answerIds.isNotEmpty) {
      for (final answerId in event.answerIds) {
        answers.add({'questionId': event.questionId, 'selectedAnswerId': answerId});
      }
      return answers;
    }
    if (event.answerId != null && event.answerId!.isNotEmpty) {
      answers.add({'questionId': event.questionId, 'selectedAnswerId': event.answerId});
      return answers;
    }
    final payload = <String, dynamic>{'questionId': event.questionId};
    if (event.userInputText != null && event.userInputText!.trim().isNotEmpty) {
      payload['answer_text'] = event.userInputText!.trim();
    }
    if (event.userAudioId != null && event.userAudioId!.trim().isNotEmpty) {
      payload['user_audio_id'] = event.userAudioId!.trim();
    }
    answers.add(payload);
    return answers;
  }

  LearnQuestionAnswerResultModel? _extractLearnResult(
      Map<String, dynamic> response, String questionId) {
    final direct = _asMap(response['data']) ?? _asMap(response['result']);
    if (direct != null) {
      return LearnQuestionAnswerResultModel.fromJson(direct);
    }
    final results = response['results'];
    if (results is List) {
      final parsedResults = results
          .map(_asMap)
          .whereType<Map<String, dynamic>>()
          .map(LearnQuestionAnswerResultModel.fromJson)
          .toList();
      for (final result in parsedResults) {
        if (result.questionId == questionId) return result;
      }
      if (parsedResults.isNotEmpty) return parsedResults.first;
    }
    if (response.containsKey('question_id') || response.containsKey('is_correct')) {
      return LearnQuestionAnswerResultModel.fromJson(response);
    }
    final items = response['data'];
    if (items is List) {
      for (final item in items) {
        final map = _asMap(item);
        if (map != null) return LearnQuestionAnswerResultModel.fromJson(map);
      }
    }
    return null;
  }

  Map<String, dynamic>? _asMap(dynamic value) => value is Map<String, dynamic> ? value : null;
}
