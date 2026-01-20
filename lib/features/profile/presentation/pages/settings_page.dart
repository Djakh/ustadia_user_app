import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:ustadia_user_app/features/common/data/models/user_profile_model.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/user_bloc/user_state.dart';
import 'package:ustadia_user_app/features/profile/data/models/settings_item_model.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/bottom_sheets/teacher_picker_sheet.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/dividers/primary_divider.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/settings/item_list_box.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/settings/settings_action_dialog.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/settings/settings_list_item.dart';
import 'package:ustadia_user_app/injection_container.dart';
import 'package:ustadia_user_app/router.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  List<SettingsItemModel> get mainItems => const [
        SettingsItemModel(title: 'Account', iconAsset: AppImages.settingsAccount),
        SettingsItemModel(title: 'Learning preferences', iconAsset: AppImages.settingsPreferences),
        SettingsItemModel(title: 'Choose teacher', iconAsset: AppImages.settingsAccount),
        SettingsItemModel(title: 'Notifications', iconAsset: AppImages.settingsNotifications),
        SettingsItemModel(title: 'Info', iconAsset: AppImages.settingsInfo),
        SettingsItemModel(title: 'Legal', iconAsset: AppImages.settingsLegal),
      ];

  SettingsItemModel get logoutItem => const SettingsItemModel(
        title: 'Log out',
        iconAsset: AppImages.settingsSmallLogout,
        isDestructive: true,
      );

  void showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => SettingsActionDialog(
          iconAsset: AppImages.settingsLargerLogout,
          title: 'Log out?',
          subtitle: 'You can log in again anytime.',
          actionText: 'Yes, Logout',
          onConfirm: () {
            Navigator.of(dialogContext).pop();
            logout(dialogContext);
          }),
    );
  }

  Future<void> logout(BuildContext context) async {
    await sl<AuthLocalDataSource>().clearAccessToken();
    if (!context.mounted) return;
    context.go(loginRoute);
  }

  void goToNotifications(BuildContext context) => context.push(settingsNotificationsRoute);

  void goToLanguage(BuildContext context, UserProfileModel userProfileModel) {
    context.push(settingsLanguageRoute, extra: userProfileModel);
  }

  void goToEditAccount(BuildContext context) => context.push(editAccountRoute);

  Future<void> showTeacherPicker(BuildContext context, UserProfileModel userModel) async {
    final didSwap = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.cs.surface,
      constraints: BoxConstraints(
        minHeight: MediaQuery.of(context).size.height * 0.4, 
        
      ),
      shape: RoundedRectangleBorder(borderRadius: Style.borderVer24),
      builder: (sheetContext) => TeacherPickerSheet(userModel: userModel),
    );
    if (didSwap == true && context.mounted) {
      context.go(splashRoute);
    }
  }

  Widget itemsList(BuildContext context) => BlocBuilder<UserBloc, UserState>(
      builder: (context, state) => state.profile == null
          ? const SizedBox()
          : Column(
              children: [
                SettingsListItem(item: mainItems[0], onTap: () => goToEditAccount(context)),
                const PrimaryDivider(),
                SettingsListItem(
                    item: mainItems[1], onTap: () => goToLanguage(context, state.profile!)),
                const PrimaryDivider(),
                SettingsListItem(
                    item: mainItems[2], onTap: () => showTeacherPicker(context, state.profile!)),
                const PrimaryDivider(),
                SettingsListItem(item: mainItems[3], onTap: () => goToNotifications(context)),
                const PrimaryDivider(),
                SettingsListItem(item: mainItems[4], onTap: () {}),
                const PrimaryDivider(),
                SettingsListItem(item: mainItems[5], onTap: () {}),
              ],
            ));

  Widget removeSettingsItem(BuildContext context) => Container(
      decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border20),
      child: SettingsListItem(item: logoutItem, onTap: () => showLogoutDialog(context)));

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PrimaryBackground(
          title: 'Settings',
          isScrollable: true,
          child: Column(children: [
            const SizedBox(height: 12),
            ItemListBox(child: itemsList(context)),
            const SizedBox(height: 16),
            removeSettingsItem(context),
            const SizedBox(height: 24)
          ])));
}
