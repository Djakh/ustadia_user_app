import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/mixins/format_date.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/listviews/primary_list_view.dart';
import 'package:ustadia_user_app/features/notifications/data/models/notification_model.dart';
import 'package:ustadia_user_app/features/notifications/presentation/widgets/notification_list_item.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with FormatDateMixin {
  List<NotificationModel> notifications = NotificationModel.mockNotifications;

  /// --- Methods ---

  void markAllRead() {
    setState(() {
      notifications = notifications.map((item) => item.copyWith(isRead: true)).toList();
    });
  }

  void toggleRead(String id) {
    setState(() {
      notifications = notifications
          .map((item) => item.id == id ? item.copyWith(isRead: !item.isRead) : item)
          .toList();
    });
  }

  /// --- Widget Methods ---

  List<NotificationSection> sections(List<NotificationModel> items) {
    final grouped = <DateTime, List<NotificationModel>>{};
    for (final item in items) {
      final day = DateUtils.dateOnly(item.createdAt);
      grouped.putIfAbsent(day, () => []).add(item);
    }

    final sections = grouped.entries
        .map((entry) => NotificationSection(date: entry.key, items: entry.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final section in sections) {
      section.items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return sections;
  }

  List<Widget> buildSectionWidgets(BuildContext context) {
    final list = sections(notifications);
    final widgets = <Widget>[];

    for (var i = 0; i < list.length; i++) {
      widgets.add(sectionListComponents(context, list[i]));
      if (i != list.length - 1) {
        widgets.add(const SizedBox(height: 20));
      }
    }

    return widgets;
  }

  /// --- Widgets ---

  Widget emptyState(BuildContext context) =>
      Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset(AppImages.notificationBell, height: 160, width: 160),
        Text("You don't have any notifications yet", style: Style.body3w7(context)),
        const SizedBox(height: 4),
        Text('New lessons, reminders, and learning updates will appear here.',
            textAlign: TextAlign.center,
            style: Style.bodyw4(context, color: TextColorRole.greyColor))
      ]);

  PrimaryListView sectionList(NotificationSection section) => PrimaryListView(
      items: section.items,
      shrinkWrap: true,
      itemBuilder: (item) =>
          NotificationListItem(notification: item, onTap: () => toggleRead(item.id)));

  Widget sectionListComponents(BuildContext context, NotificationSection section) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(formatDateLabel(section.date, DateTime.now()),
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 12),
        sectionList(section),
      ]);

  Widget listView(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          ...buildSectionWidgets(context),
          const SizedBox(height: 24),
        ],
      );

  Widget get readNotificationsButton => Align(
      alignment: Alignment.centerRight,
      child: Container(
          decoration: BoxDecoration(color: context.cs.surface, shape: BoxShape.circle),
          child:
              IconButton(onPressed: markAllRead, icon: SvgPicture.asset(AppImages.checkSquare))));

  Widget header(BuildContext context) => IntrinsicHeight(
          child: Stack(alignment: Alignment.center, children: [
        Text('Notifications', style: Style.body2w6(context)),
        readNotificationsButton
      ]));

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PrimaryBackground(
          header: header(context),
          isScrollable: notifications.isEmpty ? false : true,
          child: notifications.isEmpty ? emptyState(context) : listView(context)));
}
