import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_topic_model.dart';

abstract class AskAiEvent {
  const AskAiEvent();
}

class AskAiTopicsRequested extends AskAiEvent {
  const AskAiTopicsRequested();
}

class AskAiTopicOpened extends AskAiEvent {
  final AiChatTopicModel topic;

  const AskAiTopicOpened({required this.topic});
}

class AskAiMessagesRequested extends AskAiEvent {
  final String topicId;
  final int page;
  final int limit;

  const AskAiMessagesRequested({required this.topicId, required this.page, required this.limit});
}

class AskAiVoiceConnectRequested extends AskAiEvent {
  const AskAiVoiceConnectRequested();
}

class AskAiVoiceDisconnectRequested extends AskAiEvent {
  const AskAiVoiceDisconnectRequested();
}

class AskAiVoiceMicToggled extends AskAiEvent {
  const AskAiVoiceMicToggled();
}

class AskAiVoiceSpeakerToggled extends AskAiEvent {
  const AskAiVoiceSpeakerToggled();
}

class AskAiRoomUpdated extends AskAiEvent {
  const AskAiRoomUpdated();
}

class AskAiLivekitEventReported extends AskAiEvent {
  final String lastLivekitEvent;
  final bool? agentConnected;
  final bool? agentAudioActive;

  const AskAiLivekitEventReported(
      {required this.lastLivekitEvent, this.agentConnected, this.agentAudioActive});
}
