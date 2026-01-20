import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_question_answer_bloc/learn_question_answer_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_question_answer_bloc/learn_question_answer_state.dart';

class LearnQuestionAnswerBloc
    extends Bloc<LearnQuestionAnswerEvent, LearnQuestionAnswerState> {
  final LearnRemoteDataSource learnRemoteDataSource;

  LearnQuestionAnswerBloc({required this.learnRemoteDataSource})
      : super(const LearnQuestionAnswerState()) {
    on<LearnQuestionAnswerSubmitted>(handleQuestionAnswerSubmitted);
  }

  Future<void> handleQuestionAnswerSubmitted(
      LearnQuestionAnswerSubmitted event, Emitter<LearnQuestionAnswerState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final result = await learnRemoteDataSource.submitQuestionAnswer(
        sectionId: event.sectionId,
        questionId: event.questionId,
        answerId: event.answerId,
        userInputText: event.userInputText,
        userAudioId: event.userAudioId,
      );
      emit(state.copyWith(status: Status.success, result: result, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
