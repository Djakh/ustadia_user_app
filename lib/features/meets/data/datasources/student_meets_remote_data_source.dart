import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/core/pagination/pagination_result.dart';
import 'package:ustadia_user_app/features/meets/data/models/student_meet_model.dart';

class StudentMeetsRemoteDataSource {
  final Dio dio;

  StudentMeetsRemoteDataSource({required this.dio});

  Options get freshRequestOptions =>
      CacheOptions(policy: CachePolicy.noCache, store: MemCacheStore()).toOptions();

  Future<PaginationResult<StudentMeetModel>> fetchMeets({int page = 1, int limit = 10}) async {
    final response = await dio.get('/students/meets',
        queryParameters: {'page': page, 'limit': limit}, options: freshRequestOptions);
    final data = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final items = data['items'] as List<dynamic>? ?? [];
    final meets = items.whereType<Map<String, dynamic>>().map(StudentMeetModel.fromJson).toList();
    return PaginationResult(items: meets, meta: PaginationMeta.fromJson(data));
  }
}
