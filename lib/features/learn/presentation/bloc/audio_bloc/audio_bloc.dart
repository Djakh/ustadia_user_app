import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/learn/data/repositories/audio_repository.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/audio_bloc/audio_event.dart';
import 'package:ustadia_user_app/features/learn/presentation/bloc/audio_bloc/audio_state.dart';

class AudioBloc extends Bloc<AudioEvent, AudioState> {
  final AudioRepository audioRepository;

  AudioBloc({required this.audioRepository}) : super(const AudioState()) {
    on<AudioRequested>(handleAudioRequested);
  }

  Future<void> handleAudioRequested(AudioRequested event, Emitter<AudioState> emit) async {
    if (state.status == Status.loading) return;
    emit(state.copyWith(status: Status.loading, errorMessage: null));
    try {
      final filePath = await audioRepository.downloadAudio(event.url);
      emit(state.copyWith(status: Status.success, filePath: filePath, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (_) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }
}
