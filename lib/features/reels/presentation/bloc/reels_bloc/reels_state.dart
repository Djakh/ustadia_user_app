import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/features/reels/data/models/reel_post_model.dart';

class ReelsState extends Equatable {
  final Status status;
  final List<ReelPostModel> posts;
  final PaginationMeta pagination;
  final bool isLoadingMore;
  final String? errorMessage;
  final Map<String, List<ReelCommentModel>> commentsByPostId;
  final Map<String, PaginationMeta> commentsPagination;
  final Status commentsStatus;
  final bool isLoadingMoreComments;
  final String? commentsPostId;
  final String? commentsErrorMessage;
  final Status actionStatus;
  final String? actionErrorMessage;
  final String? actionPostId;

  const ReelsState({
    this.status = Status.initial,
    this.posts = const [],
    this.pagination = const PaginationMeta(limit: 20),
    this.isLoadingMore = false,
    this.errorMessage,
    this.commentsByPostId = const {},
    this.commentsPagination = const {},
    this.commentsStatus = Status.initial,
    this.isLoadingMoreComments = false,
    this.commentsPostId,
    this.commentsErrorMessage,
    this.actionStatus = Status.initial,
    this.actionErrorMessage,
    this.actionPostId,
  });

  ReelsState copyWith({
    Status? status,
    List<ReelPostModel>? posts,
    PaginationMeta? pagination,
    bool? isLoadingMore,
    String? errorMessage,
    Map<String, List<ReelCommentModel>>? commentsByPostId,
    Map<String, PaginationMeta>? commentsPagination,
    Status? commentsStatus,
    bool? isLoadingMoreComments,
    String? commentsPostId,
    String? commentsErrorMessage,
    Status? actionStatus,
    String? actionErrorMessage,
    String? actionPostId,
  }) =>
      ReelsState(
        status: status ?? this.status,
        posts: posts ?? this.posts,
        pagination: pagination ?? this.pagination,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        errorMessage: errorMessage,
        commentsByPostId: commentsByPostId ?? this.commentsByPostId,
        commentsPagination: commentsPagination ?? this.commentsPagination,
        commentsStatus: commentsStatus ?? this.commentsStatus,
        isLoadingMoreComments: isLoadingMoreComments ?? this.isLoadingMoreComments,
        commentsPostId: commentsPostId,
        commentsErrorMessage: commentsErrorMessage,
        actionStatus: actionStatus ?? this.actionStatus,
        actionErrorMessage: actionErrorMessage,
        actionPostId: actionPostId,
      );

  PaginationMeta commentsMeta(String postId) =>
      commentsPagination[postId] ?? const PaginationMeta(limit: 20);

  List<ReelCommentModel> commentsForPost(ReelPostModel post) =>
      commentsByPostId[post.id] ?? post.comments;

  bool hasMoreComments(String postId) => commentsMeta(postId).hasNext;

  @override
  List<Object?> get props => [
        status,
        posts,
        pagination,
        isLoadingMore,
        errorMessage,
        commentsByPostId,
        commentsPagination,
        commentsStatus,
        isLoadingMoreComments,
        commentsPostId,
        commentsErrorMessage,
        actionStatus,
        actionErrorMessage,
        actionPostId,
      ];
}
