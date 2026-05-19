import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/ask_ai/data/datasources/ai_chat_remote_data_source.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';
import 'package:ustadia_user_app/features/ask_ai/data/repositories/auth_repository.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_event.dart';
import 'package:ustadia_user_app/features/ask_ai/presentation/bloc/ask_ai_bloc/ask_ai_state.dart';

class AskAiBloc extends Bloc<AskAiEvent, AskAiState> {
  final AiChatRemoteDataSource aiChatRemoteDataSource;
  final AuthRepository authRepository;

  AskAiBloc({required this.aiChatRemoteDataSource, required this.authRepository})
      : super(const AskAiState()) {
    on<AskAiTopicsRequested>(handleTopicsRequested);
    on<AskAiTopicOpened>(handleTopicOpened);
    on<AskAiMessagesRequested>(handleMessagesRequested);
    on<AskAiMessageReceived>(handleMessageReceived);
  }

  Future<void> handleTopicsRequested(AskAiTopicsRequested event, Emitter<AskAiState> emit) async {
    emit(state.copyWith(topicsStatus: Status.loading, errorMessage: null));
    final authCheck = await ensureAuthValues(emit);
    if (!authCheck) return;
    try {
      final topics = await aiChatRemoteDataSource.fetchTopics(page: 1, limit: 10);
      emit(state.copyWith(topicsStatus: Status.success, topics: topics, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(topicsStatus: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(topicsStatus: Status.error, errorMessage: 'Request failed.'));
    }
  }

  Future<void> handleTopicOpened(AskAiTopicOpened event, Emitter<AskAiState> emit) async {
    emit(state.copyWith(currentTopic: event.topic, messages: const [], errorMessage: null));
    add(AskAiMessagesRequested(topicId: event.topic.id, page: 1, limit: 50));
  }

  Future<void> handleMessagesRequested(
      AskAiMessagesRequested event, Emitter<AskAiState> emit) async {
    if (state.currentTopic?.id.isNotEmpty == true && state.currentTopic!.id != event.topicId) {
      return;
    }
    emit(state.copyWith(messagesStatus: Status.loading, errorMessage: null));
    final authCheck = await ensureAuthValues(emit);
    if (!authCheck) return;
    try {
      final list = await aiChatRemoteDataSource.fetchMessages(
          topicId: event.topicId, page: event.page, limit: event.limit);
      if (state.currentTopic?.id.isNotEmpty == true && state.currentTopic!.id != event.topicId) {
        return;
      }
      final currentTopicMessages =
          state.messages.where((message) => message.topicId == event.topicId).toList();
      final merged = mergeMessages([...currentTopicMessages, ...list]);
      emit(state.copyWith(messagesStatus: Status.success, messages: merged, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(messagesStatus: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(messagesStatus: Status.error, errorMessage: 'Request failed.'));
    }
  }

  Future<void> handleMessageReceived(AskAiMessageReceived event, Emitter<AskAiState> emit) async {
    if (state.currentTopic?.id.isNotEmpty == true &&
        event.message.topicId != state.currentTopic!.id) {
      return;
    }
    final merged = mergeMessages([...state.messages, event.message]);
    emit(state.copyWith(messagesStatus: Status.success, messages: merged, errorMessage: null));
  }

  Future<bool> ensureAuthValues(Emitter<AskAiState> emit) async {
    final token = await authRepository.getJwtToken();
    final userId = await authRepository.getUserId();
    if (token.isEmpty) {
      emit(state.copyWith(
          topicsStatus: Status.error,
          messagesStatus: Status.error,
          errorMessage: 'Unauthorized. Please log in again.'.tr()));
      return false;
    }
    if (state.userId.isEmpty && userId.isNotEmpty) {
      emit(state.copyWith(userId: userId));
    }
    return true;
  }

  List<AiChatMessageModel> mergeMessages(List<AiChatMessageModel> items) {
    final map = <String, AiChatMessageModel>{};
    final semanticMap = <String, AiChatMessageModel>{};
    for (final item in items) {
      map[item.id] = item;
    }
    for (final item in map.values) {
      final semanticKey = messageSemanticKey(item);
      final existing = semanticMap[semanticKey];
      if (existing == null) {
        semanticMap[semanticKey] = item;
        continue;
      }
      semanticMap[semanticKey] = item.copyWith(
          id: item.id.length >= existing.id.length ? item.id : existing.id,
          isFinished: existing.isFinished || item.isFinished);
    }
    final merged = semanticMap.values.toList();
    merged.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return merged;
  }

  String messageSemanticKey(AiChatMessageModel message) {
    final createdAtSecond = message.createdAt.toUtc().millisecondsSinceEpoch ~/ 1000;
    final normalizedContent = message.content.trim();
    return '${message.topicId}|${message.userId}|${message.role}|$createdAtSecond|$normalizedContent';
  }
}
