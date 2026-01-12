import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';

import '../../domain/usecases/fetch_posts.dart';
import 'post_event.dart';
import 'post_state.dart';

class PostBloc extends Bloc<PostEvent, PostState> {
  PostBloc({required FetchPosts fetchPosts})
    : _fetchPosts = fetchPosts,
      super(const PostState()) {
    on<PostRequested>(_onPostRequested);
  }

  final FetchPosts _fetchPosts;

  Future<void> _onPostRequested(
    PostRequested event,
    Emitter<PostState> emit,
  ) async {
    emit(state.copyWith(status: Status.loading));
    try {
      final posts = await _fetchPosts();
      emit(
        state.copyWith(
          status: Status.success,
          posts: posts,
          errorMessage: null,
        ),
      );
    } catch (error) {
      emit(
        state.copyWith(
          status: Status.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }
}
