import '../entities/post.dart';
import '../repositories/post_repository.dart';

class FetchPosts {
  FetchPosts(this.repository);

  final PostRepository repository;

  Future<List<Post>> call() => repository.fetchPosts();
}
