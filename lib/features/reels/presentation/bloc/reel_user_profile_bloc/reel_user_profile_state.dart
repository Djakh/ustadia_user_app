import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/features/reels/data/models/reel_post_model.dart';

class ReelUserProfileState extends Equatable {
  final Status status;
  final ReelAuthorModel? user;
  final List<ReelPostModel> posts;
  final PaginationMeta pagination;
  final bool isLoadingMore;
  final String userId;
  final String? errorMessage;

  const ReelUserProfileState({
    this.status = Status.initial,
    this.user,
    this.posts = const [],
    this.pagination = const PaginationMeta(limit: 20),
    this.isLoadingMore = false,
    this.userId = '',
    this.errorMessage,
  });

  ReelUserProfileState copyWith({
    Status? status,
    ReelAuthorModel? user,
    List<ReelPostModel>? posts,
    PaginationMeta? pagination,
    bool? isLoadingMore,
    String? userId,
    String? errorMessage,
  }) =>
      ReelUserProfileState(
        status: status ?? this.status,
        user: user ?? this.user,
        posts: posts ?? this.posts,
        pagination: pagination ?? this.pagination,
        isLoadingMore: isLoadingMore ?? this.isLoadingMore,
        userId: userId ?? this.userId,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, user, posts, pagination, isLoadingMore, userId, errorMessage];
}
