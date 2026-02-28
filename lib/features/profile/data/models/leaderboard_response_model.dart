class LeaderboardEntryModel {
  final int rank;
  final String userId;
  final String firstName;
  final String lastName;
  final String? profilePictureUrl;
  final int totalXp;

  const LeaderboardEntryModel({
    required this.rank,
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.profilePictureUrl,
    required this.totalXp
  });

  String get fullName {
    final name = '$firstName $lastName'.trim();
    if (name.isNotEmpty) return name;
    return 'Unknown user';
  }

  factory LeaderboardEntryModel.fromJson(Map<String, dynamic> json) => LeaderboardEntryModel(
      rank: (json['rank'] as num?)?.toInt() ?? 0,
      userId: json['userId']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      profilePictureUrl: json['profilePictureUrl']?.toString(),
      totalXp: (json['totalXp'] as num?)?.toInt() ?? 0);
}

class LeaderboardResponseModel {
  final List<LeaderboardEntryModel> weekly;
  final List<LeaderboardEntryModel> monthly;
  final int? myWeeklyRank;
  final int? myMonthlyRank;

  const LeaderboardResponseModel({
    required this.weekly,
    required this.monthly,
    required this.myWeeklyRank,
    required this.myMonthlyRank
  });

  factory LeaderboardResponseModel.fromJson(Map<String, dynamic> json) {
    final weeklyRaw = json['weekly'] as List<dynamic>? ?? const [];
    final monthlyRaw = json['monthly'] as List<dynamic>? ?? const [];
    return LeaderboardResponseModel(
        weekly: weeklyRaw
            .whereType<Map<String, dynamic>>()
            .map(LeaderboardEntryModel.fromJson)
            .toList(),
        monthly: monthlyRaw
            .whereType<Map<String, dynamic>>()
            .map(LeaderboardEntryModel.fromJson)
            .toList(),
        myWeeklyRank: (json['myWeeklyRank'] as num?)?.toInt(),
        myMonthlyRank: (json['myMonthlyRank'] as num?)?.toInt());
  }
}
