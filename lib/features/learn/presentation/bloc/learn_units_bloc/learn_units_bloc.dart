import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_units_bloc/learn_units_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/learn_units_bloc/learn_units_state.dart';

class LearnUnitsBloc extends Bloc<LearnUnitsEvent, LearnUnitsState> {
  final LearnRemoteDataSource learnRemoteDataSource;

  LearnUnitsBloc({required this.learnRemoteDataSource}) : super(const LearnUnitsState()) {
    on<LearnUnitsRequested>(handleUnitsRequested);
  }

  Future<void> handleUnitsRequested(
      LearnUnitsRequested event, Emitter<LearnUnitsState> emit) async {
    emit(state.copyWith(status: Status.loading, lessonId: event.lessonId));
    try {
      final units = await learnRemoteDataSource.fetchUnits(
          lessonId: event.lessonId, page: event.page, limit: event.limit);
      emit(state.copyWith(
          status: Status.success, units: units, errorMessage: null, lessonId: event.lessonId));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }
}
