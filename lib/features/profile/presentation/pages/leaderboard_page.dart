import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/toggles/segmented_control.dart';
import 'package:ustadia_user_app/features/profile/data/models/leaderboard_podium_model.dart';
import 'package:ustadia_user_app/features/profile/data/models/leaderboard_user_model.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/leaderboard/leaderboard_podium_item.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/leaderboard/leaderboard_user_list_item.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/leaderboard/scope_filter_item.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  int selectedRangeIndex = 0;
  int selectedScopeIndex = 0;

  List<String> scopeFilters = ['Global', 'Friends'];

  static const String _avatarAlex =
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?q=80&w=300&auto=format&fit=crop';
  static const String _avatarTaylor =
      'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?q=80&w=300&auto=format&fit=crop';
  static const String _avatarJordan =
      'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?q=80&w=300&auto=format&fit=crop';
  static const String _avatarRahimov =
      'https://images.unsplash.com/photo-1527980965255-d3b416303d12?q=80&w=300&auto=format&fit=crop';

  static const List<LeaderboardPodiumModel> _podiumUsers = [
    LeaderboardPodiumModel(
      user: LeaderboardUserModel(rank: 2, name: 'Taylor Reed', xp: 2150, avatarUrl: _avatarTaylor),
      placeAsset: AppImages.leaderboardSecondPlace,
      placeLabel: '2nd',
    ),
    LeaderboardPodiumModel(
      user: LeaderboardUserModel(rank: 1, name: 'Alex Mercer', xp: 2400, avatarUrl: _avatarAlex),
      placeAsset: AppImages.leaderboardFirstPlace,
      placeLabel: '1st',
    ),
    LeaderboardPodiumModel(
      user: LeaderboardUserModel(rank: 3, name: 'Jordan Blake', xp: 1980, avatarUrl: _avatarJordan),
      placeAsset: AppImages.leaderboardThirdPlace,
      placeLabel: '3rd',
    ),
  ];

  static const List<LeaderboardUserModel> _leaderboardUsers = [
    LeaderboardUserModel(rank: 4, name: 'Rahimov A.', xp: 1920, avatarUrl: _avatarRahimov),
    LeaderboardUserModel(rank: 5, name: 'Rahimov A.', xp: 1760, avatarUrl: _avatarRahimov),
    LeaderboardUserModel(rank: 6, name: 'Rahimov A.', xp: 1720, avatarUrl: _avatarRahimov),
    LeaderboardUserModel(rank: 7, name: 'Rahimov A.', xp: 1630, avatarUrl: _avatarRahimov),
    LeaderboardUserModel(rank: 8, name: 'Rahimov A.', xp: 1850, avatarUrl: _avatarRahimov),
    LeaderboardUserModel(rank: 9, name: 'Rahimov A.', xp: 1810, avatarUrl: _avatarRahimov),
    LeaderboardUserModel(
        rank: 10, name: 'You', xp: 1850, avatarUrl: _avatarRahimov, isCurrentUser: true),
  ];

  /// --- Methods ---

  void onSelectedRangeIndex(int index) {
    setState(() => selectedRangeIndex = index);
  }

  void onSelectScopeFilter(int index) {
    selectedScopeIndex = index;
    setState(() {});
  }

  /// --- Widgets ---

  Widget rangeSelector(BuildContext context) => SegmentedControl(
      labels: const ['This week', 'This month'],
      selectedIndex: selectedRangeIndex,
      onChanged: onSelectedRangeIndex);

  Widget get scopeFiltersList => SizedBox(
        height: 34,
        child: ListView.separated(
            itemCount: scopeFilters.length,
            scrollDirection: Axis.horizontal,
            separatorBuilder: (_, index) => const SizedBox(width: 12),
            itemBuilder: (_, index) => ScopeFilterItem(
                  title: scopeFilters[index],
                  index: index,
                  isSelected: selectedScopeIndex == index,
                  onTap: onSelectScopeFilter,
                )),
      );

  Widget podiumRow(BuildContext context) => Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          LeaderboardPodiumItem(podium: _podiumUsers[0]),
          LeaderboardPodiumItem(podium: _podiumUsers[1]),
          LeaderboardPodiumItem(podium: _podiumUsers[2]),
        ],
      );

  Widget leaderboardList(BuildContext context) => ListView.separated(
        itemCount: _leaderboardUsers.length,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        separatorBuilder: (_, __) => const SizedBox(height: 4),
        itemBuilder: (_, index) => LeaderboardUserListItem(user: _leaderboardUsers[index]),
      );

  Widget view(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          rangeSelector(context),
          const SizedBox(height: 12),
          scopeFiltersList,
          const SizedBox(height: 28),
          podiumRow(context),
          const SizedBox(height: 24),
          leaderboardList(context),
          const SizedBox(height: 80),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PrimaryBackground(title: 'Leaderboard', isScrollable: true, child: view(context)));
}
