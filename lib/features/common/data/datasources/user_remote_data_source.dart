import 'package:dio/dio.dart';
import 'package:ustadia_user_app/features/common/data/models/swap_teacher_response.dart';
import 'package:ustadia_user_app/features/common/data/models/teacher_model.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_statistics_model.dart';

class UserRemoteDataSource {
  final Dio dio;

  UserRemoteDataSource({required this.dio});

  Future<UserProfileModel> fetchProfile() async {
    final response = await dio.get('/users/profile?intro=true&statistics=true');
    final data = response.data as Map<String, dynamic>;
    return UserProfileModel.fromJson(data);
  }

  Future<UserProfileModel> updateProfile(
      {required String firstName,
      required String lastName,
      required String language,
      String? profilePictureId}) async {
    final data = {'firstName': firstName, 'lastName': lastName, 'language': language};
    if (profilePictureId != null && profilePictureId.isNotEmpty) {
      data['profilePictureId'] = profilePictureId;
    }
    final response = await dio.patch('/users/profile?intro=true&statistics=true', data: data);
    final responseData = response.data as Map<String, dynamic>;
    return UserProfileModel.fromJson(responseData);
  }

  Future<void> deleteProfile() async {
    await dio.delete('/users/profile');
  }

  Future<ProfileStatisticsModel> fetchProfileStatistics() async {
    final response = await dio.get('/users/profile/statistics');
    final data = response.data as Map<String, dynamic>;
    return ProfileStatisticsModel.fromJson(data);
  }

  Future<List<TeacherModel>> fetchTeachers() async {
    final response = await dio.get('/students/teachers');
    final data = response.data as Map<String, dynamic>;
    final items = data['data'] as List<dynamic>? ?? [];
    return items.map((item) => TeacherModel.fromJson(item as Map<String, dynamic>)).toList();
  }

  Future<SwapTeacherResponse> swapTeacher({required String? teacherId}) async {
    final response = await dio.post('/students/swap-teacher',
        data: teacherId != null ? {'teacher_id': teacherId} : {});
    final data = response.data as Map<String, dynamic>;
    return SwapTeacherResponse.fromJson(data);
  }

  Future<void> registerDevice({required String token, required String deviceType}) async {
    await dio.post('/users/devices', data: {'token': token, 'deviceType': deviceType});
  }

  Future<void> unregisterDevice({String? token, String? deviceType}) async {
    final data = <String, dynamic>{};
    if (token != null && token.isNotEmpty) data['token'] = token;
    if (deviceType != null && deviceType.isNotEmpty) data['deviceType'] = deviceType;
    await dio.delete('/users/devices', data: data.isEmpty ? null : data);
  }
}
