import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/common/data/repositories/flashcard_repository.dart';
import 'package:ustadia_user_app/features/dashboard/data/services/current_unit_store.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/flashcard_status_bloc/flashcard_status_event.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/flashcard_status_bloc/flashcard_status_state.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';

class FlashcardStatusBloc extends Bloc<FlashcardStatusEvent, FlashcardStatusState> {
  final FlashcardRepository flashcardRepository;
  final ProfileStatisticsStore profileStatisticsStore;
  final CurrentUnitStore currentUnitStore;

  FlashcardStatusBloc(
      {required this.flashcardRepository,
      required this.profileStatisticsStore,
      required this.currentUnitStore})
      : super(const FlashcardStatusState()) {
    on<FlashcardStatusRequested>(handleStatusRequested);
  }

  Future<void> handleStatusRequested(
      FlashcardStatusRequested event, Emitter<FlashcardStatusState> emit) async {
    if (state.status == Status.loading) return;
    emit(state.copyWith(
      status: Status.loading,
      errorMessage: null,
      flashcardId: event.flashcardId,
      back: null,
      cardStatus: null,
      isAnswered: null,
    ));
    try {
      final response = await flashcardRepository.updateFlashcardStatus(
        flashcardId: event.flashcardId,
        status: event.status,
        isPractice: event.isPractice,
      );
      profileStatisticsStore.markStale();
      currentUnitStore.markStale();
      emit(state.copyWith(
        status: Status.success,
        flashcardId: event.flashcardId,
        back: response.back,
        cardStatus: response.status,
        isAnswered: response.isAnswered,
        errorMessage: null,
      ));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
