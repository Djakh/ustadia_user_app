import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
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

  Room? room;
  EventsListener<RoomEvent>? livekitListener;

  AskAiBloc({required this.aiChatRemoteDataSource, required this.authRepository})
      : super(const AskAiState()) {
    on<AskAiTopicsRequested>(handleTopicsRequested);
    on<AskAiTopicOpened>(handleTopicOpened);
    on<AskAiMessagesRequested>(handleMessagesRequested);
    on<AskAiVoiceConnectRequested>(handleVoiceConnectRequested);
    on<AskAiVoiceDisconnectRequested>(handleVoiceDisconnectRequested);
    on<AskAiVoiceMicToggled>(handleVoiceMicToggled);
    on<AskAiVoiceSpeakerToggled>(handleVoiceSpeakerToggled);
    on<AskAiRoomUpdated>(handleRoomUpdated);
    on<AskAiLivekitEventReported>(handleLivekitEventReported);
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
    emit(state.copyWith(messagesStatus: Status.loading, errorMessage: null));
    final authCheck = await ensureAuthValues(emit);
    if (!authCheck) return;
    try {
      final list = await aiChatRemoteDataSource.fetchMessages(
          topicId: event.topicId, page: event.page, limit: event.limit);
      final merged = mergeMessages([...state.messages, ...list]);
      emit(state.copyWith(messagesStatus: Status.success, messages: merged, errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(messagesStatus: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(messagesStatus: Status.error, errorMessage: 'Request failed.'));
    }
  }

  Future<void> handleVoiceConnectRequested(
      AskAiVoiceConnectRequested event, Emitter<AskAiState> emit) async {
    final topic = state.currentTopic;
    if (topic == null) return;
    emit(state.copyWith(voiceStatus: Status.loading, errorMessage: null));
    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      if (permissionStatus.isPermanentlyDenied) {
        await openAppSettings();
      }
      emit(state.copyWith(
          voiceStatus: Status.error, errorMessage: 'Microphone permission denied'.tr()));
      return;
    }
    final authCheck = await ensureAuthValues(emit);
    if (!authCheck) return;
    try {
      final tokenModel = await aiChatRemoteDataSource.fetchLivekitToken(topicId: topic.id);
      final nextRoom = room ??
          Room(
              roomOptions: const RoomOptions(
                  adaptiveStream: true,
                  dynacast: true,
                  defaultAudioOutputOptions: AudioOutputOptions(speakerOn: true)));
      listenToRoomEvents(nextRoom);
      await nextRoom.connect(tokenModel.url, tokenModel.token);
      await nextRoom.localParticipant?.setMicrophoneEnabled(true);
      await nextRoom.setSpeakerOn(true, forceSpeakerOutput: true);
      room = nextRoom;
      emit(state.copyWith(
          voiceStatus: Status.success,
          micEnabled: true,
          speakerEnabled: true,
          connectionState: roomConnectionState(room),
          participantsCount: roomParticipantsCount(room),
          agentConnected: agentConnectedValue(room),
          agentAudioActive: agentAudioActiveValue(room)));
      add(AskAiMessagesRequested(topicId: topic.id, page: 1, limit: 50));
    } on DioException catch (error) {
      emit(state.copyWith(voiceStatus: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(voiceStatus: Status.error, errorMessage: 'Request failed.'));
    }
  }

  Future<void> handleVoiceDisconnectRequested(
      AskAiVoiceDisconnectRequested event, Emitter<AskAiState> emit) async {
    if (room == null) return;
    try {
      await room!.disconnect();
    } finally {
      if (livekitListener != null) livekitListener!.dispose();
      livekitListener = null;
      room = null;
      emit(state.copyWith(
          voiceStatus: Status.initial,
          micEnabled: false,
          speakerEnabled: false,
          connectionState: 'disconnected',
          participantsCount: 0,
          agentConnected: false,
          agentAudioActive: false,
          lastLivekitEvent: ''));
    }
  }

  Future<void> handleVoiceMicToggled(AskAiVoiceMicToggled event, Emitter<AskAiState> emit) async {
    if (room == null) return;
    final next = !state.micEnabled;
    await room!.localParticipant?.setMicrophoneEnabled(next);
    emit(state.copyWith(micEnabled: next));
  }

  Future<void> handleVoiceSpeakerToggled(
      AskAiVoiceSpeakerToggled event, Emitter<AskAiState> emit) async {
    if (room == null) return;
    final next = !state.speakerEnabled;
    await room!.setSpeakerOn(next, forceSpeakerOutput: true);
    emit(state.copyWith(speakerEnabled: next));
  }

  Future<void> handleRoomUpdated(AskAiRoomUpdated event, Emitter<AskAiState> emit) async {
    emit(state.copyWith(
        connectionState: roomConnectionState(room),
        participantsCount: roomParticipantsCount(room),
        agentConnected: agentConnectedValue(room),
        agentAudioActive: agentAudioActiveValue(room)));
  }

  Future<void> handleLivekitEventReported(
      AskAiLivekitEventReported event, Emitter<AskAiState> emit) async {
    emit(state.copyWith(
        lastLivekitEvent: event.lastLivekitEvent,
        agentConnected: event.agentConnected ?? state.agentConnected,
        agentAudioActive: event.agentAudioActive ?? state.agentAudioActive));
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
          voiceStatus: Status.error,
          errorMessage: 'Unauthorized. Please log in again.'.tr()));
      return false;
    }
    if (state.userId.isEmpty && userId.isNotEmpty) {
      emit(state.copyWith(userId: userId));
    }
    return true;
  }

  String roomConnectionState(Room? roomValue) {
    if (roomValue == null) return 'disconnected';
    return roomValue.connectionState.name;
  }

  int roomParticipantsCount(Room? roomValue) {
    if (roomValue == null) return 0;
    return roomValue.remoteParticipants.length + 1;
  }

  bool agentConnectedValue(Room? roomValue) {
    if (roomValue == null) return false;
    if (roomValue.remoteParticipants.isNotEmpty) return true;
    return false;
  }

  bool agentAudioActiveValue(Room? roomValue) {
    if (roomValue == null) return false;
    for (final participant in roomValue.remoteParticipants.values) {
      for (final entry in participant.trackPublications.entries) {
        final publication = entry.value;
        if (publication.kind != TrackType.AUDIO) continue;
        final track = publication.track;
        if (track is RemoteAudioTrack) return true;
      }
    }
    return false;
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

  void listenToRoomEvents(Room nextRoom) {
    livekitListener?.dispose();
    livekitListener = nextRoom.createListener();
    livekitListener!.on<RoomConnectedEvent>((event) {
      debugPrint('[LiveKit] room connected');
      add(const AskAiRoomUpdated());
      add(const AskAiLivekitEventReported(lastLivekitEvent: 'Room connected'));
    });
    livekitListener!.on<RoomDisconnectedEvent>((event) {
      debugPrint('[LiveKit] room disconnected');
      add(const AskAiRoomUpdated());
      add(const AskAiLivekitEventReported(lastLivekitEvent: 'Room disconnected'));
    });
    livekitListener!.on<ParticipantConnectedEvent>((event) {
      debugPrint('[LiveKit] participant joined: ${event.participant.identity}');
      add(const AskAiRoomUpdated());
      add(AskAiLivekitEventReported(
          lastLivekitEvent: 'Participant joined: ${event.participant.identity}',
          agentConnected: true));
    });
    livekitListener!.on<ParticipantDisconnectedEvent>((event) {
      debugPrint('[LiveKit] participant left: ${event.participant.identity}');
      add(const AskAiRoomUpdated());
      add(AskAiLivekitEventReported(
          lastLivekitEvent: 'Participant left: ${event.participant.identity}'));
    });
    livekitListener!.on<TrackPublishedEvent>((event) {
      debugPrint(
          '[LiveKit] track published: ${event.publication.sid} ${event.publication.kind.name}');
      add(const AskAiRoomUpdated());
      add(AskAiLivekitEventReported(
          lastLivekitEvent:
              'Track published: ${event.publication.sid} ${event.publication.kind.name}',
          agentConnected: true));
    });
    livekitListener!.on<TrackUnpublishedEvent>((event) {
      debugPrint(
          '[LiveKit] track unpublished: ${event.publication.sid} ${event.publication.kind.name}');
      add(const AskAiRoomUpdated());
      add(AskAiLivekitEventReported(
          lastLivekitEvent:
              'Track unpublished: ${event.publication.sid} ${event.publication.kind.name}'));
    });
    livekitListener!.on<TrackSubscribedEvent>((event) async {
      final track = event.track;
      final publication = event.publication;
      final isAudio = track is RemoteAudioTrack;
      debugPrint(
          '[LiveKit] track subscribed: kind=${publication.kind.name} participant=${event.participant.identity}');
      if (isAudio) {
        debugPrint('🔥 AGENT AUDIO TRACK RECEIVED from ${event.participant.identity}');
        await track.start();
        debugPrint('[LiveKit] audio playback started');
      }
      add(AskAiLivekitEventReported(
          lastLivekitEvent:
              'Track subscribed: ${event.participant.identity} ${publication.sid} ${publication.kind.name}',
          agentAudioActive: isAudio || state.agentAudioActive,
          agentConnected: true));
    });
    livekitListener!.on<TrackUnsubscribedEvent>((event) {
      debugPrint('[LiveKit] track unsubscribed: ${event.publication.sid}');
      add(const AskAiRoomUpdated());
      add(AskAiLivekitEventReported(
          lastLivekitEvent: 'Track unsubscribed: ${event.publication.sid}'));
    });
  }

  @override
  Future<void> close() {
    room?.disconnect();
    livekitListener?.dispose();
    room?.dispose();
    return super.close();
  }
}
