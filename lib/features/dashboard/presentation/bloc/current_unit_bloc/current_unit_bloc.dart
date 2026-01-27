import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/bloc/current_unit_bloc/current_unit_event.dart';
import 'package:ustadia_user_app/features/dashboard/presentation/bloc/current_unit_bloc/current_unit_state.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';

class CurrentUnitBloc extends Bloc<CurrentUnitEvent, CurrentUnitState> {
  final LearnRemoteDataSource learnRemoteDataSource;

  CurrentUnitBloc({required this.learnRemoteDataSource}) : super(const CurrentUnitState()) {
    on<CurrentUnitRequested>(handleCurrentUnitRequested);
  }

  Future<void> handleCurrentUnitRequested(
      CurrentUnitRequested event, Emitter<CurrentUnitState> emit) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final unit = await learnRemoteDataSource.fetchCurrentUnit();
      emit(state.copyWith(status: Status.success, unit: unit, errorMessage: null));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: error.toString()));
    }
  }
}
