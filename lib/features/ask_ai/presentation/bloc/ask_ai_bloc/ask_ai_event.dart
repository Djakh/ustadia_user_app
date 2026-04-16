import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_topic_model.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';

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

class AskAiMessageReceived extends AskAiEvent {
  final AiChatMessageModel message;

  const AskAiMessageReceived({required this.message});
}
