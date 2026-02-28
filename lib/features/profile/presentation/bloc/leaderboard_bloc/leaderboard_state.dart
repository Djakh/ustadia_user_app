import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/profile/data/models/leaderboard_user_model.dart';

class LeaderboardState {
  final Status status;
  final List<LeaderboardUserModel> weeklyUsers;
  final List<LeaderboardUserModel> monthlyUsers;
  final int? myWeeklyRank;
  final int? myMonthlyRank;
  final String? errorMessage;

  const LeaderboardState({
    this.status = Status.initial,
    this.weeklyUsers = const [],
    this.monthlyUsers = const [],
    this.myWeeklyRank,
    this.myMonthlyRank,
    this.errorMessage
  });

  LeaderboardState copyWith({
    Status? status,
    List<LeaderboardUserModel>? weeklyUsers,
    List<LeaderboardUserModel>? monthlyUsers,
    int? myWeeklyRank,
    int? myMonthlyRank,
    String? errorMessage,
    bool resetError = false
  }) =>
      LeaderboardState(
          status: status ?? this.status,
          weeklyUsers: weeklyUsers ?? this.weeklyUsers,
          monthlyUsers: monthlyUsers ?? this.monthlyUsers,
          myWeeklyRank: myWeeklyRank ?? this.myWeeklyRank,
          myMonthlyRank: myMonthlyRank ?? this.myMonthlyRank,
          errorMessage: resetError ? null : errorMessage ?? this.errorMessage);
}
