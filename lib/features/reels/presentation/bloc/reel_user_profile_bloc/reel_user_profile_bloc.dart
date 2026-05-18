import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/features/reels/data/datasources/reels_remote_data_source.dart';
import 'package:ustadia_user_app/features/reels/presentation/bloc/reel_user_profile_bloc/reel_user_profile_event.dart';
import 'package:ustadia_user_app/features/reels/presentation/bloc/reel_user_profile_bloc/reel_user_profile_state.dart';

class ReelUserProfileBloc extends Bloc<ReelUserProfileEvent, ReelUserProfileState> {
  final ReelsRemoteDataSource reelsRemoteDataSource;

  ReelUserProfileBloc({required this.reelsRemoteDataSource}) : super(const ReelUserProfileState()) {
    on<ReelUserProfileRequested>(handleProfileRequested);
    on<ReelUserProfileLoadMoreRequested>(handleLoadMoreRequested);
  }

  Future<void> handleProfileRequested(
      ReelUserProfileRequested event, Emitter<ReelUserProfileState> emit) async {
    if (event.userId.isEmpty) return;
    if (event.showLoading || state.posts.isEmpty || state.userId != event.userId) {
      emit(state.copyWith(
          status: Status.loading,
          posts: const [],
          pagination: const PaginationMeta(limit: 20),
          isLoadingMore: false,
          userId: event.userId,
          errorMessage: null));
    } else {
      emit(state.copyWith(userId: event.userId, errorMessage: null));
    }
    try {
      final result = await reelsRemoteDataSource.fetchUserProfile(
          userId: event.userId, page: event.page, limit: event.limit);
      emit(state.copyWith(
          status: Status.success,
          user: result.user,
          posts: result.feeds.items,
          pagination: result.feeds.meta,
          userId: event.userId,
          errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: event.showLoading || state.posts.isEmpty ? Status.error : state.status,
          isLoadingMore: false,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: event.showLoading || state.posts.isEmpty ? Status.error : state.status,
          isLoadingMore: false,
          errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }

  Future<void> handleLoadMoreRequested(
      ReelUserProfileLoadMoreRequested event, Emitter<ReelUserProfileState> emit) async {
    if (state.userId.isEmpty || state.isLoadingMore || !state.pagination.hasNext) return;
    emit(state.copyWith(isLoadingMore: true, errorMessage: null));
    try {
      final result = await reelsRemoteDataSource.fetchUserProfile(
          userId: state.userId, page: state.pagination.page + 1, limit: state.pagination.limit);
      emit(state.copyWith(
          status: Status.success,
          user: result.user,
          posts: [...state.posts, ...result.feeds.items],
          pagination: result.feeds.meta,
          isLoadingMore: false,
          errorMessage: null));
    } on DioException catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: DioErrorMessage.fromUnknown(error)));
    }
  }
}
