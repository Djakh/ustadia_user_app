// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/inherited_widgets/navigation_shell_scope.dart';
import 'package:ustadia_user_app/features/dashboard/data/services/current_unit_store.dart';
import 'package:ustadia_user_app/features/profile/data/services/profile_statistics_store.dart';
import 'package:ustadia_user_app/injection_container.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.navigationShell});
  final StatefulNavigationShell navigationShell;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  /// --- Getters ---
  int get navigationIndex => widget.navigationShell.currentIndex;

  /// --- Methods ---

  void onSelectBottomNavigation(int i) {
    final current = navigationIndex;
    if (i == 0) {
      sl<ProfileStatisticsStore>().refreshIfNeeded();
      sl<CurrentUnitStore>().refreshIfNeeded();
    }
    if (i == 4) {
      sl<ProfileStatisticsStore>().refreshIfNeeded();
    }
    widget.navigationShell.goBranch(i, initialLocation: i == current);
    setState(() {});
  }

  /// --- Widgets ---
  Widget _item(IconData icon, bool selected, String label, double itemWidth) {
    final compact = itemWidth < 68;
    final iconSize = compact ? 22.0 : 24.0;
    final textStyle = Style.small2w5(context,
            color: selected ? TextColorRole.primaryColor : TextColorRole.greyColor)
        .copyWith(fontSize: compact ? 10 : 12, height: 1);

    return Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: selected ? context.cs.primary : AppColors.gray8C, size: iconSize),
          SizedBox(height: compact ? 2 : 4),
          SizedBox(
              width: itemWidth - 12,
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: textStyle))
        ]);
  }

  Widget _itemBox(int index, IconData icon, String label, double itemWidth) {
    final selected = navigationIndex == index;
    final compact = itemWidth < 68;
    final horizontalInset = compact ? 3.0 : 5.0;
    final boxWidth = (itemWidth - horizontalInset * 2).clamp(48.0, 66.0);
    final boxHeight = compact ? 54.0 : 58.0;

    return Expanded(
        child: Padding(
            padding: EdgeInsets.symmetric(horizontal: horizontalInset),
            child: Material(
                color: Colors.transparent,
                child: InkWell(
                    borderRadius: BorderRadius.circular(boxHeight / 2),
                    onTap: () => onSelectBottomNavigation(index),
                    child: Center(
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeOut,
                            width: boxWidth,
                            height: boxHeight,
                            padding: EdgeInsets.symmetric(
                                horizontal: compact ? 4 : 6, vertical: compact ? 5 : 6),
                            decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.primary.withValues(alpha: 0.08)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(boxHeight / 2)),
                            child: _item(icon, selected, label, boxWidth)))))));
  }

  Widget get bottomNavigationBar => LayoutBuilder(builder: (context, constraints) {
        final itemWidth = constraints.maxWidth / 5;
        return Row(children: [
          _itemBox(0, Icons.home_rounded, 'Home'.tr(), itemWidth),
          _itemBox(1, Icons.menu_book_rounded, 'Learn'.tr(), itemWidth),
          _itemBox(2, Icons.extension_rounded, 'Practice'.tr(), itemWidth),
          _itemBox(3, Icons.auto_awesome_rounded, 'ai_chat'.tr(), itemWidth),
          _itemBox(4, Icons.person_rounded, 'Profile'.tr(), itemWidth)
        ]);
      });

  Widget get bottomNavigationBarBox => Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: DecoratedBox(
          decoration: BoxDecoration(
              color: context.cs.surface,
              borderRadius: BorderRadius.circular(70),
              boxShadow: const [
                BoxShadow(
                    color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8), spreadRadius: 1)
              ]),
          child: bottomNavigationBar));

  @override
  Widget build(BuildContext context) => Scaffold(
        body: NavigationShellScope(
          shell: widget.navigationShell,
          child: widget.navigationShell,
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        floatingActionButton: bottomNavigationBarBox,
      );
}
