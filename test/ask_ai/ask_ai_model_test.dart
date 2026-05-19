import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_message_model.dart';
import 'package:ustadia_user_app/features/ask_ai/data/models/ai_chat_topic_model.dart';

void main() {
  group('AiChatTopicModel', () {
    test('parses numeric duration variants', () {
      expect(AiChatTopicModel.fromJson({'duration': 12}).duration, 12);
      expect(AiChatTopicModel.fromJson({'duration': 12.9}).duration, 12);
      expect(AiChatTopicModel.fromJson({'duration': '15'}).duration, 15);
      expect(AiChatTopicModel.fromJson({'duration': null}).duration, 0);
    });
  });

  group('AiChatMessageModel', () {
    test('parses snake case fields and string boolean values', () {
      final message = AiChatMessageModel.fromJson({
        'topic_id': 'topic-1',
        'user_id': 'user-1',
        'role': 'assistant',
        'content': 'Done',
        'createdAt': '2026-05-19T10:00:00.000Z',
        'isFinished': 'true'
      });

      expect(message.topicId, 'topic-1');
      expect(message.userId, 'user-1');
      expect(message.isFinished, isTrue);
      expect(message.createdAt.toUtc().year, 2026);
    });
  });
}
