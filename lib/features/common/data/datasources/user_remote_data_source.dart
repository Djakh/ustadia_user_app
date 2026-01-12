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

  Future<UserProfileModel> updateProfile({
    required String firstName,
    required String lastName,
    required String language,
    String? profilePictureId
  }) async {
    final data = {
      'firstName': firstName,
      'lastName': lastName,
      'language': language
    };
    if (profilePictureId != null && profilePictureId.isNotEmpty) {
      data['profilePictureId'] = profilePictureId;
    }
    final response = await dio.patch('/users/profile', data: data);
    final responseData = response.data as Map<String, dynamic>;
    return UserProfileModel.fromJson(responseData);
  }

  Future<void> deleteProfile() async {
    await dio.delete('/users/profile');
  }
}
