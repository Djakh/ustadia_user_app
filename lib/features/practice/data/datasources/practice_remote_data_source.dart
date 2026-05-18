import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/practice/data/models/monkey_type_model.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_listen_tap_set_model.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_listen_tap_status_response.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_sentence_builder_set_model.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_sentence_builder_status_response.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_word_match_set_model.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_word_match_status_response.dart';

class PracticeRemoteDataSource {
  final Dio dio;

  PracticeRemoteDataSource({required this.dio});

  Future<List<LearnFlashcardSetModel>> fetchFlashcardSets() async {
    final response = await dio.get('/students/practice/flashcards');
    final data = response.data;
    final items =
        data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().map(LearnFlashcardSetModel.fromJson).toList();
  }

  Future<List<PracticeListenTapSetModel>> fetchListenTapSets() async {
    final response = await dio.get('/students/practice/listen-tap');
    final data = response.data;
    final items =
        data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().map(PracticeListenTapSetModel.fromJson).toList();
  }

  Future<List<PracticeWordMatchSetModel>> fetchWordMatchSets() async {
    final response = await dio.get('/students/practice/word-match');
    final data = response.data;
    final items =
        data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().map(PracticeWordMatchSetModel.fromJson).toList();
  }

  Future<List<PracticeSentenceBuilderSetModel>> fetchSentenceBuilderSets() async {
    final response = await dio.get('/students/practice/sentence-builder');
    final data = response.data;
    final items =
        data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(PracticeSentenceBuilderSetModel.fromJson)
        .toList();
  }

  Future<List<MonkeyTypePracticeModel>> fetchMonkeyTypePractices() async {
    final response = await dio.get('/student/monkey-type');
    final data = response.data;
    final items =
        data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().map(MonkeyTypePracticeModel.fromJson).toList();
  }

  Future<List<MonkeyTypeTextModel>> fetchMonkeyTypeTexts(String practiceId) async {
    final detailResponse = await dio.get('/student/monkey-type/$practiceId');
    final detailData = detailResponse.data;
    final detail = detailData is Map<String, dynamic>
        ? detailData['data'] is Map<String, dynamic>
            ? detailData['data'] as Map<String, dynamic>
            : detailData
        : <String, dynamic>{};
    final detailTexts = _listFrom(detail['texts'])
        .whereType<Map<String, dynamic>>()
        .map(MonkeyTypeTextModel.fromJson)
        .toList();
    if (detailTexts.isNotEmpty) {
      detailTexts.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
      return detailTexts;
    }

    final response = await dio.get('/student/monkey-type/$practiceId/texts');
    final data = response.data;
    final items =
        data is List ? data : _listFrom((data as Map<String, dynamic>)['data'] ?? data['texts']);
    final texts =
        items.whereType<Map<String, dynamic>>().map(MonkeyTypeTextModel.fromJson).toList();
    texts.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return texts;
  }

  Future<MonkeyTypeAnswerModel> submitMonkeyTypeAnswer({
    required String practiceId,
    required String text,
    required double wpm,
    required double accuracy,
    required int correctChars,
    required int totalChars,
    required int timeTakenSeconds,
  }) async {
    final response = await dio.post('/student/monkey-type/$practiceId/answers', data: {
      'text': text,
      'wpm': wpm,
      'accuracy': accuracy,
      'correct_chars': correctChars,
      'total_chars': totalChars,
      'time_taken_seconds': timeTakenSeconds,
    });
    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final answer =
        data['data'] is Map<String, dynamic> ? data['data'] as Map<String, dynamic> : data;
    return MonkeyTypeAnswerModel.fromJson(answer);
  }

  Future<PracticeSentenceBuilderStatusResponse> updateSentenceBuilderStatus({
    required String sentenceBuilderId,
    required String status,
    required int correctAnswers,
    required int wrongAnswers,
  }) async {
    final response = await dio.patch(
      '/students/practice/sentence-builder/$sentenceBuilderId/status',
      data: {
        'status': status,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return PracticeSentenceBuilderStatusResponse.fromJson(data);
  }

  Future<PracticeWordMatchStatusResponse> updateWordMatchStatus({
    required String wordMatchId,
    required String status,
    required int correctAnswers,
    required int wrongAnswers,
  }) async {
    final response = await dio.patch(
      '/students/practice/word-match/$wordMatchId/status',
      data: {
        'status': status,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return PracticeWordMatchStatusResponse.fromJson(data);
  }

  Future<PracticeListenTapStatusResponse> updateListenTapStatus({
    required String listenTapId,
    required String status,
    required int correctAnswers,
    required int wrongAnswers,
  }) async {
    final response = await dio.patch(
      '/students/practice/listen-tap/$listenTapId/status',
      data: {
        'status': status,
        'correctAnswers': correctAnswers,
        'wrongAnswers': wrongAnswers,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return PracticeListenTapStatusResponse.fromJson(data);
  }
}

List<dynamic> _listFrom(dynamic value) => value is List ? value : const [];
