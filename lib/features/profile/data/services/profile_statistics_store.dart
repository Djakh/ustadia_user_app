import 'package:flutter/material.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/profile/data/models/profile_statistics_model.dart';

class ProfileStatisticsStore {
  final UserRemoteDataSource userRemoteDataSource;
  final ValueNotifier<ProfileStatisticsModel?> statistics = ValueNotifier(null);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  bool isLoading = false;
  bool isUpToDate = false;

  ProfileStatisticsStore({required this.userRemoteDataSource});

  Future<void> refresh() async {
    if (isLoading) return;
    isLoading = true;
    loading.value = true;
    try {
      statistics.value = await userRemoteDataSource.fetchProfileStatistics();
      isUpToDate = true;
    } finally {
      isLoading = false;
      loading.value = false;
    }
  }

  Future<void> refreshIfNeeded() async {
    if (statistics.value == null || !isUpToDate) {
      await refresh();
    }
  }

  void markStale() {
    isUpToDate = false;
  }
}
