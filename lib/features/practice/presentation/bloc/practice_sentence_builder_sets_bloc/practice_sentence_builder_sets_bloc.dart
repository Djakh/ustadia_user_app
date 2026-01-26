import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/practice/data/datasources/practice_remote_data_source.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_sets_bloc/practice_sentence_builder_sets_event.dart';
import 'package:ustadia_user_app/features/practice/presentation/bloc/practice_sentence_builder_sets_bloc/practice_sentence_builder_sets_state.dart';

class PracticeSentenceBuilderSetsBloc
    extends Bloc<PracticeSentenceBuilderSetsEvent, PracticeSentenceBuilderSetsState> {
  final PracticeRemoteDataSource practiceRemoteDataSource;

  PracticeSentenceBuilderSetsBloc({required this.practiceRemoteDataSource})
      : super(const PracticeSentenceBuilderSetsState()) {
    on<PracticeSentenceBuilderSetsRequested>(handleSetsRequested);
  }

  Future<void> handleSetsRequested(PracticeSentenceBuilderSetsRequested event,
      Emitter<PracticeSentenceBuilderSetsState> emit) async {
    emit(state.copyWith(status: Status.loading, errorMessage: null, sets: const []));
    try {
      final sets = await practiceRemoteDataSource.fetchSentenceBuilderSets();
      emit(state.copyWith(status: Status.success, sets: sets, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
