import 'package:flutter/material.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/features/profile/data/models/settings_toggle_model.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/dividers/primary_divider.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/settings/item_list_box.dart';
import 'package:ustadia_user_app/features/profile/presentation/widgets/settings/settings_notification_item.dart';

class SettingsNotificationsPage extends StatefulWidget {
  const SettingsNotificationsPage({super.key});

  @override
  State<SettingsNotificationsPage> createState() => SettingsNotificationsPageState();
}

class SettingsNotificationsPageState extends State<SettingsNotificationsPage> {
  List<SettingsToggleModel> items = const [
    SettingsToggleModel(title: 'Daily reminder', isEnabled: true),
    SettingsToggleModel(title: 'Streak reminders', isEnabled: true),
    SettingsToggleModel(title: 'New features and tips', isEnabled: true),
  ];

  void updateItem(int index, bool value) {
    setState(() {
      items = items
          .asMap()
          .entries
          .map((entry) => entry.key == index ? entry.value.copyWith(isEnabled: value) : entry.value)
          .toList();
    });
  }

  Widget notificationItemList(BuildContext context) => Column(
        children: [
          SettingsNotificationItem(item: items[0], onChanged: (value) => updateItem(0, value)),
          const PrimaryDivider(),
          SettingsNotificationItem(item: items[1], onChanged: (value) => updateItem(1, value)),
          const PrimaryDivider(),
          SettingsNotificationItem(item: items[2], onChanged: (value) => updateItem(2, value)),
        ],
      );

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PrimaryBackground(
          title: 'Notifications',
          isScrollable: true,
          child: Column(children: [
            const SizedBox(height: 24),
            ItemListBox(child: notificationItemList(context)),
            const SizedBox(height: 24)
          ])));
}
