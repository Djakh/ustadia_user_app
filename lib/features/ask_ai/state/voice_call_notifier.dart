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

class VoiceCallNotifier extends ChangeNotifier {
  static const String agentParticipantIdentity = 'ustadia-bot';
  static const double assistantSpeakingThreshold = 0.01;
  static const double assistantVisualizerThreshold = 0.08;

  final AiChatRemoteDataSource aiChatRemoteDataSource;
  final String topicId;

  Room? room;
  EventsListener<RoomEvent>? livekitListener;
  AudioVisualizer? assistantAudioVisualizer;

  VoiceUiState voiceUiState = VoiceUiState.connecting;
  bool isConnecting = false;
  bool isDisposed = false;
  bool micEnabled = false;
  bool speakerEnabled = false;
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
  String lastLivekitEvent = '';
  String? errorMessage;
  Timer? thinkingTimer;
  Timer? speakingSilenceTimer;
  Timer? levelJitterTimer;
  Timer? assistantAudioLockTimer;

  VoiceCallNotifier({required this.aiChatRemoteDataSource, required this.topicId});

  bool get isConnected => room?.connectionState == ConnectionState.connected;
  bool get isAgentTurn => assistantAudioLocked;
  bool get canStartUserTurn =>
      isConnected && !isConnecting && voiceUiState != VoiceUiState.connecting;

  Future<void> connect() async {
    if (isDisposed || isConnecting || isConnected) return;
    isConnecting = true;
    errorMessage = null;
    setVoiceState(VoiceUiState.connecting);
    debugPrint('[Voice] connecting...');

    final permissionStatus = await Permission.microphone.request();
    if (!permissionStatus.isGranted) {
      if (permissionStatus.isPermanentlyDenied) {
        await openAppSettings();
      }
      errorMessage = 'Microphone permission denied'.tr();
      setVoiceState(VoiceUiState.error);
      isConnecting = false;
      notifyListeners();
      return;
    }

    try {
      await VoiceAgentAudioRouteService.instance.startSession(reason: 'before_livekit_connect');
      final tokenModel = await aiChatRemoteDataSource.fetchLivekitToken(topicId: topicId);
      if (isDisposed) return;
      final nextRoom = room ??
          Room(
              roomOptions: const RoomOptions(
                  adaptiveStream: true,
                  dynacast: true,
                  defaultAudioOutputOptions: AudioOutputOptions(speakerOn: true)));
      listenToRoomEvents(nextRoom);
      await nextRoom.connect(tokenModel.url, tokenModel.token);
      if (isDisposed) {
        await nextRoom.disconnect();
        return;
      }
      await nextRoom.localParticipant?.setMicrophoneEnabled(false);
      room = nextRoom;
      await ensureMicrophoneTrackUnpublished();
      await applyPlaybackMode(reason: 'after_livekit_connect');
      micEnabled = false;
      speakerEnabled = true;
      assistantAudioLocked = false;
      participantsCount = roomParticipantsCount(room);
      agentConnected = agentConnectedValue(room);
      agentAudioActive = agentAudioActiveValue(room);
      setVoiceState(VoiceUiState.listening);
      debugPrint('[Voice] connected');
    } on DioException catch (error) {
      errorMessage = DioErrorMessage.from(error);
      setVoiceState(VoiceUiState.error);
      clearAssistantAudioLock();
      userSpeaking = false;
      agentAudioActive = false;
    } catch (error) {
      errorMessage = 'Request failed.'.tr();
      setVoiceState(VoiceUiState.error);
      clearAssistantAudioLock();
      userSpeaking = false;
      agentAudioActive = false;
    } finally {
      isConnecting = false;
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    debugPrint('[Voice] disconnecting...');
    thinkingTimer?.cancel();
    speakingSilenceTimer?.cancel();
    assistantAudioLockTimer?.cancel();
    await disposeAssistantAudioVisualizer();
    isConnecting = false;
    if (room == null) {
      resetState();
      return;
    }
    try {
      await room!.localParticipant?.setMicrophoneEnabled(false);
      await room!.disconnect();
    } finally {
      await VoiceAgentAudioRouteService.instance.stopSession(reason: 'voice_session_disconnected');
      livekitListener?.dispose();
      livekitListener = null;
      room?.dispose();
      room = null;
      resetState();
      debugPrint('[Voice] disconnected');
    }
  }

  Future<void> onAppPaused() async {
    await disconnect();
  }

  Future<void> onAppResumed() async {
    if (!isConnected) return;
    await applyCurrentAudioMode(reason: 'app_resumed');
    notifyListeners();
  }

  Future<void> toggleMicrophone() async {
    if (!isConnected || room == null || isConnecting) return;
    if (!micEnabled && !canStartUserTurn) return;
    await setMicrophoneEnabled(!micEnabled);
  }

  Future<void> setMicrophoneEnabled(bool enabled) async {
    if (!isConnected || room == null) return;
    if (enabled && !canStartUserTurn) return;
    if (enabled) {
      await applyCaptureMode(reason: 'microphone_enabled');
      await room!.localParticipant?.setMicrophoneEnabled(true);
    } else {
      await room!.localParticipant?.setMicrophoneEnabled(false);
      await ensureMicrophoneTrackUnpublished();
      await applyPlaybackMode(reason: 'microphone_disabled');
    }
    micEnabled = enabled;
    userSpeaking = false;
    localSpeaking = false;
    localAudioLevel = 0;
    if (enabled) {
      userTurnHasSpeech = false;
      setVoiceState(VoiceUiState.listening);
      return;
    }
    if (!assistantAudioLocked && voiceUiState != VoiceUiState.error) setVoiceState(VoiceUiState.listening);
    notifyListeners();
  }

  Future<void> stopMicrophoneForAssistant() async {
    if (!micEnabled || room == null) return;
    micEnabled = false;
    userSpeaking = false;
    localSpeaking = false;
    localAudioLevel = 0;
    userTurnHasSpeech = false;
    notifyListeners();
    await room!.localParticipant?.setMicrophoneEnabled(false);
    await ensureMicrophoneTrackUnpublished();
    await applyPlaybackMode(reason: 'assistant_turn_started');
  }

  Future<void> ensureMicrophoneTrackUnpublished() async {
    final roomValue = room;
    if (roomValue == null) return;
    final localParticipant = roomValue.localParticipant;
    final publication = localParticipant?.getTrackPublicationBySource(TrackSource.microphone);
    if (publication == null) return;
    await localParticipant?.removePublishedTrack(publication.sid);
  }

  Future<void> applyCurrentAudioMode({required String reason}) async {
    if (micEnabled) {
      await applyCaptureMode(reason: reason);
      return;
    }
    await applyPlaybackMode(reason: reason);
  }

  Future<void> applyPlaybackMode({required String reason}) async {
    final roomValue = room;
    await VoiceAgentAudioRouteService.instance.enterPlaybackMode(reason: reason);
    if (roomValue != null) {
      await roomValue.setSpeakerOn(true, forceSpeakerOutput: true);
    }
    speakerEnabled = true;
  }

  Future<void> applyCaptureMode({required String reason}) async {
    final roomValue = room;
    await VoiceAgentAudioRouteService.instance.enterCaptureMode(reason: reason);
    if (roomValue != null) {
      await roomValue.setSpeakerOn(true, forceSpeakerOutput: true);
    }
    speakerEnabled = true;
  }

  Future<void> attachAssistantAudioVisualizer(RemoteAudioTrack track) async {
    if (assistantAudioVisualizer != null) {
      await disposeAssistantAudioVisualizer();
    }
    final nextVisualizer = createVisualizer(track,
        options: const AudioVisualizerOptions(barCount: 7, centeredBands: true));
    nextVisualizer.events.listen((event) {
      final nextLevel = visualizerLevel(event.event);
      agentAudioLevel = nextLevel;
      if (nextLevel < assistantVisualizerThreshold) {
        notifyListeners();
        return;
      }
      refreshAssistantAudioLock();
      if (voiceUiState != VoiceUiState.error) {
        setVoiceState(VoiceUiState.speaking);
      } else {
        notifyListeners();
      }
    });
    assistantAudioVisualizer = nextVisualizer;
    await nextVisualizer.start();
  }

  Future<void> disposeAssistantAudioVisualizer() async {
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
    livekitListener!.on<RoomConnectedEvent>((event) {
      debugPrint('[LiveKit] room connected');
      room?.setSpeakerOn(true, forceSpeakerOutput: true);
      VoiceAgentAudioRouteService.instance.enterPlaybackMode(reason: 'room_connected_event');
      speakerEnabled = true;
      participantsCount = roomParticipantsCount(nextRoom);
      setLastEvent('Room connected');
    });
    livekitListener!.on<RoomDisconnectedEvent>((event) {
      debugPrint('[LiveKit] room disconnected');
      setLastEvent('Room disconnected');
      setVoiceState(VoiceUiState.error);
      clearAssistantAudioLock();
      userSpeaking = false;
      agentAudioActive = false;
      notifyListeners();
    });
    livekitListener!.on<ParticipantConnectedEvent>((event) {
      debugPrint('[LiveKit] participant joined: ${event.participant.identity}');
      participantsCount = roomParticipantsCount(nextRoom);
      if (event.participant.identity.isNotEmpty) {
        currentAgentIdentity = event.participant.identity;
      }
      agentConnected = true;
      setLastEvent('Participant joined: ${event.participant.identity}');
      notifyListeners();
    });
    livekitListener!.on<ParticipantDisconnectedEvent>((event) {
      debugPrint('[LiveKit] participant left: ${event.participant.identity}');
      participantsCount = roomParticipantsCount(nextRoom);
      agentConnected = agentConnectedValue(nextRoom);
      setLastEvent('Participant left: ${event.participant.identity}');
      notifyListeners();
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
        await track.start();
        await attachAssistantAudioVisualizer(track);
        debugPrint('[LiveKit] audio playback started');
        await applyPlaybackMode(reason: 'remote_audio_track_subscribed');
        agentAudioActive = true;
        agentConnected = true;
        speakingSilenceTimer?.cancel();
      }
      setLastEvent(
          'Track subscribed: ${event.participant.identity} ${publication.sid} ${publication.kind.name}');
      notifyListeners();
    });
    livekitListener!.on<TrackUnsubscribedEvent>((event) {
      debugPrint('[LiveKit] track unsubscribed: ${event.publication.sid}');
      setLastEvent('Track unsubscribed: ${event.publication.sid}');
      agentAudioActive = agentAudioActiveValue(nextRoom);
      if (event.track is RemoteAudioTrack) {
        disposeAssistantAudioVisualizer();
        clearAssistantAudioLock();
      }
      if (!agentAudioActive) startListeningTransition();
      notifyListeners();
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

    localAudioLevel = localLevel;
    userSpeaking = localActive;

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

    updateLevelJitter();
    debugPrint(
        '[VoiceUI] assistantLevel=${agentAudioLevel.toStringAsFixed(2)} userLevel=${localAudioLevel.toStringAsFixed(2)} assistantLocked=$assistantAudioLocked userSpeaking=$userSpeaking');
    if (!stateChanged) notifyListeners();
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
    if (voiceUiState == nextState) return false;
    voiceUiState = nextState;
    debugPrint('[VoiceUI] state -> $voiceUiState');
    notifyListeners();
    return true;
  }

  void setLastEvent(String value) {
    lastLivekitEvent = value;
    notifyListeners();
  }

  double normalizedAssistantLevel(double rawLevel) {
    final clampedLevel = rawLevel.clamp(0, 1).toDouble();
    if (clampedLevel <= 0) return 0;
    return (clampedLevel * 7.5).clamp(0.12, 1.0);
  }

  void refreshAssistantAudioLock() {
    assistantAudioLockTimer?.cancel();
    assistantAudioLocked = true;
    assistantSpeaking = true;
    agentAudioPlaying = true;
    assistantAudioLockTimer = Timer(const Duration(milliseconds: 1400), releaseAssistantAudioLock);
  }

  void releaseAssistantAudioLock() {
    assistantAudioLocked = false;
    assistantSpeaking = false;
    agentAudioPlaying = false;
    if (voiceUiState == VoiceUiState.speaking) {
      setVoiceState(VoiceUiState.listening);
      return;
    }
    notifyListeners();
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
    assistantAudioLockTimer?.cancel();
    disposeAssistantAudioVisualizer();
    agentConnected = false;
    agentAudioActive = false;
    agentAudioPlaying = false;
    assistantSpeaking = false;
    assistantAudioLocked = false;
    userSpeaking = false;
    userTurnHasSpeech = false;
    currentAgentIdentity = null;
    micEnabled = false;
    speakerEnabled = false;
    participantsCount = 0;
    agentAudioLevel = 0;
    localAudioLevel = 0;
    localSpeaking = false;
    voiceUiState = VoiceUiState.connecting;
    lastLivekitEvent = '';
    errorMessage = null;
    notifyListeners();
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
    isDisposed = true;
    thinkingTimer?.cancel();
    speakingSilenceTimer?.cancel();
    levelJitterTimer?.cancel();
    assistantAudioLockTimer?.cancel();
    unawaited(disposeAssistantAudioVisualizer());
    if (room != null) {
      unawaited(room!.disconnect());
    }
    livekitListener?.dispose();
    room?.dispose();
    super.dispose();
  }

  void updateLevelJitter() {
    if (!assistantSpeaking && !userSpeaking) {
      levelJitterTimer?.cancel();
      return;
    }
    if (levelJitterTimer != null) return;
    levelJitterTimer = Timer.periodic(const Duration(milliseconds: 120), (timer) {
      if (!assistantSpeaking && !userSpeaking) {
        timer.cancel();
        levelJitterTimer = null;
        return;
      }
      if (assistantSpeaking && agentAudioLevel < 0.02) {
        agentAudioLevel = 0.15 + (timer.tick % 5) * 0.03;
      }
      if (userSpeaking && localAudioLevel < 0.02) {
        localAudioLevel = 0.12 + (timer.tick % 5) * 0.025;
      }
      notifyListeners();
    });
  }
}
