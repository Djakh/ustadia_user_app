import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/toggles/segmented_control.dart';
import 'package:ustadia_user_app/features/profile/data/models/leaderboard_podium_model.dart';
import 'package:ustadia_user_app/features/profile/data/models/leaderboard_user_model.dart';
import 'package:ustadia_user_app/features/profile/presentation/bloc/leaderboard_bloc/leaderboard_bloc.dart';
import 'package:ustadia_user_app/features/profile/presentation/bloc/leaderboard_bloc/leaderboard_event.dart';
import 'package:ustadia_user_app/features/profile/presentation/bloc/leaderboard_bloc/leaderboard_state.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/leaderboard/leaderboard_podium_item.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/leaderboard/leaderboard_user_list_item.dart';
import 'package:ustadia_user_app/injection_container.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => LeaderboardPageState();
}

class LeaderboardPageState extends State<LeaderboardPage> {
  final LeaderboardBloc leaderboardBloc = sl<LeaderboardBloc>();
  int selectedRangeIndex = 0;

  @override
  void initState() {
    super.initState();
    leaderboardBloc.add(const LeaderboardRequested());
  }

  @override
  void dispose() {
    leaderboardBloc.close();
    super.dispose();
  }

  /// --- Methods ---

  void onSelectedRangeIndex(int index) {
    setState(() => selectedRangeIndex = index);
  }

  List<LeaderboardUserModel> usersForSelectedRange(LeaderboardState state) {
    return selectedRangeIndex == 0 ? state.weeklyUsers : state.monthlyUsers;
  }

  List<LeaderboardUserModel> topThreeUsers(List<LeaderboardUserModel> users) {
    final byRank = <int, LeaderboardUserModel>{};
    for (final user in users) {
      byRank[user.rank] = user;
    }
    return [
      if (byRank.containsKey(2)) byRank[2]!,
      if (byRank.containsKey(1)) byRank[1]!,
      if (byRank.containsKey(3)) byRank[3]!,
    ];
  }

  List<LeaderboardPodiumModel> podiumItems(List<LeaderboardUserModel> users) {
    return users.map((user) {
      if (user.rank == 1) {
        return LeaderboardPodiumModel(
            user: user, placeAsset: AppImages.leaderboardFirstPlace, placeLabel: '1st');
      }
      if (user.rank == 2) {
        return LeaderboardPodiumModel(
            user: user, placeAsset: AppImages.leaderboardSecondPlace, placeLabel: '2nd');
      }
      return LeaderboardPodiumModel(
          user: user, placeAsset: AppImages.leaderboardThirdPlace, placeLabel: '3rd');
    }).toList();
  }

  List<LeaderboardUserModel> leaderboardUsers(List<LeaderboardUserModel> users) {
    return users.where((user) => user.rank > 3).toList();
  }

  /// --- Widgets ---

  Widget rangeSelector() => SegmentedControl(
      labels: const ['This week', 'This month'],
      selectedIndex: selectedRangeIndex,
      onChanged: onSelectedRangeIndex);

  Widget podiumRow(List<LeaderboardUserModel> users) {
    final topUsers = topThreeUsers(users);
    final podium = podiumItems(topUsers);
    if (podium.isEmpty) return const SizedBox.shrink();
    return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: podium
            .map((item) => Expanded(
                    child: LeaderboardPodiumItem(
                  podium: item,
                )))
            .toList());
  }

  Widget leaderboardList(List<LeaderboardUserModel> users) {
    final listUsers = leaderboardUsers(users);
    return ListView.separated(
        itemCount: listUsers.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, index) => LeaderboardUserListItem(user: listUsers[index]));
  }

  Widget dataView(List<LeaderboardUserModel> users) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          rangeSelector(),
          const SizedBox(height: 28),
          podiumRow(users),
          const SizedBox(height: 24),
          leaderboardList(users),
          const SizedBox(height: 80),
        ],
      );

  Widget get content =>
      BlocStatusView<LeaderboardBloc, LeaderboardState, List<LeaderboardUserModel>>(
          bloc: leaderboardBloc,
          statusOf: (state) => state.status,
          errorOf: (state) => state.errorMessage,
          data: usersForSelectedRange,
          isEmpty: (users) => users.isEmpty,
          empty: Center(child: Text('No data found'.tr())),
          loading: const Center(child: CircularProgressIndicator()),
          builder: (context, users) => dataView(users),
          listener: (context, state) {
            if (state.status == Status.error && state.errorMessage != null) {
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(state.errorMessage!)));
            }
          });

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PrimaryBackground(title: 'Leaderboard'.tr(), isScrollable: true, child: content));
}
