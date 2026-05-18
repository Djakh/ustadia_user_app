import 'package:equatable/equatable.dart';

abstract class ReelUserProfileEvent extends Equatable {
  const ReelUserProfileEvent();

  @override
  List<Object?> get props => [];
}

class ReelUserProfileRequested extends ReelUserProfileEvent {
  final String userId;
  final int page;
  final int limit;
  final bool showLoading;

  const ReelUserProfileRequested({
    required this.userId,
    this.page = 1,
    this.limit = 20,
    this.showLoading = true,
  });

  @override
  List<Object?> get props => [userId, page, limit, showLoading];
}

class ReelUserProfileLoadMoreRequested extends ReelUserProfileEvent {
  const ReelUserProfileLoadMoreRequested();
}
