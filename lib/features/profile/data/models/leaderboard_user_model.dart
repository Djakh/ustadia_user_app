class LeaderboardUserModel {
  final int rank;
  final String userId;
  final String name;
  final int xp;
  final String avatarUrl;
  final bool isCurrentUser;

  const LeaderboardUserModel({
    required this.rank,
    required this.userId,
    required this.name,
    required this.xp,
    required this.avatarUrl,
    this.isCurrentUser = false,
  });
}
