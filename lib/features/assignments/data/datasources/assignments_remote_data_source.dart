import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:ustadia_user_app/features/assignments/data/models/assignment_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_stats_model.dart';

class AssignmentsRemoteDataSource {
  final Dio dio;

  AssignmentsRemoteDataSource({required this.dio});

  Options get freshRequestOptions =>
      CacheOptions(policy: CachePolicy.noCache, store: MemCacheStore()).toOptions();

  Future<List<AssignmentModel>> fetchAssignments() async {
    final response = await dio.get('/students/assignments', options: freshRequestOptions);
    final data = response.data;
    final items =
        data is List ? data : (data as Map<String, dynamic>)['items'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().map(AssignmentModel.fromJson).toList();
  }

  Future<SectionModel> fetchAssignmentSectionDetail(
      {required String assignmentId, required String sectionId}) async {
    final response = await dio.get('/students/assignments/$assignmentId/sections/$sectionId',
        options: freshRequestOptions);
    final data = response.data as Map<String, dynamic>;
    return SectionModel.fromJson(data);
  }

  Future<List<SectionModel>> fetchAssignmentSections({required String assignmentId}) async {
    final response =
        await dio.get('/students/assignments/$assignmentId/sections', options: freshRequestOptions);
    final data = response.data;
    final items =
        data is List ? data : (data as Map<String, dynamic>)['data'] as List<dynamic>? ?? [];
    return items.whereType<Map<String, dynamic>>().map(SectionModel.fromJson).toList();
  }

  Future<SectionStatsModel> fetchAssignmentSectionStats(
      {required String assignmentId, required String sectionId}) async {
    final response = await dio.get('/students/assignments/$assignmentId/sections/$sectionId/stats',
        options: freshRequestOptions);
    final data = response.data as Map<String, dynamic>;
    return SectionStatsModel.fromJson(data);
  }

  Future<Map<String, dynamic>> submitAssignmentAnswers(
      {required String assignmentId, required List<Map<String, dynamic>> answers}) async {
    final response =
        await dio.post('/students/assignments/$assignmentId/submit', data: {'answers': answers});
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    return const {};
  }
}
