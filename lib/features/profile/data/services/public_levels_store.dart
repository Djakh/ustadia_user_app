import 'package:flutter/material.dart';
import 'package:ustadia_user_app/features/common/data/datasources/user_remote_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';

class PublicLevelsStore {
  final UserRemoteDataSource userRemoteDataSource;
  final ValueNotifier<List<UserLevelModel>> levels = ValueNotifier(const []);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  bool isLoading = false;
  bool isUpToDate = false;

  PublicLevelsStore({required this.userRemoteDataSource});

  Future<void> refresh() async {
    if (isLoading) return;
    isLoading = true;
    loading.value = true;
    try {
      levels.value = await userRemoteDataSource.fetchPublicLevels();
      isUpToDate = true;
    } finally {
      isLoading = false;
      loading.value = false;
    }
  }

  Future<void> refreshIfNeeded() async {
    if (levels.value.isEmpty || !isUpToDate) {
      await refresh();
    }
  }

  void markStale() {
    isUpToDate = false;
  }
}
