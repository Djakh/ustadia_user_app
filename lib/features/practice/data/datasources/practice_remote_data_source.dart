import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_listen_tap_set_model.dart';
import 'package:ustadia_user_app/features/practice/data/models/practice_listen_tap_status_response.dart';

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

  Future<PracticeListenTapStatusResponse> updateListenTapStatus({
    required String listenTapId,
    required String status,
  }) async {
    final response = await dio.patch(
      '/students/practice/listen-tap/$listenTapId/status',
      data: {'status': status},
    );
    final data = response.data as Map<String, dynamic>;
    return PracticeListenTapStatusResponse.fromJson(data);
  }
}
