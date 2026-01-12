import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import '../../domain/entities/post.dart';

class PostState extends Equatable {
  const PostState({
    this.status = Status.initial,
    this.posts = const [],
    this.errorMessage
  });

  final Status status;
  final List<Post> posts;
  final String? errorMessage;

  PostState copyWith({
    Status? status,
    List<Post>? posts,
    String? errorMessage
  }) {
    return PostState(
      status: status ?? this.status,
      posts: posts ?? this.posts,
      errorMessage: errorMessage
    );
  }

  @override
  List<Object?> get props => [status, posts, errorMessage];
}
