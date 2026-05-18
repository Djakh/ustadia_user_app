import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/features/reels/data/models/reel_post_model.dart';

abstract class ReelsEvent extends Equatable {
  const ReelsEvent();

  @override
  List<Object?> get props => [];
}

class ReelsRequested extends ReelsEvent {
  final int page;
  final int limit;
  final bool showLoading;

  const ReelsRequested({this.page = 1, this.limit = 20, this.showLoading = true});

  @override
  List<Object?> get props => [page, limit, showLoading];
}

class ReelsSeeded extends ReelsEvent {
  final List<ReelPostModel> posts;

  const ReelsSeeded({required this.posts});

  @override
  List<Object?> get props => [posts];
}

class ReelsLoadMoreRequested extends ReelsEvent {
  const ReelsLoadMoreRequested();
}

class ReelCommentsRequested extends ReelsEvent {
  final String postId;
  final int page;
  final int limit;
  final bool showLoading;

  const ReelCommentsRequested({
    required this.postId,
    this.page = 1,
    this.limit = 20,
    this.showLoading = true,
  });

  @override
  List<Object?> get props => [postId, page, limit, showLoading];
}

class ReelCommentsLoadMoreRequested extends ReelsEvent {
  final String postId;

  const ReelCommentsLoadMoreRequested({required this.postId});

  @override
  List<Object?> get props => [postId];
}

class ReelLikeToggled extends ReelsEvent {
  final ReelPostModel post;

  const ReelLikeToggled({required this.post});

  @override
  List<Object?> get props => [post];
}

class ReelCommentSubmitted extends ReelsEvent {
  final String postId;
  final String text;
  final String? parentCommentId;

  const ReelCommentSubmitted({required this.postId, required this.text, this.parentCommentId});

  @override
  List<Object?> get props => [postId, text, parentCommentId];
}
