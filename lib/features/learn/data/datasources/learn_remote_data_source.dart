import 'package:dio/dio.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/core/pagination/pagination_result.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_lesson_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_question_answer_result_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_unit_model.dart';

class LearnRemoteDataSource {
  final Dio dio;

  LearnRemoteDataSource({required this.dio});

  Future<List<LearnLessonModel>> fetchLessons({int page = 1, int limit = 10}) async {
    final response = await dio.get('/students/lessons', queryParameters: {'page': page, 'limit': limit});
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? [];
    final lessons = items
        .whereType<Map<String, dynamic>>()
        .map(LearnLessonModel.fromJson)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    return lessons;
  }

  Future<List<LearnUnitModel>> fetchUnits({required String lessonId, int page = 1, int limit = 10}) async {
    final response = await dio.get('/students/units',
        queryParameters: {'lessonId': lessonId, 'page': page, 'limit': limit});
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? [];
    final units = items
        .whereType<Map<String, dynamic>>()
        .map(LearnUnitModel.fromJson)
        .toList()
      ..sort((a, b) => a.unitNumber.compareTo(b.unitNumber));
    return units;
  }

  Future<PaginationResult<LearnSectionModel>> fetchSections(
      {required String unitId, int page = 1, int limit = 10}) async {
    final response = await dio.get('/students/sections',
        queryParameters: {'unitId': unitId, 'page': page, 'limit': limit});
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? [];
    final sections = items
        .whereType<Map<String, dynamic>>()
        .map(LearnSectionModel.fromJson)
        .toList()
      ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final meta = PaginationMeta.fromJson(data);
    return PaginationResult(items: sections, meta: meta);
  }

  Future<LearnSectionModel> fetchSectionDetail({required String sectionId}) async {
    final response = await dio.get('/students/sections/$sectionId');
    final data = response.data as Map<String, dynamic>;
    return LearnSectionModel.fromJson(data);
  }

  Future<LearnQuestionAnswerResultModel> submitQuestionAnswer({
    required String sectionId,
    required String questionId,
    String? answerId,
    String? userInputText,
    String? userAudioId,
  }) async {
    final response = await dio.post(
      '/students/sections/$sectionId/questions/$questionId/answer',
      data: {
        'question_id': questionId,
        'answer_id': answerId,
        'user_input_text': userInputText,
        'user_audio_id': userAudioId,
      },
    );
    final data = response.data as Map<String, dynamic>;
    return LearnQuestionAnswerResultModel.fromJson(data);
  }
}
