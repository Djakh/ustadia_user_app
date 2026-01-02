import 'package:ustadia_user_app/features/profile/data/models/leaderboard_user_model.dart';

class LeaderboardPodiumModel {
  final LeaderboardUserModel user;
  final String placeAsset;
  final String placeLabel;

  const LeaderboardPodiumModel({
    required this.user,
    required this.placeAsset,
    required this.placeLabel,
  });
}
