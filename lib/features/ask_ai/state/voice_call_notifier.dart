import 'dart:async';

import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/core/services/voice_agent_audio_route_service.dart';
import 'package:ustadia_user_app/features/ask_ai/data/datasources/ai_chat_remote_data_source.dart';

enum VoiceUiState { connecting, listening, thinking, speaking, error }

enum VoiceAudioOutputMode { speaker, phone }

class VoiceCallNotifier extends ChangeNotifier {
  static const String agentParticipantIdentity = 'ustadia-bot';
  static const double assistantSpeakingThreshold = 0.01;
  static const double assistantVisualizerThreshold = 0.08;
  static const double levelNotifyThreshold = 0.035;

  final AiChatRemoteDataSource aiChatRemoteDataSource;
  final String topicId;

  Room? room;
  EventsListener<RoomEvent>? livekitListener;
  AudioVisualizer? assistantAudioVisualizer;
  CancelListenFunc? assistantAudioVisualizerSubscription;
  String? assistantTrackSid;

  VoiceUiState voiceUiState = VoiceUiState.connecting;
  VoiceAudioOutputMode outputMode = VoiceAudioOutputMode.speaker;
  bool isConnecting = false;
  bool isDisposed = false;
  bool isMicrophoneTransitioning = false;
  bool micEnabled = false;
  bool agentConnected = false;
  bool agentAudioActive = false;
  bool agentAudioPlaying = false;
  bool assistantSpeaking = false;
  bool assistantAudioLocked = false;
  bool userSpeaking = false;
  bool userTurnHasSpeech = false;
  String? currentAgentIdentity;
  int participantsCount = 0;
  double agentAudioLevel = 0;
  double localAudioLevel = 0;
  bool localSpeaking = false;
  bool audioSessionActive = false;
  String lastLivekitEvent = '';
  String? errorMessage;
  Timer? thinkingTimer;
  Timer? speakingSilenceTimer;
  Timer? assistantAudioLockTimer;
  int connectAttemptId = 0;
  Future<void>? disconnectOperation;
  Future<void>? audioOutputModeOperation;

  VoiceCallNotifier({required this.aiChatRemoteDataSource, required this.topicId});

  bool get isConnected => room?.connectionState == ConnectionState.connected;
  bool get isAgentTurn => assistantAudioLocked;
  bool get canStartUserTurn =>
      isConnected && !isConnecting && voiceUiState != VoiceUiState.connecting;
  bool get isSpeakerMode => outputMode == VoiceAudioOutputMode.speaker;

  bool isActiveConnectAttempt(int attemptId) => !isDisposed && attemptId == connectAttemptId;

  void notifySafely() {
    if (!isDisposed) notifyListeners();
  }

  Future<void> connect() async {
    if (isDisposed || isConnecting || isConnected || disconnectOperation != null) return;
    final micPermission = await Permission.microphone.request();
    if (micPermission.isDenied || micPermission.isPermanentlyDenied) {
      errorMessage = 'Microphone permission denied'.tr();
      setVoiceState(VoiceUiState.error);
      notifySafely();
      return;
    }
    final attemptId = ++connectAttemptId;
    isConnecting = true;
    errorMessage = null;
    setVoiceState(VoiceUiState.connecting);
    debugPrint('[Voice] connecting...');

    try {
      await applyCurrentAudioOutputMode(reason: 'before_livekit_connect');
      final tokenModel = await aiChatRemoteDataSource.fetchLivekitToken(topicId: topicId);
      if (!isActiveConnectAttempt(attemptId)) return;
      final nextRoom = Room(
          roomOptions: RoomOptions(
              adaptiveStream: true,
              dynacast: true,
              defaultAudioOutputOptions: AudioOutputOptions(speakerOn: isSpeakerMode)));
      listenToRoomEvents(nextRoom);
      await nextRoom.connect(tokenModel.url, tokenModel.token);
      if (!isActiveConnectAttempt(attemptId)) {
        await nextRoom.disconnect();
        nextRoom.dispose();
        return;
      }
      if (room != null && room != nextRoom) {
        unawaited(room!.disconnect());
        room!.dispose();
      }
      room = nextRoom;
      await nextRoom.localParticipant?.setMicrophoneEnabled(false);
      await Future.delayed(const Duration(milliseconds: 300));
      if (!isActiveConnectAttempt(attemptId)) return;
      await applyCurrentAudioOutputMode(reason: 'after_livekit_connect');
      micEnabled = false;
      assistantAudioLocked = false;
      participantsCount = roomParticipantsCount(room);
      agentConnected = agentConnectedValue(room);
      agentAudioActive = agentAudioActiveValue(room);
      setVoiceState(VoiceUiState.listening);
      debugPrint('[Voice] connected');
    } on DioException catch (error) {
      await stopAudioSession(reason: 'voice_connect_failed');
      errorMessage = DioErrorMessage.from(error);
      setVoiceState(VoiceUiState.error);
      clearAssistantAudioLock();
      userSpeaking = false;
      agentAudioActive = false;
    } catch (error) {
      await stopAudioSession(reason: 'voice_connect_failed');
      errorMessage = 'Request failed.'.tr();
      setVoiceState(VoiceUiState.error);
      clearAssistantAudioLock();
      userSpeaking = false;
      agentAudioActive = false;
    } finally {
      if (isActiveConnectAttempt(attemptId)) {
        isConnecting = false;
        notifySafely();
      }
    }
  }

  Future<void> disconnect() async {
    final ongoingDisconnect = disconnectOperation;
    if (ongoingDisconnect != null) {
      await ongoingDisconnect;
      return;
    }
    final operation = disconnectInternal();
    disconnectOperation = operation;
    await operation;
    if (identical(disconnectOperation, operation)) {
      disconnectOperation = null;
    }
  }

  Future<void> disconnectInternal() async {
    debugPrint('[Voice] disconnecting...');
    connectAttemptId++;
    thinkingTimer?.cancel();
    speakingSilenceTimer?.cancel();
    assistantAudioLockTimer?.cancel();
    await disposeAssistantAudioVisualizer();
    isConnecting = false;
    livekitListener?.dispose();
    livekitListener = null;
    final roomValue = room;
    room = null;
    if (roomValue == null) {
      await stopAudioSession(reason: 'voice_session_disconnected_without_room');
      resetState();
      return;
    }
    try {
      await roomValue.localParticipant?.setMicrophoneEnabled(false);
      await roomValue.disconnect();
    } finally {
      await stopAudioSession(reason: 'voice_session_disconnected');
      roomValue.dispose();
      resetState();
      debugPrint('[Voice] disconnected');
    }
  }

  Future<void> onAppPaused() async {
    await disconnect();
  }

  Future<void> onAppResumed() async {
    if (!isConnected) return;
    await applyCurrentAudioOutputMode(reason: 'app_resumed');
    notifySafely();
  }

  Future<void> toggleAudioOutputMode() async {
    final nextMode = outputMode == VoiceAudioOutputMode.speaker
        ? VoiceAudioOutputMode.phone
        : VoiceAudioOutputMode.speaker;
    await setAudioOutputMode(nextMode);
  }

  Future<void> setAudioOutputMode(VoiceAudioOutputMode nextMode) async {
    if (outputMode == nextMode) return;
    outputMode = nextMode;
    notifySafely();
    await applyCurrentAudioOutputMode(reason: 'user_selected_${nextMode.name}');
  }

  Future<void> toggleMicrophone() async {
    if (!isConnected || room == null || isConnecting || isMicrophoneTransitioning) return;
    if (!micEnabled && !canStartUserTurn) return;
    await setMicrophoneEnabled(!micEnabled);
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (!isConnected || room == null) return;
    if (enabled && !canStartUserTurn) return;
    if (micEnabled == enabled && !isMicrophoneTransitioning) return;
    final previousMicEnabled = micEnabled;
    final previousUserSpeaking = userSpeaking;
    final previousLocalSpeaking = localSpeaking;
    final previousLocalAudioLevel = localAudioLevel;
    final previousUserTurnHasSpeech = userTurnHasSpeech;
    final previousVoiceUiState = voiceUiState;

    isMicrophoneTransitioning = true;
    micEnabled = enabled;
    userSpeaking = false;
    localSpeaking = false;
    localAudioLevel = 0;
    if (enabled) {
      userTurnHasSpeech = false;
      if (voiceUiState != VoiceUiState.error) {
        voiceUiState = VoiceUiState.listening;
      }
      notifySafely();
    } else {
      if (!assistantAudioLocked && voiceUiState != VoiceUiState.error) {
        voiceUiState = VoiceUiState.listening;
      }
      notifySafely();
    }
    try {
      if (enabled) {
        await room!.localParticipant?.setMicrophoneEnabled(true);
      } else {
        await room!.localParticipant?.setMicrophoneEnabled(false);
      }
      await applyCurrentAudioOutputMode(
          reason: enabled ? 'microphone_enabled' : 'microphone_disabled');
    } catch (error) {
      micEnabled = previousMicEnabled;
      userSpeaking = previousUserSpeaking;
      localSpeaking = previousLocalSpeaking;
      localAudioLevel = previousLocalAudioLevel;
      userTurnHasSpeech = previousUserTurnHasSpeech;
      voiceUiState = previousVoiceUiState;
      rethrow;
    } finally {
      isMicrophoneTransitioning = false;
      notifySafely();
    }
  }

  Future<void> stopMicrophoneForAssistant() async {
    if (!micEnabled || room == null || isMicrophoneTransitioning) return;
    isMicrophoneTransitioning = true;
    micEnabled = false;
    userSpeaking = false;
    localSpeaking = false;
    localAudioLevel = 0;
    userTurnHasSpeech = false;
    notifySafely();
    try {
      await room!.localParticipant?.setMicrophoneEnabled(false);
      await applyCurrentAudioOutputMode(reason: 'stop_microphone_for_assistant');
    } finally {
      isMicrophoneTransitioning = false;
      notifySafely();
    }
  }

  Future<void> applyCurrentAudioOutputMode({required String reason}) {
    late final Future<void> operation;
    operation = (audioOutputModeOperation ?? Future<void>.value())
        .catchError((_) {})
        .then((_) => applyCurrentAudioOutputModeInternal(reason: reason));
    audioOutputModeOperation = operation;
    unawaited(operation.whenComplete(() {
      if (identical(audioOutputModeOperation, operation)) {
        audioOutputModeOperation = null;
      }
    }));
    return operation;
  }

  Future<void> applyCurrentAudioOutputModeInternal({required String reason}) async {
    if (isDisposed) return;
    final roomValue = room;
    final targetMode = outputMode;
    final isSpeakerOutput = targetMode == VoiceAudioOutputMode.speaker;
    final modeName = targetMode.name;
    try {
      await VoiceAgentAudioRouteService.instance
          .applyOutputMode(outputMode: modeName, reason: reason);
      audioSessionActive = true;
      if (isDisposed || !identical(room, roomValue)) return;
      if (roomValue != null) {
        await roomValue.setSpeakerOn(isSpeakerOutput, forceSpeakerOutput: isSpeakerOutput);
      }
    } catch (error, stackTrace) {
      debugPrint('[VoiceAudioOutput] apply failed: $error');
      debugPrintStack(stackTrace: stackTrace);
    }
  }

  Future<void> stopAudioSession({required String reason}) {
    if (!audioSessionActive && audioOutputModeOperation == null) return Future<void>.value();
    late final Future<void> operation;
    operation = (audioOutputModeOperation ?? Future<void>.value())
        .catchError((_) {})
        .then((_) => stopAudioSessionInternal(reason: reason));
    audioOutputModeOperation = operation;
    unawaited(operation.whenComplete(() {
      if (identical(audioOutputModeOperation, operation)) {
        audioOutputModeOperation = null;
      }
    }));
    return operation;
  }

  Future<void> stopAudioSessionInternal({required String reason}) async {
    if (!audioSessionActive) return;
    audioSessionActive = false;
    await VoiceAgentAudioRouteService.instance.stopSession(reason: reason);
  }

  Future<void> attachAssistantAudioVisualizer(RemoteAudioTrack track) async {
    if (assistantAudioVisualizer != null) {
      await disposeAssistantAudioVisualizer();
    }
    final nextVisualizer = createVisualizer(track,
        options: const AudioVisualizerOptions(barCount: 7, centeredBands: true));
    assistantAudioVisualizerSubscription = nextVisualizer.events.listen((event) {
      final nextLevel = visualizerLevel(event.event);
      final visibleLevel = nextLevel < assistantVisualizerThreshold ? 0.0 : nextLevel;
      final levelChanged = (agentAudioLevel - visibleLevel).abs() > levelNotifyThreshold;
      agentAudioLevel = visibleLevel;
      if (visibleLevel <= 0) {
        if (levelChanged) notifySafely();
        return;
      }
      refreshAssistantAudioLock();
      if (voiceUiState != VoiceUiState.error) {
        final stateChanged = setVoiceState(VoiceUiState.speaking);
        if (!stateChanged && levelChanged) notifySafely();
      } else if (levelChanged) {
        notifySafely();
      }
    });
    assistantAudioVisualizer = nextVisualizer;
    await nextVisualizer.start();
  }

  Future<void> disposeAssistantAudioVisualizer() async {
    if (assistantAudioVisualizerSubscription != null) {
      await assistantAudioVisualizerSubscription!.call();
    }
    assistantAudioVisualizerSubscription = null;
    final visualizer = assistantAudioVisualizer;
    assistantAudioVisualizer = null;
    if (visualizer == null) return;
    await visualizer.stop();
    visualizer.dispose();
  }

  double visualizerLevel(List<Object?> bars) {
    if (bars.isEmpty) return 0;
    double peak = 0;
    for (final bar in bars) {
      if (bar is num && bar.toDouble() > peak) {
        peak = bar.toDouble();
      }
    }
    return peak.clamp(0.0, 1.0);
  }

  void listenToRoomEvents(Room nextRoom) {
    livekitListener?.dispose();
    livekitListener = nextRoom.createListener();
    livekitListener!.on<RoomConnectedEvent>((event) async {
      debugPrint('[LiveKit] room connected');
      await applyCurrentAudioOutputMode(reason: 'room_connected_event');
      participantsCount = roomParticipantsCount(nextRoom);
      setLastEvent('Room connected');
    });
    livekitListener!.on<RoomReconnectingEvent>((event) {
      debugPrint('[LiveKit] room reconnecting');
      setLastEvent('Room reconnecting');
      setVoiceState(VoiceUiState.connecting);
    });
    livekitListener!.on<RoomReconnectedEvent>((event) async {
      debugPrint('[LiveKit] room reconnected');
      await applyCurrentAudioOutputMode(reason: 'room_reconnected_event');
      participantsCount = roomParticipantsCount(nextRoom);
      agentConnected = agentConnectedValue(nextRoom);
      agentAudioActive = agentAudioActiveValue(nextRoom);
      if (!assistantAudioLocked) setVoiceState(VoiceUiState.listening);
      setLastEvent('Room reconnected');
    });
    livekitListener!.on<RoomDisconnectedEvent>((event) {
      debugPrint('[LiveKit] room disconnected');
      setLastEvent('Room disconnected');
      unawaited(stopAudioSession(reason: 'room_disconnected_event'));
      setVoiceState(VoiceUiState.error);
      clearAssistantAudioLock();
      userSpeaking = false;
      agentAudioActive = false;
      notifySafely();
    });
    livekitListener!.on<ParticipantConnectedEvent>((event) {
      debugPrint('[LiveKit] participant joined: ${event.participant.identity}');
      participantsCount = roomParticipantsCount(nextRoom);
      if (event.participant.identity.isNotEmpty) {
        currentAgentIdentity = event.participant.identity;
      }
      agentConnected = true;
      setLastEvent('Participant joined: ${event.participant.identity}');
      notifySafely();
    });
    livekitListener!.on<ParticipantDisconnectedEvent>((event) {
      debugPrint('[LiveKit] participant left: ${event.participant.identity}');
      participantsCount = roomParticipantsCount(nextRoom);
      agentConnected = agentConnectedValue(nextRoom);
      setLastEvent('Participant left: ${event.participant.identity}');
      notifySafely();
    });
    livekitListener!.on<TrackSubscribedEvent>((event) async {
      final track = event.track;
      final publication = event.publication;
      debugPrint(
          '[LiveKit] track subscribed: kind=${publication.kind.name} participant=${event.participant.identity}');
      if (track is RemoteAudioTrack) {
        await stopMicrophoneForAssistant();
        debugPrint('🔥 AGENT AUDIO TRACK RECEIVED from ${event.participant.identity}');
        if (event.participant.identity.isNotEmpty) {
          currentAgentIdentity = event.participant.identity;
        }
        if (assistantTrackSid != publication.sid) {
          assistantTrackSid = publication.sid;
          await track.start();
          await attachAssistantAudioVisualizer(track);
        }
        debugPrint('[LiveKit] audio playback started');
        agentAudioActive = true;
        agentConnected = true;
        speakingSilenceTimer?.cancel();
      }
      setLastEvent(
          'Track subscribed: ${event.participant.identity} ${publication.sid} ${publication.kind.name}');
      notifySafely();
    });
    livekitListener!.on<TrackUnsubscribedEvent>((event) {
      debugPrint('[LiveKit] track unsubscribed: ${event.publication.sid}');
      setLastEvent('Track unsubscribed: ${event.publication.sid}');
      agentAudioActive = agentAudioActiveValue(nextRoom);
      if (event.track is RemoteAudioTrack) {
        if (assistantTrackSid == event.publication.sid) {
          assistantTrackSid = null;
        }
        disposeAssistantAudioVisualizer();
        clearAssistantAudioLock();
      }
      if (!agentAudioActive) startListeningTransition();
      notifySafely();
    });
    livekitListener!.on<LocalTrackPublishedEvent>((event) {
      debugPrint('[LiveKit] local track published: ${event.publication.sid}');
      setLastEvent('Local track published: ${event.publication.sid}');
    });
    livekitListener!.on<ActiveSpeakersChangedEvent>((event) {
      handleActiveSpeakers(event.speakers);
    });
  }

  void handleActiveSpeakers(List<Participant> speakers) {
    if (isDisposed) return;
    final roomValue = room;
    if (roomValue == null) return;
    final localParticipant = roomValue.localParticipant;
    bool localActive = false;
    double localLevel = 0;

    for (final speaker in speakers) {
      final isLocal = localParticipant != null && speaker.sid == localParticipant.sid;
      if (isLocal) {
        localActive = true;
        localLevel = speaker.audioLevel;
        if (speaker.audioLevel >= assistantSpeakingThreshold) userTurnHasSpeech = true;
      } else {
        if (speaker.identity.isNotEmpty && currentAgentIdentity == null) {
          currentAgentIdentity = speaker.identity;
        }
      }
    }

    final levelChanged = (localLevel - localAudioLevel).abs() > 0.02;
    final speakingChanged = localActive != userSpeaking;
    localAudioLevel = localLevel;
    userSpeaking = localActive;
    if (!levelChanged && !speakingChanged) return;

    bool stateChanged = false;
    if (localActive) {
      localSpeaking = true;
      if (voiceUiState != VoiceUiState.connecting && voiceUiState != VoiceUiState.error) {
        stateChanged = setVoiceState(VoiceUiState.listening);
      }
      speakingSilenceTimer?.cancel();
    } else if (localSpeaking) {
      localSpeaking = false;
      if (micEnabled) {
        stateChanged = setVoiceState(VoiceUiState.listening);
      } else if (userTurnHasSpeech) {
        startThinkingTransition();
      } else {
        startListeningTransition();
      }
    } else if (!assistantAudioLocked && agentAudioPlaying) {
      startListeningTransition();
    }
    if (!stateChanged) notifySafely();
  }

  void startThinkingTransition() {
    setVoiceState(VoiceUiState.thinking);
    thinkingTimer?.cancel();
    thinkingTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!assistantAudioLocked) setVoiceState(VoiceUiState.listening);
    });
  }

  void startListeningTransition() {
    speakingSilenceTimer?.cancel();
    speakingSilenceTimer = Timer(const Duration(milliseconds: 1500), () {
      if (!assistantAudioLocked && voiceUiState != VoiceUiState.thinking) {
        setVoiceState(VoiceUiState.listening);
      }
    });
  }

  bool setVoiceState(VoiceUiState nextState) {
    if (isDisposed) return false;
    if (voiceUiState == nextState) return false;
    voiceUiState = nextState;
    debugPrint('[VoiceUI] state -> $voiceUiState');
    notifySafely();
    return true;
  }

  void setLastEvent(String value) {
    if (isDisposed) return;
    lastLivekitEvent = value;
    notifySafely();
  }

  double normalizedAssistantLevel(double rawLevel) {
    final clampedLevel = rawLevel.clamp(0, 1).toDouble();
    if (clampedLevel <= 0) return 0;
    return (clampedLevel * 7.5).clamp(0.12, 1.0);
  }

  void refreshAssistantAudioLock() {
    if (isDisposed) return;
    assistantAudioLockTimer?.cancel();
    assistantAudioLocked = true;
    assistantSpeaking = true;
    agentAudioPlaying = true;
    assistantAudioLockTimer = Timer(const Duration(milliseconds: 1400), releaseAssistantAudioLock);
  }

  void releaseAssistantAudioLock() {
    if (isDisposed) return;
    assistantAudioLocked = false;
    assistantSpeaking = false;
    agentAudioPlaying = false;
    if (voiceUiState == VoiceUiState.speaking) {
      setVoiceState(VoiceUiState.listening);
      return;
    }
    notifySafely();
  }

  void clearAssistantAudioLock() {
    assistantAudioLockTimer?.cancel();
    assistantAudioLocked = false;
    assistantSpeaking = false;
    agentAudioPlaying = false;
  }

  bool consumeUserTurnHasSpeech() {
    final value = userTurnHasSpeech;
    userTurnHasSpeech = false;
    return value;
  }

  void resetState() {
    if (isDisposed) return;
    assistantAudioLockTimer?.cancel();
    disposeAssistantAudioVisualizer();
    assistantTrackSid = null;
    agentConnected = false;
    agentAudioActive = false;
    agentAudioPlaying = false;
    assistantSpeaking = false;
    assistantAudioLocked = false;
    userSpeaking = false;
    userTurnHasSpeech = false;
    currentAgentIdentity = null;
    micEnabled = false;
    participantsCount = 0;
    agentAudioLevel = 0;
    localAudioLevel = 0;
    localSpeaking = false;
    audioSessionActive = false;
    voiceUiState = VoiceUiState.connecting;
    lastLivekitEvent = '';
    errorMessage = null;
    notifySafely();
  }

  int roomParticipantsCount(Room? roomValue) {
    if (roomValue == null) return 0;
    return roomValue.remoteParticipants.length + 1;
  }

  bool agentConnectedValue(Room? roomValue) {
    if (roomValue == null) return false;
    if (roomValue.remoteParticipants.isEmpty) return false;
    for (final participant in roomValue.remoteParticipants.values) {
      if (participant.identity == 'ustadia-bot') return true;
    }
    return true;
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

  @override
  void dispose() {
    if (isDisposed) {
      super.dispose();
      return;
    }
    isDisposed = true;
    thinkingTimer?.cancel();
    speakingSilenceTimer?.cancel();
    assistantAudioLockTimer?.cancel();
    thinkingTimer = null;
    speakingSilenceTimer = null;
    assistantAudioLockTimer = null;
    connectAttemptId++;
    disconnectOperation = null;
    final currentListener = livekitListener;
    livekitListener = null;
    final roomValue = room;
    room = null;
    final currentVisualizer = assistantAudioVisualizer;
    assistantAudioVisualizer = null;
    final currentVisualizerSubscription = assistantAudioVisualizerSubscription;
    assistantAudioVisualizerSubscription = null;
    assistantTrackSid = null;
    agentConnected = false;
    agentAudioActive = false;
    agentAudioPlaying = false;
    assistantSpeaking = false;
    assistantAudioLocked = false;
    userSpeaking = false;
    userTurnHasSpeech = false;
    currentAgentIdentity = null;
    micEnabled = false;
    participantsCount = 0;
    agentAudioLevel = 0;
    localAudioLevel = 0;
    localSpeaking = false;
    audioSessionActive = false;
    lastLivekitEvent = '';
    Future<void>(() async {
      currentListener?.dispose();
      if (currentVisualizerSubscription != null) {
        await currentVisualizerSubscription();
      }
      if (currentVisualizer != null) {
        await currentVisualizer.stop();
        currentVisualizer.dispose();
      }
      if (roomValue != null) {
        try {
          await roomValue.localParticipant?.setMicrophoneEnabled(false);
          await roomValue.disconnect();
        } finally {
          roomValue.dispose();
          await VoiceAgentAudioRouteService.instance.stopSession(reason: 'voice_session_disposed');
        }
      } else {
        await VoiceAgentAudioRouteService.instance.stopSession(reason: 'voice_session_disposed');
      }
    });
    super.dispose();
  }
}
