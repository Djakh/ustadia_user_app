import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/profile/data/datasources/leaderboard_remote_data_source.dart';
import 'package:ustadia_user_app/features/profile/data/models/leaderboard_response_model.dart';
import 'package:ustadia_user_app/features/profile/data/models/leaderboard_user_model.dart';
import 'package:ustadia_user_app/features/profile/presentation/bloc/leaderboard_bloc/leaderboard_event.dart';
import 'package:ustadia_user_app/features/profile/presentation/bloc/leaderboard_bloc/leaderboard_state.dart';

class LeaderboardBloc extends Bloc<LeaderboardEvent, LeaderboardState> {
  final LeaderboardRemoteDataSource leaderboardRemoteDataSource;
  final UserBloc userBloc;

  LeaderboardBloc({required this.leaderboardRemoteDataSource, required this.userBloc})
      : super(const LeaderboardState()) {
    on<LeaderboardRequested>(handleLeaderboardRequested);
  }

  Future<void> handleLeaderboardRequested(
      LeaderboardRequested event, Emitter<LeaderboardState> emit) async {
    emit(state.copyWith(status: Status.loading, resetError: true));
    try {
      final response = await leaderboardRemoteDataSource.fetchLeaderboard();
      final weeklyUsers = mapUsers(response.weekly);
      final monthlyUsers = mapUsers(response.monthly);
      emit(state.copyWith(
          status: Status.success,
          weeklyUsers: weeklyUsers,
          monthlyUsers: monthlyUsers,
          myWeeklyRank: response.myWeeklyRank,
          myMonthlyRank: response.myMonthlyRank,
          resetError: true));
    } on DioException catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(status: Status.error, errorMessage: 'Request failed.'));
    }
  }

  List<LeaderboardUserModel> mapUsers(List<LeaderboardEntryModel> entries) {
    final currentUserId = userBloc.state.profile?.id ?? '';
    return entries
        .map((entry) => LeaderboardUserModel(
            rank: entry.rank,
            userId: entry.userId,
            name: entry.fullName,
            xp: entry.totalXp,
            avatarUrl: leaderboardRemoteDataSource.avatarUrl(entry.profilePictureUrl),
            isCurrentUser: entry.userId == currentUserId))
        .toList()
      ..sort((first, second) => first.rank.compareTo(second.rank));
  }
}
