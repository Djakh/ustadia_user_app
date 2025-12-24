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


class Task {
  final String name;
  final int priority;

  Task(this.name, this.priority);
}

void main() {
  final tasks = [
    Task('task1', 1),
    Task('task2', 2),
    Task('task3', 3),
  ];

  tasks.executeInOrder(
    (t) => t.priority,
    (t) {
      print(t.name);
      return t.name == 'task2';
    },
  );
}

extension ExecuteInOrder<T> on List<T> {
  void executeInOrder(
    int Function(T) order,
    bool Function(T) process,
  ) {
    final sorted = [...this]..sort((a, b) => order(a).compareTo(order(b)));

    for (final item in sorted) {
      final shouldStop = process(item);
      if (shouldStop) break;
    }
  }
}
