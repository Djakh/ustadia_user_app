import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/practice/data/datasources/practice_remote_data_source.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_sets_bloc/practice_listen_tap_sets_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_sets_bloc/practice_listen_tap_sets_state.dart';

class PracticeListenTapSetsBloc
    extends Bloc<PracticeListenTapSetsEvent, PracticeListenTapSetsState> {
  final PracticeRemoteDataSource practiceRemoteDataSource;

  PracticeListenTapSetsBloc({required this.practiceRemoteDataSource})
      : super(const PracticeListenTapSetsState()) {
    on<PracticeListenTapSetsRequested>(handleSetsRequested);
  }

  Future<void> handleSetsRequested(
      PracticeListenTapSetsRequested event, Emitter<PracticeListenTapSetsState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null, sets: const []));
    try {
      final sets = await practiceRemoteDataSource.fetchListenTapSets();
      emit(state.copyWith(status: Status.success, sets: sets, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
