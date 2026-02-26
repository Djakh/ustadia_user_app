import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_topic_model.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/livekit_token_model.dart';

class AiChatRemoteDataSource {
  final Dio dio;

  AiChatRemoteDataSource({required this.dio});

  Future<List<AiChatTopicModel>> fetchTopics({required int page, required int limit}) async {
    final response = await dio.get('/student/ai-chat/topics',
        queryParameters: {'page': page, 'limit': limit});
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().map(AiChatTopicModel.fromJson).toList();
  }

  Future<List<AiChatMessageModel>> fetchMessages(
      {required String topicId, required int page, required int limit}) async {
    final response = await dio.get('/student/ai-chat/topics/$topicId/messages',
        queryParameters: {'page': page, 'limit': limit});
    final data = response.data as Map<String, dynamic>;
    final items = data['messages'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().map(AiChatMessageModel.fromJson).toList();
  }

  Future<LivekitTokenModel> fetchLivekitToken({required String topicId}) async {
    final response = await dio.post('/student/ai-chat/livekit/token', data: {'topicId': topicId});
    return LivekitTokenModel.fromJson(response.data as Map<String, dynamic>);
  }
}
