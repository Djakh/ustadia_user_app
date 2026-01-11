import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';

class UserRemoteDataSource {
  final Dio dio;

  UserRemoteDataSource({required this.dio});

  Future<UserProfileModel> fetchProfile() async {
    final response = await dio.get('/users/profile');
    final data = response.data as Map<String, dynamic>;
    return UserProfileModel.fromJson(data);
  }
}
