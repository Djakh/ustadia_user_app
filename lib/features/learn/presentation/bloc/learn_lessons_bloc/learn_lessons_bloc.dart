import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_lessons_bloc/learn_lessons_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_lessons_bloc/learn_lessons_state.dart';

class LearnLessonsBloc extends Bloc<LearnLessonsEvent, LearnLessonsState> {
  final LearnRemoteDataSource learnRemoteDataSource;

  LearnLessonsBloc({required this.learnRemoteDataSource}) : super(const LearnLessonsState()) {
    on<LearnLessonsRequested>(handleLessonsRequested);
  }

  Future<void> handleLessonsRequested(
      LearnLessonsRequested event, Emitter<LearnLessonsState> emit) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final lessons =
          await learnRemoteDataSource.fetchLessons(page: event.page, limit: event.limit);
      emit(state.copyWith(status: Status.success, lessons: lessons, errorMessage: null));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }
}
