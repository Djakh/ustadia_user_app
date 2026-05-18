import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/practice/data/datasources/practice_remote_data_source.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_practices_bloc/monkey_type_practices_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/monkey_type_practices_bloc/monkey_type_practices_state.dart';

class MonkeyTypePracticesBloc extends Bloc<MonkeyTypePracticesEvent, MonkeyTypePracticesState> {
  final PracticeRemoteDataSource practiceRemoteDataSource;

  MonkeyTypePracticesBloc({required this.practiceRemoteDataSource})
      : super(const MonkeyTypePracticesState()) {
    on<MonkeyTypePracticesRequested>(handlePracticesRequested);
  }

  Future<void> handlePracticesRequested(
      MonkeyTypePracticesRequested event, Emitter<MonkeyTypePracticesState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null, practices: const []));
    try {
      final practices = await practiceRemoteDataSource.fetchMonkeyTypePractices();
      emit(state.copyWith(status: Status.success, practices: practices, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
