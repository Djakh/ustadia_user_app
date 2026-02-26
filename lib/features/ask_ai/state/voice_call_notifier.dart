import 'dart:async';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:livekit_client/livekit_client.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/ask_ai/data/datasources/ai_chat_remote_data_source.dart';

enum VoiceUiState { connecting, listening, thinking, speaking, error }

class VoiceCallNotifier extends ChangeNotifier {
  final AiChatRemoteDataSource aiChatRemoteDataSource;
  final String topicId;

  Room? room;
  EventsListener<RoomEvent>? livekitListener;

  VoiceUiState voiceUiState = VoiceUiState.connecting;
  bool isConnecting = false;
  bool isDisposed = false;
  bool micEnabled = false;
  bool speakerEnabled = false;
  bool agentConnected = false;
  bool agentAudioActive = false;
  bool agentAudioPlaying = false;
  bool assistantSpeaking = false;
  bool userSpeaking = false;
  int participantsCount = 0;
  double agentAudioLevel = 0;
  double localAudioLevel = 0;
  bool localSpeaking = false;
  String lastLivekitEvent = '';
  String? errorMessage;
  Timer? thinkingTimer;
  Timer? speakingSilenceTimer;
  Timer? levelJitterTimer;

  VoiceCallNotifier({required this.aiChatRemoteDataSource, required this.topicId});

  bool get isConnected => room?.connectionState == ConnectionState.connected;

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
      final tokenModel = await aiChatRemoteDataSource.fetchLivekitToken(topicId: topicId);
      if (isDisposed) return;
      final nextRoom = room ?? Room();
      listenToRoomEvents(nextRoom);
      await nextRoom.connect(tokenModel.url, tokenModel.token,
          roomOptions: const RoomOptions(adaptiveStream: true, dynacast: true));
      if (isDisposed) {
        await nextRoom.disconnect();
        return;
      }
      await nextRoom.localParticipant?.setMicrophoneEnabled(true);
      await nextRoom.setSpeakerOn(true, forceSpeakerOutput: true);
      room = nextRoom;
      micEnabled = true;
      speakerEnabled = true;
      participantsCount = roomParticipantsCount(room);
      agentConnected = agentConnectedValue(room);
      agentAudioActive = agentAudioActiveValue(room);
      setVoiceState(VoiceUiState.listening);
      debugPrint('[Voice] connected');
    } on DioException catch (error) {
      errorMessage = DioErrorMessage.from(error);
      setVoiceState(VoiceUiState.error);
      assistantSpeaking = false;
      userSpeaking = false;
      agentAudioPlaying = false;
      agentAudioActive = false;
    } catch (error) {
      errorMessage = 'Request failed.'.tr();
      setVoiceState(VoiceUiState.error);
      assistantSpeaking = false;
      userSpeaking = false;
      agentAudioPlaying = false;
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
    isConnecting = false;
    if (room == null) {
      resetState();
      return;
    }
    try {
      await room!.localParticipant?.setMicrophoneEnabled(false);
      await room!.disconnect();
    } finally {
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
    await room!.localParticipant?.setMicrophoneEnabled(true);
    await room!.setSpeakerOn(true, forceSpeakerOutput: true);
    micEnabled = true;
    speakerEnabled = true;
    notifyListeners();
  }

  void listenToRoomEvents(Room nextRoom) {
    livekitListener?.dispose();
    livekitListener = nextRoom.createListener();
    livekitListener!.on<RoomConnectedEvent>((event) {
      debugPrint('[LiveKit] room connected');
      room?.setSpeakerOn(true, forceSpeakerOutput: true);
      speakerEnabled = true;
      participantsCount = roomParticipantsCount(nextRoom);
      setLastEvent('Room connected');
    });
    livekitListener!.on<RoomDisconnectedEvent>((event) {
      debugPrint('[LiveKit] room disconnected');
      setLastEvent('Room disconnected');
      setVoiceState(VoiceUiState.error);
      assistantSpeaking = false;
      userSpeaking = false;
      agentAudioPlaying = false;
      agentAudioActive = false;
    });
    livekitListener!.on<ParticipantConnectedEvent>((event) {
      debugPrint('[LiveKit] participant joined: ${event.participant.identity}');
      participantsCount = roomParticipantsCount(nextRoom);
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
        debugPrint('🔥 AGENT AUDIO TRACK RECEIVED from ${event.participant.identity}');
        await track.start();
        debugPrint('[LiveKit] audio playback started');
        await room?.setSpeakerOn(true, forceSpeakerOutput: true);
        speakerEnabled = true;
        agentAudioActive = true;
        agentAudioPlaying = true;
        agentConnected = true;
        setVoiceState(VoiceUiState.speaking);
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
      if (!agentAudioActive) agentAudioPlaying = false;
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
    bool remoteActive = false;
    double maxRemoteLevel = 0;
    double localLevel = 0;
    bool assistantFound = false;

    for (final speaker in speakers) {
      final isLocal = localParticipant != null && speaker.sid == localParticipant.sid;
      if (isLocal) {
        localActive = true;
        localLevel = speaker.audioLevel;
      } else {
        remoteActive = true;
        if (speaker.audioLevel > maxRemoteLevel) maxRemoteLevel = speaker.audioLevel;
        if (speaker.identity == 'ustadia-bot') assistantFound = true;
      }
    }

    localAudioLevel = localLevel;
    agentAudioLevel = maxRemoteLevel;
    assistantSpeaking = remoteActive;
    userSpeaking = localActive;
    if (assistantFound) agentConnected = true;

    bool stateChanged = false;
    if (remoteActive) {
      agentAudioPlaying = true;
      agentAudioActive = true;
      stateChanged = setVoiceState(VoiceUiState.speaking);
      speakingSilenceTimer?.cancel();
    } else if (localActive) {
      localSpeaking = true;
      agentAudioPlaying = false;
      if (voiceUiState != VoiceUiState.connecting && voiceUiState != VoiceUiState.error) {
        stateChanged = setVoiceState(VoiceUiState.listening);
      }
      speakingSilenceTimer?.cancel();
    } else if (localSpeaking) {
      localSpeaking = false;
      agentAudioPlaying = false;
      startThinkingTransition();
    } else if (agentAudioPlaying) {
      agentAudioPlaying = false;
      startListeningTransition();
    }

    updateLevelJitter();
    debugPrint(
        '[VoiceUI] assistantLevel=${agentAudioLevel.toStringAsFixed(2)} userLevel=${localAudioLevel.toStringAsFixed(2)} assistantSpeaking=$assistantSpeaking userSpeaking=$userSpeaking');
    if (!stateChanged) notifyListeners();
  }

  void startThinkingTransition() {
    setVoiceState(VoiceUiState.thinking);
    thinkingTimer?.cancel();
    thinkingTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!agentAudioPlaying) setVoiceState(VoiceUiState.listening);
    });
  }

  void startListeningTransition() {
    speakingSilenceTimer?.cancel();
    speakingSilenceTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!agentAudioPlaying && voiceUiState != VoiceUiState.thinking) {
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

  void resetState() {
    agentConnected = false;
    agentAudioActive = false;
    agentAudioPlaying = false;
    assistantSpeaking = false;
    userSpeaking = false;
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
