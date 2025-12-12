import 'package:dio/dio.dart';

import '../models/post_model.dart';

abstract class PostRemoteDataSource {
  Future<List<PostModel>> fetchPosts();
}

class PostRemoteDataSourceImpl implements PostRemoteDataSource {
  PostRemoteDataSourceImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<PostModel>> fetchPosts() async {
    final response = await _dio.get('/posts');
    final data = response.data as List<dynamic>;
    return data
        .map((json) => PostModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
