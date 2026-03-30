import 'package:flutter/material.dart';
import 'package:ustadia_user_app/features/dashboard/data/models/current_unit_model.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';

class CurrentUnitStore {
  final LearnRemoteDataSource learnRemoteDataSource;
  final ValueNotifier<CurrentUnitModel?> unit = ValueNotifier(null);
  final ValueNotifier<bool> loading = ValueNotifier(false);
  bool isLoading = false;
  bool isUpToDate = false;

  CurrentUnitStore({required this.learnRemoteDataSource});

  Future<void> refresh() async {
    if (isLoading) return;
    isLoading = true;
    loading.value = true;
    try {
      unit.value = await learnRemoteDataSource.fetchCurrentUnit();
      isUpToDate = true;
    } finally {
      isLoading = false;
      loading.value = false;
    }
  }

  Future<void> refreshIfNeeded() async {
    if (unit.value == null || !isUpToDate) {
      await refresh();
    }
  }

  void markStale() {
    isUpToDate = false;
  }
}
