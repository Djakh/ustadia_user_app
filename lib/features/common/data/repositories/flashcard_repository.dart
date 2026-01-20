import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flashcard_status_response.dart';

abstract class FlashcardRepository {
  Future<FlashcardStatusResponse> updateFlashcardStatus({
    required String flashcardId,
    required String status,
  });
}

class FlashcardRepositoryImpl implements FlashcardRepository {
  final Dio dio;

  FlashcardRepositoryImpl({required this.dio});

  @override
  Future<FlashcardStatusResponse> updateFlashcardStatus({
    required String flashcardId,
    required String status,
  }) async {
    final response = await dio.patch(
      '/students/sections/flashcards/$flashcardId/status',
      data: {'status': status},
    );
    final data = response.data as Map<String, dynamic>;
    return FlashcardStatusResponse.fromJson(data);
  }
}
