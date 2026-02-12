// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/inherited_widgets/navigation_shell_scope.dart';

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
    widget.navigationShell.goBranch(i, initialLocation: i == current);
    setState(() {});
  }

  /// --- Widgets ---
  Widget _item(IconData icon, bool selected, String label) =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(icon, color: selected ? context.cs.primary : AppColors.gray8C, size: 26),
        const SizedBox(height: 4),
        Text(label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Style.small2w5(context,
                color: selected ? TextColorRole.primaryColor : TextColorRole.greyColor))
      ]);

  BottomNavigationBarItem _itemBox(bool selected, IconData icon, String label) =>
      BottomNavigationBarItem(
          label: '',
          icon: Center(
              child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: 80,
                  height: 74,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                      color:
                          selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.transparent,
                      shape: BoxShape.circle),
                  child: _item(icon, selected, label))));

  Widget get bottomNavigationBar => ClipRRect(
        borderRadius: BorderRadius.circular(70),
        child: BottomNavigationBar(
          elevation: 0,
          backgroundColor: Colors.transparent,
          type: BottomNavigationBarType.fixed,
          currentIndex: navigationIndex,
          onTap: onSelectBottomNavigation,
          showSelectedLabels: false,
          showUnselectedLabels: false,
          selectedItemColor: context.cs.primary,
          unselectedItemColor: AppColors.gray8C,
          selectedFontSize: 0,
          unselectedFontSize: 0,
          items: [
            _itemBox(navigationIndex == 0, Icons.home_rounded, 'Home'.tr()),
            _itemBox(navigationIndex == 1, Icons.menu_book_rounded, 'Learn'.tr()),
            _itemBox(navigationIndex == 2, Icons.extension_rounded, 'Practice'.tr()),
            _itemBox(navigationIndex == 3, Icons.auto_awesome_rounded, 'ai_chat'.tr()),
            _itemBox(navigationIndex == 4, Icons.person_rounded, 'Profile'.tr()),
          ],
        ),
      );

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
