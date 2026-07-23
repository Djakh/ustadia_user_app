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
    expect(listenTap.questions, hasLength(2));
    expect(listenTap.questions.first.options.single.word, 'Hello');
    expect(wordMatch.options, hasLength(2));
    expect(wordMatch.options.first.match, isNull);
    expect(sentenceBuilder.questions, hasLength(2));
    expect(sentenceBuilder.questions.first.correctOrder, ['I', 'learn']);
    expect(monkeyType.texts.single.text, 'Typing detail text');
    expect(monkeyType.monkeyTypeUrl, 'https://students.ustadia.com/monkey-type/monkey_1');
  });

  test('list endpoints accept documented paginated items responses', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response<Map<String, dynamic>>(requestOptions: options, data: {
        'items': [
          {'id': 'set_1', 'title': 'Set one'}
        ],
        'total': 1,
        'page': 1,
        'limit': 10,
        'totalPages': 1,
      }));
    }));
    final dataSource = PracticeRemoteDataSource(dio: dio);

    expect(await dataSource.fetchFlashcardSets(), hasLength(1));
    expect(await dataSource.fetchListenTapSets(), hasLength(1));
    expect(await dataSource.fetchWordMatchSets(), hasLength(1));
    expect(await dataSource.fetchSentenceBuilderSets(), hasLength(1));
    expect(await dataSource.fetchMonkeyTypePractices(), hasLength(1));
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

  test('practice detail models keep every question from snake case responses', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response<Map<String, dynamic>>(
          requestOptions: options, data: {'data': _snakeCaseResponseFor(options.path)}));
    }));
    final dataSource = PracticeRemoteDataSource(dio: dio);

    final listenTap = await dataSource.fetchListenTapSet('listen_1');
    final wordMatch = await dataSource.fetchWordMatchSet('words_1');
    final sentenceBuilder = await dataSource.fetchSentenceBuilderSet('sentence_1');

    expect(listenTap.questions, hasLength(2));
    expect(listenTap.questions.first.options.single.isCorrect, isTrue);
    expect(wordMatch.options, hasLength(4));
    expect(sentenceBuilder.questions, hasLength(2));
    expect(sentenceBuilder.questions.last.correctOrder, ['You', 'practice']);
  });

  test('practice detail models parse documented response examples', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://example.com'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      handler.resolve(Response<Map<String, dynamic>>(
          requestOptions: options, data: _documentedResponseFor(options.path)));
    }));
    final dataSource = PracticeRemoteDataSource(dio: dio);

    final listenTap = await dataSource.fetchListenTapSet('listen_1');
    final wordMatch = await dataSource.fetchWordMatchSet('words_1');
    final sentenceBuilder = await dataSource.fetchSentenceBuilderSet('sentence_1');

    expect(listenTap.questions.single.options.first.word, 'Dog');
    expect(listenTap.questions.single.options.first.isCorrect, isTrue);
    expect(wordMatch.options, hasLength(2));
    expect(wordMatch.options.first.word, 'Red');
    expect(wordMatch.options.first.match, 'Qizil');
    expect(sentenceBuilder.questions.single.correctOrder, ['He', 'said']);
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
        },
        {
          'id': 'listen_question_2',
          'listenTapId': 'listen_1',
          'order': 2,
          'options': [
            {
              'id': 'listen_option_2',
              'listenTapQuestionId': 'listen_question_2',
              'word': 'Bye',
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
        },
        {
          'id': 'sentence_question_2',
          'sentenceBuilderId': 'sentence_1',
          'order': 2,
          'words': [
            {'id': 'word_4', 'word': 'practice', 'correctPosition': 2, 'order': 1},
            {'id': 'word_3', 'word': 'You', 'correctPosition': 1, 'order': 2},
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

Map<String, dynamic> _snakeCaseResponseFor(String path) {
  if (path.contains('/listen-tap/')) {
    return {
      'id': 'listen_1',
      'title': 'Listen',
      'total_questions': 2,
      'listen_tap_questions': [
        {
          'id': 'listen_question_1',
          'listen_tap_id': 'listen_1',
          'order_index': 1,
          'options': [
            {
              'id': 'listen_option_1',
              'listen_tap_question_id': 'listen_question_1',
              'word': 'Hello',
              'is_correct': true,
              'order_index': 1,
            }
          ]
        },
        {
          'id': 'listen_question_2',
          'listen_tap_id': 'listen_1',
          'order_index': 2,
          'options': [
            {
              'id': 'listen_option_2',
              'listen_tap_question_id': 'listen_question_2',
              'word': 'Bye',
              'is_correct': true,
              'order_index': 1,
            }
          ]
        },
      ],
    };
  }
  if (path.contains('/word-match/')) {
    return {
      'id': 'words_1',
      'title': 'Words',
      'word_match_questions': [
        {
          'id': 'word_question_1',
          'options': [
            {'id': 'source_1', 'word': 'Hello', 'type': 'source', 'pair_id': 1, 'order_index': 1},
            {'id': 'target_1', 'word': 'Salom', 'type': 'target', 'pair_id': 1, 'order_index': 2},
          ]
        },
        {
          'id': 'word_question_2',
          'options': [
            {'id': 'source_2', 'word': 'Bye', 'type': 'source', 'pair_id': 2, 'order_index': 3},
            {'id': 'target_2', 'word': 'Xayr', 'type': 'target', 'pair_id': 2, 'order_index': 4},
          ]
        },
      ],
    };
  }
  if (path.contains('/sentence-builder/')) {
    return {
      'id': 'sentence_1',
      'title': 'Sentence',
      'total_questions': 2,
      'sentence_builder_questions': [
        {
          'id': 'sentence_question_1',
          'sentence_builder_id': 'sentence_1',
          'order_index': 1,
          'sentence_builder_words': [
            {'id': 'word_2', 'word': 'learn', 'correct_position': 2, 'order_index': 1},
            {'id': 'word_1', 'word': 'I', 'correct_position': 1, 'order_index': 2},
          ]
        },
        {
          'id': 'sentence_question_2',
          'sentence_builder_id': 'sentence_1',
          'order_index': 2,
          'sentence_builder_words': [
            {'id': 'word_4', 'word': 'practice', 'correct_position': 2, 'order_index': 1},
            {'id': 'word_3', 'word': 'You', 'correct_position': 1, 'order_index': 2},
          ]
        },
      ],
    };
  }
  return _flashcardResponse;
}

Map<String, dynamic> _documentedResponseFor(String path) {
  if (path.contains('/listen-tap/')) {
    return {
      'id': 'listen_1',
      'title': 'Animals',
      'description': 'Identify animals by sound',
      'status': 'not_completed',
      'questions': [
        {
          'id': 'question_1',
          'text': 'Which animal is this?',
          'audio': {'id': 'audio_1', 'url': 'path/to/audio.mp3'},
          'options': [
            {'id': 'option_1', 'text': 'Dog', 'isCorrect': true},
            {'id': 'option_2', 'text': 'Cat', 'isCorrect': false},
          ],
          'order': 0,
        }
      ],
    };
  }
  if (path.contains('/word-match/')) {
    return {
      'id': 'words_1',
      'title': 'Colors',
      'description': 'Match color words with translations',
      'status': 'not_completed',
      'difficulty': {
        'id': 'difficulty_1',
        'name': {'en': 'Elementary', 'uz': 'Boshlangʻich'},
      },
      'options': [
        {'id': 'option_1', 'word': 'Red', 'match': 'Qizil', 'order': 0},
        {'id': 'option_2', 'word': 'Blue', 'match': 'Koʻk', 'order': 1},
      ],
    };
  }
  if (path.contains('/sentence-builder/')) {
    return {
      'id': 'sentence_1',
      'title': 'Reported Speech',
      'description': 'He said that ___',
      'status': 'not_completed',
      'questions': [
        {
          'id': 'question_1',
          'hint': 'Said / he',
          'translation': 'He said.',
          'order': 0,
          'words': [
            {'id': 'word_1', 'word': 'He', 'correctPosition': 0, 'order': 0},
            {'id': 'word_2', 'word': 'said', 'correctPosition': 1, 'order': 1},
          ],
        }
      ],
    };
  }
  return _flashcardResponse;
}
