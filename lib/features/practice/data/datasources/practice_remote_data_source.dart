import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
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
    final items = data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(LearnFlashcardSetModel.fromJson)
        .toList();
  }

  Future<List<PracticeListenTapSetModel>> fetchListenTapSets() async {
    final response = await dio.get('/students/practice/listen-tap');
    final data = response.data;
    final items = data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(PracticeListenTapSetModel.fromJson)
        .toList();
  }

  Future<List<PracticeWordMatchSetModel>> fetchWordMatchSets() async {
    final response = await dio.get('/students/practice/word-match');
    final data = response.data;
    final items = data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(PracticeWordMatchSetModel.fromJson)
        .toList();
  }

  Future<List<PracticeSentenceBuilderSetModel>> fetchSentenceBuilderSets() async {
    final response = await dio.get('/students/practice/sentence-builder');
    final data = response.data;
    final items = data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items
        .whereType<Map<String, dynamic>>()
        .map(PracticeSentenceBuilderSetModel.fromJson)
        .toList();
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
