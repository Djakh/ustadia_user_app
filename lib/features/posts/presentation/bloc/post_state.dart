import 'package:equatable/equatable.dart';

import '../../domain/entities/post.dart';

enum PostStatus { initial, loading, success, failure }

class PostState extends Equatable {
  const PostState({
    this.status = PostStatus.initial,
    this.posts = const [],
    this.errorMessage,
  });

  final PostStatus status;
  final List<Post> posts;
  final String? errorMessage;

  PostState copyWith({
    PostStatus? status,
    List<Post>? posts,
    String? errorMessage,
  }) {
    return PostState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, posts, errorMessage];
}
