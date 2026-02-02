import 'package:flutter/material.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_statistics_model.dart';

class ProfileStatisticsStore {
  final UserRemoteDataSource userRemoteDataSource;
  final ValueNotifier<ProfileStatisticsModel?> statistics = ValueNotifier(null);
  bool isLoading = false;

  ProfileStatisticsStore({required this.userRemoteDataSource});

  Future<void> refresh() async {
    if (isLoading) return;
    isLoading = true;
    try {
      statistics.value = await userRemoteDataSource.fetchProfileStatistics();
    } finally {
      isLoading = false;
    }
  }
}
