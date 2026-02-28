import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/profile/data/models/leaderboard_response_model.dart';

class LeaderboardRemoteDataSource {
  final Dio dio;

  LeaderboardRemoteDataSource({required this.dio});

  String avatarUrl(String? profilePictureUrl) {
    if (profilePictureUrl == null || profilePictureUrl.isEmpty) return '';
    if (profilePictureUrl.startsWith('http')) return profilePictureUrl;
    return '${dio.options.baseUrl}$profilePictureUrl';
  }

  Future<LeaderboardResponseModel> fetchLeaderboard() async {
    final response = await dio.get('/users/leaderboard');
    final data = response.data as Map<String, dynamic>;
    return LeaderboardResponseModel.fromJson(data);
  }
}
