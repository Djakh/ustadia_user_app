import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_topic_model.dart';

class AskAiState {
  final Status topicsStatus;
  final Status messagesStatus;
  final List<AiChatTopicModel> topics;
  final List<AiChatMessageModel> messages;
  final AiChatTopicModel? currentTopic;
  final String? errorMessage;
  final String userId;

  const AskAiState(
      {this.topicsStatus = Status.initial,
      this.messagesStatus = Status.initial,
      this.topics = const [],
      this.messages = const [],
      this.currentTopic,
      this.errorMessage,
      this.userId = ''});

  AskAiState copyWith(
      {Status? topicsStatus,
      Status? messagesStatus,
      List<AiChatTopicModel>? topics,
      List<AiChatMessageModel>? messages,
      AiChatTopicModel? currentTopic,
      String? errorMessage,
      String? userId}) {
    return AskAiState(
        topicsStatus: topicsStatus ?? this.topicsStatus,
        messagesStatus: messagesStatus ?? this.messagesStatus,
        topics: topics ?? this.topics,
        messages: messages ?? this.messages,
        currentTopic: currentTopic ?? this.currentTopic,
        errorMessage: errorMessage,
        userId: userId ?? this.userId);
  }
}
