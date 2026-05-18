import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/features/reels/data/datasources/reels_remote_data_source.dart';
import 'package:ustadia_user_app/features/reels/data/models/reel_post_model.dart';
import 'package:ustadia_user_app/features/reels/presentation/bloc/reels_bloc/reels_event.dart';
import 'package:ustadia_user_app/features/reels/presentation/bloc/reels_bloc/reels_state.dart';

class ReelsBloc extends Bloc<ReelsEvent, ReelsState> {
  final ReelsRemoteDataSource reelsRemoteDataSource;

  ReelsBloc({required this.reelsRemoteDataSource}) : super(const ReelsState()) {
    on<ReelsRequested>(handleReelsRequested);
    on<ReelsSeeded>(handleReelsSeeded);
    on<ReelsLoadMoreRequested>(handleReelsLoadMoreRequested);
    on<ReelCommentsRequested>(handleReelCommentsRequested);
    on<ReelCommentsLoadMoreRequested>(handleReelCommentsLoadMoreRequested);
    on<ReelLikeToggled>(handleReelLikeToggled);
    on<ReelCommentSubmitted>(handleReelCommentSubmitted);
  }

  Future<void> handleReelsRequested(ReelsRequested event, Emitter<ReelsState> emit) async {
    if (event.showLoading || state.posts.isEmpty) {
      emit(state.copyWith(
          status: Status.loading,
          posts: const [],
          pagination: const PaginationMeta(limit: 20),
          isLoadingMore: false,
          errorMessage: null));
    } else {
      emit(state.copyWith(errorMessage: null, isLoadingMore: false));
    }
    try {
      final result = await reelsRemoteDataSource.fetchPosts(page: event.page, limit: event.limit);
      emit(state.copyWith(
          status: Status.success,
          posts: result.items,
          pagination: result.meta,
          errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: event.showLoading || state.posts.isEmpty ? Status.error : state.status,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: event.showLoading || state.posts.isEmpty ? Status.error : state.status,
          errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  void handleReelsSeeded(ReelsSeeded event, Emitter<ReelsState> emit) {
    emit(state.copyWith(
        status: Status.success,
        posts: event.posts,
        pagination: PaginationMeta(
            page: 1, limit: event.posts.length, total: event.posts.length, totalPages: 1),
        isLoadingMore: false,
        errorMessage: null));
  }

  Future<void> handleReelsLoadMoreRequested(
      ReelsLoadMoreRequested event, Emitter<ReelsState> emit) async {
    if (state.isLoadingMore || !state.pagination.hasNext) return;
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    try {
      final result = await reelsRemoteDataSource.fetchPosts(
          page: state.pagination.page + 1, limit: state.pagination.limit);
      emit(state.copyWith(
          status: Status.success,
          posts: [...state.posts, ...result.items],
          pagination: result.meta,
          isLoadingMore: false,
          errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  Future<void> handleReelCommentsRequested(
      ReelCommentsRequested event, Emitter<ReelsState> emit) async {
    if (event.postId.isEmpty) return;
    if (event.showLoading) {
      emit(state.copyWith(
          commentsStatus: Status.loading,
          commentsPostId: event.postId,
          commentsErrorMessage: null));
    }
    try {
      final result = await reelsRemoteDataSource.fetchComments(
          postId: event.postId, page: event.page, limit: event.limit);
      final nextPagination = Map<String, PaginationMeta>.from(state.commentsPagination)
        ..[event.postId] = result.meta;
      final nextCommentsByPostId = Map<String, List<ReelCommentModel>>.from(state.commentsByPostId)
        ..[event.postId] = result.items;
      emit(state.copyWith(
          posts: replacePostComments(
              postId: event.postId,
              comments: result.items,
              commentsCount: result.meta.total == 0 ? result.items.length : result.meta.total),
          commentsByPostId: nextCommentsByPostId,
          commentsPagination: nextPagination,
          commentsStatus: Status.success,
          commentsPostId: event.postId,
          commentsErrorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          commentsStatus: Status.error,
          commentsPostId: event.postId,
          commentsErrorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          commentsStatus: Status.error,
          commentsPostId: event.postId,
          commentsErrorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  ReelsState stateWithComments({
    required String postId,
    required List<ReelCommentModel> comments,
    required PaginationMeta pagination,
    required ReelsState currentState,
    Status commentsStatus = Status.success,
  }) {
    final nextPagination = Map<String, PaginationMeta>.from(currentState.commentsPagination)
      ..[postId] = pagination;
    final nextCommentsByPostId =
        Map<String, List<ReelCommentModel>>.from(currentState.commentsByPostId)
          ..[postId] = comments;
    return currentState.copyWith(
        posts: replacePostComments(
            postId: postId,
            comments: comments,
            commentsCount: pagination.total == 0 ? comments.length : pagination.total),
        commentsByPostId: nextCommentsByPostId,
        commentsPagination: nextPagination,
        commentsStatus: commentsStatus,
        commentsPostId: postId,
        commentsErrorMessage: null);
  }

  Future<void> handleReelCommentsLoadMoreRequested(
      ReelCommentsLoadMoreRequested event, Emitter<ReelsState> emit) async {
    final meta = state.commentsMeta(event.postId);
    if (event.postId.isEmpty || state.isLoadingMoreComments || !meta.hasNext) return;
    emit(state.copyWith(
        isLoadingMoreComments: true, commentsPostId: event.postId, commentsErrorMessage: null));
    try {
      final result = await reelsRemoteDataSource.fetchComments(
          postId: event.postId, page: meta.page + 1, limit: meta.limit);
      final postIndex = state.posts.indexWhere((post) => post.id == event.postId);
      if (postIndex == -1) {
        emit(state.copyWith(isLoadingMoreComments: false, commentsPostId: event.postId));
        return;
      }
      final currentPost = state.posts[postIndex];
      final currentComments = state.commentsByPostId[event.postId] ?? currentPost.comments;
      final nextComments = [...currentComments, ...result.items];
      final nextPagination = Map<String, PaginationMeta>.from(state.commentsPagination)
        ..[event.postId] = result.meta;
      final nextCommentsByPostId = Map<String, List<ReelCommentModel>>.from(state.commentsByPostId)
        ..[event.postId] = nextComments;
      emit(state.copyWith(
          posts: replacePostComments(
              postId: event.postId,
              comments: nextComments,
              commentsCount: result.meta.total == 0 ? nextComments.length : result.meta.total),
          commentsByPostId: nextCommentsByPostId,
          commentsPagination: nextPagination,
          isLoadingMoreComments: false,
          commentsStatus: Status.success,
          commentsPostId: event.postId,
          commentsErrorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          commentsStatus: Status.error,
          isLoadingMoreComments: false,
          commentsPostId: event.postId,
          commentsErrorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          commentsStatus: Status.error,
          isLoadingMoreComments: false,
          commentsPostId: event.postId,
          commentsErrorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  Future<void> handleReelLikeToggled(ReelLikeToggled event, Emitter<ReelsState> emit) async {
    final previousPosts = state.posts;
    final post = event.post;
    final nextLikesCount = post.isLiked
        ? post.likesCount > 0
            ? post.likesCount - 1
            : 0
        : post.likesCount + 1;
    final nextPost = post.copyWith(isLiked: !post.isLiked, likesCount: nextLikesCount);
    emit(state.copyWith(
        posts: replacePost(state.posts, nextPost),
        actionStatus: Status.loading,
        actionPostId: post.id,
        actionErrorMessage: null));
    try {
      if (post.isLiked) {
        await reelsRemoteDataSource.unlikePost(post.id);
      } else {
        await reelsRemoteDataSource.likePost(post.id);
      }
      emit(state.copyWith(actionStatus: Status.success, actionPostId: post.id));
    } on DioException catch (error) {
      emit(state.copyWith(
          posts: previousPosts,
          actionStatus: Status.error,
          actionPostId: post.id,
          actionErrorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          posts: previousPosts,
          actionStatus: Status.error,
          actionPostId: post.id,
          actionErrorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  Future<void> handleReelCommentSubmitted(
      ReelCommentSubmitted event, Emitter<ReelsState> emit) async {
    if (event.postId.isEmpty || event.text.trim().isEmpty) return;
    emit(state.copyWith(
        actionStatus: Status.loading, actionPostId: event.postId, actionErrorMessage: null));
    try {
      await reelsRemoteDataSource.createComment(
          postId: event.postId, text: event.text.trim(), parentCommentId: event.parentCommentId);
      final result = await reelsRemoteDataSource.fetchComments(postId: event.postId);
      emit(stateWithComments(
              postId: event.postId,
              comments: result.items,
              pagination: result.meta,
              currentState: state)
          .copyWith(actionStatus: Status.success, actionPostId: event.postId));
    } on DioException catch (error) {
      emit(state.copyWith(
          actionStatus: Status.error,
          actionPostId: event.postId,
          actionErrorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          actionStatus: Status.error,
          actionPostId: event.postId,
          actionErrorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  List<ReelPostModel> replacePost(List<ReelPostModel> posts, ReelPostModel nextPost) =>
      posts.map((post) => post.id == nextPost.id ? nextPost : post).toList();

  List<ReelPostModel> replacePostComments({
    required String postId,
    required List<ReelCommentModel> comments,
    required int commentsCount,
  }) =>
      state.posts
          .map((post) => post.id == postId
              ? post.copyWith(comments: comments, commentsCount: commentsCount)
              : post)
          .toList();
}
