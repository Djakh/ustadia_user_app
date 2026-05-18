import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/core/pagination/pagination_result.dart';
import 'package:ustadia_user_app/features/reels/data/models/reel_post_model.dart';
import 'package:ustadia_user_app/features/reels/data/models/reel_user_profile_model.dart';

class ReelsRemoteDataSource {
  final Dio dio;

  ReelsRemoteDataSource({required this.dio});

  Options get freshRequestOptions =>
      CacheOptions(policy: CachePolicy.noCache, store: MemCacheStore()).toOptions();

  Future<PaginationResult<ReelPostModel>> fetchPosts({int page = 1, int limit = 20}) async {
    final response = await dio.get('/feed/posts', options: freshRequestOptions);
    if (response.data is List) {
      final posts = (response.data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(ReelPostModel.fromJson)
          .toList();
      return PaginationResult(
          items: posts,
          meta: PaginationMeta(page: 1, limit: posts.length, total: posts.length, totalPages: 1));
    }

    final responseData = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final data = responseData['data'] is Map<String, dynamic>
        ? responseData['data'] as Map<String, dynamic>
        : responseData;
    final items = data['items'] as List<dynamic>? ?? const [];
    final posts = items.whereType<Map<String, dynamic>>().map(ReelPostModel.fromJson).toList();
    return PaginationResult(items: posts, meta: PaginationMeta.fromJson(data));
  }

  Future<PaginationResult<ReelCommentModel>> fetchComments({
    required String postId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dio.get('/feed/posts/$postId/comments',
        queryParameters: {'page': page, 'limit': limit}, options: freshRequestOptions);
    if (response.data is List) {
      final comments = (response.data as List<dynamic>)
          .whereType<Map<String, dynamic>>()
          .map(ReelCommentModel.fromJson)
          .toList();
      return PaginationResult(
          items: comments,
          meta: PaginationMeta(page: page, limit: limit, total: comments.length, totalPages: page));
    }

    final responseData = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final data = responseData['data'] is Map<String, dynamic>
        ? responseData['data'] as Map<String, dynamic>
        : responseData;
    final items = _listFrom(data['items'] ?? data['comments'] ?? responseData['comments']);
    final comments =
        items.whereType<Map<String, dynamic>>().map(ReelCommentModel.fromJson).toList();
    final metaData =
        data.containsKey('items') || data.containsKey('comments') ? data : responseData;
    return PaginationResult(items: comments, meta: PaginationMeta.fromJson(metaData));
  }

  Future<ReelUserProfileModel> fetchUserProfile({
    required String userId,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await dio.get('/feed/users/$userId/profile',
        queryParameters: {'page': page, 'limit': limit}, options: freshRequestOptions);
    final responseData = response.data is Map<String, dynamic>
        ? response.data as Map<String, dynamic>
        : <String, dynamic>{};
    final data = responseData['data'] is Map<String, dynamic>
        ? responseData['data'] as Map<String, dynamic>
        : responseData;
    return ReelUserProfileModel.fromJson(data);
  }

  Future<void> likePost(String postId) async {
    await dio.post('/feed/posts/$postId/like');
  }

  Future<void> unlikePost(String postId) async {
    await dio.delete('/feed/posts/$postId/like');
  }

  Future<ReelCommentModel> createComment({
    required String postId,
    required String text,
    String? parentCommentId,
  }) async {
    final response = await dio.post('/feed/posts/$postId/comments', data: {
      'text': text,
      if (parentCommentId != null && parentCommentId.isNotEmpty) 'parentCommentId': parentCommentId,
    });
    final data = response.data as Map<String, dynamic>;
    final comment = data['comment'] is Map<String, dynamic>
        ? data['comment'] as Map<String, dynamic>
        : data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : data;
    return ReelCommentModel.fromJson(comment);
  }
}

List<dynamic> _listFrom(dynamic value) => value is List ? value : const [];
