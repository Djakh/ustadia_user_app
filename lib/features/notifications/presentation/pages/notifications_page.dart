import 'package:flutter/material.dart';
import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/core/mixins/format_date.dart';
import 'package:ustadia_user_app/core/services/firebase_messaging_service.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/listviews/primary_list_view.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_bloc.dart';
import 'package:ustadia_user_app/features/common/presentation/bloc/teacher_bloc/teacher_event.dart';
import 'package:ustadia_user_app/features/notifications/data/models/notification_api_model.dart';
import 'package:ustadia_user_app/features/notifications/data/models/notification_model.dart';
import 'package:ustadia_user_app/features/notifications/presentation/bloc/notifications_bloc/notifications_bloc.dart';
import 'package:ustadia_user_app/features/notifications/presentation/bloc/notifications_bloc/notifications_event.dart';
import 'package:ustadia_user_app/features/notifications/presentation/bloc/notifications_bloc/notifications_state.dart';
import 'package:ustadia_user_app/features/notifications/presentation/widgets/notification_list_item.dart';
import 'package:ustadia_user_app/injection_container.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> with FormatDateMixin {
  final NotificationsBloc notificationsBloc = sl<NotificationsBloc>();
  BuildContext? dialogContext;
  bool shouldReloadTeachers = false;
  StreamSubscription? messageSubscription;

  @override
  void initState() {
    super.initState();
    notificationsBloc.add(const NotificationsRequested());
    messageSubscription = FirebaseMessagingService.notificationMessages.listen((_) {
      notificationsBloc.add(const NotificationsRequested(showLoading: false));
    });
  }

  @override
  void dispose() {
    messageSubscription?.cancel();
    notificationsBloc.close();
    super.dispose();
  }

  /// --- Methods ---

  void markAllRead() {
    notificationsBloc.add(const NotificationsMarkedAllRead());
  }

  bool canRespondToInvitation(NotificationApiModel notification) {
    final invitation = notification.invitation;
    if (invitation == null) return false;
    return invitation.status != 'accepted' && invitation.status != 'rejected';
  }

  void openNotification(NotificationApiModel notification) {
    if (!notification.isRead) {
      notificationsBloc.add(NotificationMarkedRead(notificationId: notification.id));
    }
    showDialog<void>(
      context: context,
      builder: (context) {
        dialogContext = context;
        return BlocBuilder<NotificationsBloc, NotificationsState>(
            bloc: notificationsBloc,
            builder: (context, state) {
              final notificationItem = state.notifications
                  .firstWhere((item) => item.id == notification.id, orElse: () => notification);
              final invitation = notificationItem.invitation;
              final showActions =
                  notificationItem.isInvitation && canRespondToInvitation(notificationItem);
              final isWorking =
                  state.actionStatus.isLoading && state.actionInvitationId == invitation?.id;
              return AlertDialog(
                title: Text(notificationItem.title),
                content: Text(notificationItem.message),
                actions: [
                  if (showActions)
                    TextButton(
                      onPressed: isWorking
                          ? null
                          : () {
                              notificationsBloc.add(NotificationInvitationRejected(
                                  notificationId: notification.id, invitationId: invitation!.id));
                            },
                      child: Text('Reject'.tr()),
                    ),
                  if (showActions)
                    TextButton(
                      onPressed: isWorking
                          ? null
                          : () {
                              shouldReloadTeachers = true;
                              notificationsBloc.add(NotificationInvitationAccepted(
                                  notificationId: notification.id, invitationId: invitation!.id));
                            },
                      child: Text('Accept'.tr()),
                    ),
                  if (!showActions)
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: Text('Close'.tr()),
                    ),
                ],
              );
            });
      },
    ).then((_) => dialogContext = null);
  }

  /// --- Widget Methods ---

  List<NotificationSection<NotificationApiModel>> sections(List<NotificationApiModel> items) {
    final grouped = <DateTime, List<NotificationApiModel>>{};
    for (final item in items) {
      final day = DateUtils.dateOnly(item.createdAt);
      grouped.putIfAbsent(day, () => []).add(item);
    }

    final sections = grouped.entries
        .map((entry) =>
            NotificationSection<NotificationApiModel>(date: entry.key, items: entry.value))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    for (final section in sections) {
      section.items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    return sections;
  }

  List<Widget> buildSectionWidgets(BuildContext context, List<NotificationApiModel> items) {
    final list = sections(items);
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
        Text('You don`t have any notifications yet'.tr(), style: Style.body3w7(context)),
        const SizedBox(height: 4),
        Text('New lessons, reminders, and learning updates will appear here.'.tr(),
            textAlign: TextAlign.center,
            style: Style.bodyw4(context, color: TextColorRole.greyColor))
      ]);

  PrimaryListView sectionList(NotificationSection<NotificationApiModel> section) => PrimaryListView(
      items: section.items,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (item) => NotificationListItem(
          notification: item.toDisplayModel(), onTap: () => openNotification(item)));

  Widget sectionListComponents(
          BuildContext context, NotificationSection<NotificationApiModel> section) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(formatDateLabel(section.date, DateTime.now()),
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 12),
        sectionList(section),
      ]);

  Widget listView(BuildContext context, List<NotificationApiModel> items) {
    final grouped = sections(items);
    return PrimaryListView(
        items: grouped,
        padding: const EdgeInsets.only(top: 12, bottom: 24),
        separatorHeight: 20,
        onRefresh: () async {
          notificationsBloc.add(const NotificationsRequested(showLoading: false));
        },
        itemBuilder: (item) => sectionListComponents(context, item));
  }

  Widget get readNotificationsButton => Align(
      alignment: Alignment.centerRight,
      child: Container(
          decoration: BoxDecoration(color: context.cs.surface, shape: BoxShape.circle),
          child:
              IconButton(onPressed: markAllRead, icon: SvgPicture.asset(AppImages.checkSquare))));

  Widget header(BuildContext context) => IntrinsicHeight(
          child: Stack(alignment: Alignment.center, children: [
        Text('Notifications'.tr(), style: Style.body2w6(context)),
        readNotificationsButton
      ]));

  Widget get contentChecker =>
      BlocStatusView<NotificationsBloc, NotificationsState, List<NotificationApiModel>>(
          bloc: notificationsBloc,
          statusOf: (s) => s.status,
          errorOf: (s) => s.errorMessage,
          data: (s) => s.notifications,
          isEmpty: (items) => items.isEmpty,
          empty: emptyState(context),
          builder: (context, items) => listView(context, items));

  @override
  Widget build(BuildContext context) => BlocListener<NotificationsBloc, NotificationsState>(
      bloc: notificationsBloc,
      listenWhen: (previous, current) => previous.actionStatus != current.actionStatus,
      listener: (context, state) {
        if (state.actionStatus.isError && state.actionErrorMessage != null) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(state.actionErrorMessage!)));
          shouldReloadTeachers = false;
          return;
        }
        if (state.actionStatus.isSuccess) {
          if (shouldReloadTeachers) {
            sl<TeacherBloc>().add(const TeachersRequested());
            shouldReloadTeachers = false;
          }
          notificationsBloc.add(const NotificationsRequested(showLoading: false));
        }
      },
      child: Scaffold(
          body: PrimaryBackground(
              header: header(context), isScrollable: false, child: contentChecker)));
}
