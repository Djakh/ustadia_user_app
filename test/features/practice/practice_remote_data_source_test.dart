import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/practice/data/datasources/practice_remote_data_source.dart';

void main() {
  test('active practice sessions fetch detail by set id', () async {
    final requestedPaths = <String>[];
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requestedPaths.add(options.path);
      handler.resolve(Response<Map<String, dynamic>>(
          requestOptions: options, data: {'data': _responseFor(options.path)}));
    }));
    final dataSource = PracticeRemoteDataSource(dio: dio);

    final flashcards = await dataSource.fetchFlashcardSet('flashcards_1');
    final listenTap = await dataSource.fetchListenTapSet('listen_1');
    final wordMatch = await dataSource.fetchWordMatchSet('words_1');
    final sentenceBuilder = await dataSource.fetchSentenceBuilderSet('sentence_1');
    final monkeyType = await dataSource.fetchMonkeyTypePractice('monkey_1');

    expect(requestedPaths, [
      '/students/practice/flashcards/flashcards_1',
      '/students/practice/listen-tap/listen_1',
      '/students/practice/word-match/words_1',
      '/students/practice/sentence-builder/sentence_1',
      '/student/monkey-type/monkey_1',
    ]);
    expect(flashcards.flashcards.single.front, 'Hello');
    expect(listenTap.questions.single.options.single.word, 'Hello');
    expect(wordMatch.options, hasLength(2));
    expect(sentenceBuilder.questions.single.correctOrder, ['I', 'learn']);
    expect(monkeyType.texts.single.text, 'Typing detail text');
    expect(monkeyType.monkeyTypeUrl, 'https://students.ustadia.com/monkey-type/monkey_1');
  });

  test('practice detail accepts an unwrapped response object', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(
          Response<Map<String, dynamic>>(requestOptions: options, data: _flashcardResponse));
    }));

    final detail = await PracticeRemoteDataSource(dio: dio).fetchFlashcardSet('flashcards_1');

    expect(detail.id, 'flashcards_1');
    expect(detail.flashcards, hasLength(1));
  });
}

Map<String, dynamic> _responseFor(String path) {
  if (path.contains('/flashcards/')) return _flashcardResponse;
  if (path.contains('/listen-tap/')) {
    return {
      'id': 'listen_1',
      'title': 'Listen',
      'questions': [
        {
          'id': 'listen_question_1',
          'listenTapId': 'listen_1',
          'order': 1,
          'options': [
            {
              'id': 'listen_option_1',
              'listenTapQuestionId': 'listen_question_1',
              'word': 'Hello',
              'isCorrect': true,
              'order': 1,
            }
          ]
        }
      ]
    };
  }
  if (path.contains('/word-match/')) {
    return {
      'id': 'words_1',
      'title': 'Words',
      'options': [
        {'id': 'source_1', 'word': 'Hello', 'type': 'source', 'pairId': 1, 'order': 1},
        {'id': 'target_1', 'word': 'Salom', 'type': 'target', 'pairId': 1, 'order': 2},
      ]
    };
  }
  if (path.contains('/sentence-builder/')) {
    return {
      'id': 'sentence_1',
      'title': 'Sentence',
      'questions': [
        {
          'id': 'sentence_question_1',
          'sentenceBuilderId': 'sentence_1',
          'order': 1,
          'words': [
            {'id': 'word_2', 'word': 'learn', 'correctPosition': 2, 'order': 1},
            {'id': 'word_1', 'word': 'I', 'correctPosition': 1, 'order': 2},
          ]
        }
      ]
    };
  }
  if (path.contains('/monkey-type/')) {
    return {
      'id': 'monkey_1',
      'title': 'Monkey Type',
      'monkeyTypeUrl': 'https://students.ustadia.com/monkey-type/monkey_1',
      'texts': [
        {
          'id': 'text_1',
          'practice_id': 'monkey_1',
          'text': 'Typing detail text',
          'order_index': 1,
        }
      ]
    };
  }
  throw StateError('Unexpected path: $path');
}

const Map<String, dynamic> _flashcardResponse = {
  'id': 'flashcards_1',
  'title': 'Flashcards',
  'flashcards': [
    {'id': 'card_1', 'front': 'Hello', 'back': 'Salom', 'order': 1, 'status': 'new'}
  ]
};
