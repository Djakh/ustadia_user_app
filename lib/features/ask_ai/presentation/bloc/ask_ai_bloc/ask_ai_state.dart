import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_topic_model.dart';

class AskAiState {
  final Status topicsStatus;
  final Status messagesStatus;
  final Status voiceStatus;
  final List<AiChatTopicModel> topics;
  final List<AiChatMessageModel> messages;
  final AiChatTopicModel? currentTopic;
  final String? errorMessage;
  final String userId;
  final String connectionState;
  final int participantsCount;
  final bool micEnabled;
  final bool speakerEnabled;
  final bool agentConnected;
  final bool agentAudioActive;
  final String lastLivekitEvent;

  const AskAiState(
      {this.topicsStatus = Status.initial,
      this.messagesStatus = Status.initial,
      this.voiceStatus = Status.initial,
      this.topics = const [],
      this.messages = const [],
      this.currentTopic,
      this.errorMessage,
      this.userId = '',
      this.connectionState = 'disconnected',
      this.participantsCount = 0,
      this.micEnabled = false,
      this.speakerEnabled = false,
      this.agentConnected = false,
      this.agentAudioActive = false,
      this.lastLivekitEvent = ''});

  AskAiState copyWith(
      {Status? topicsStatus,
      Status? messagesStatus,
      Status? voiceStatus,
      List<AiChatTopicModel>? topics,
      List<AiChatMessageModel>? messages,
      AiChatTopicModel? currentTopic,
      String? errorMessage,
      String? userId,
      String? connectionState,
      int? participantsCount,
      bool? micEnabled,
      bool? speakerEnabled,
      bool? agentConnected,
      bool? agentAudioActive,
      String? lastLivekitEvent}) {
    return AskAiState(
        topicsStatus: topicsStatus ?? this.topicsStatus,
        messagesStatus: messagesStatus ?? this.messagesStatus,
        voiceStatus: voiceStatus ?? this.voiceStatus,
        topics: topics ?? this.topics,
        messages: messages ?? this.messages,
        currentTopic: currentTopic ?? this.currentTopic,
        errorMessage: errorMessage,
        userId: userId ?? this.userId,
        connectionState: connectionState ?? this.connectionState,
        participantsCount: participantsCount ?? this.participantsCount,
        micEnabled: micEnabled ?? this.micEnabled,
        speakerEnabled: speakerEnabled ?? this.speakerEnabled,
        agentConnected: agentConnected ?? this.agentConnected,
        agentAudioActive: agentAudioActive ?? this.agentAudioActive,
        lastLivekitEvent: lastLivekitEvent ?? this.lastLivekitEvent);
  }
}
