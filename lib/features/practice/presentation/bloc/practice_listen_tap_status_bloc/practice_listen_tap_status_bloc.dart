import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/practice/data/datasources/practice_remote_data_source.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_status_bloc/practice_listen_tap_status_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_listen_tap_status_bloc/practice_listen_tap_status_state.dart';

class PracticeListenTapStatusBloc
    extends Bloc<PracticeListenTapStatusEvent, PracticeListenTapStatusState> {
  final PracticeRemoteDataSource practiceRemoteDataSource;

  PracticeListenTapStatusBloc({required this.practiceRemoteDataSource})
      : super(const PracticeListenTapStatusState()) {
    on<PracticeListenTapStatusRequested>(handleStatusRequested);
  }

  Future<void> handleStatusRequested(
      PracticeListenTapStatusRequested event, Emitter<PracticeListenTapStatusState> emit) async {
    if (state.status == Status.loading) return;
    emit(state.copyWith(
      status: Status.loading,
      errorMessage: null,
      listenTapId: event.listenTapId,
      listenTapStatus: null,
      correctAnswers: null,
      wrongAnswers: null,
      message: null,
    ));
    try {
      final response = await practiceRemoteDataSource.updateListenTapStatus(
        listenTapId: event.listenTapId,
        status: event.status,
      );
      emit(state.copyWith(
        status: Status.success,
        listenTapId: response.listenTapId,
        listenTapStatus: response.status,
        correctAnswers: response.correctAnswers,
        wrongAnswers: response.wrongAnswers,
        message: response.message,
      ));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
