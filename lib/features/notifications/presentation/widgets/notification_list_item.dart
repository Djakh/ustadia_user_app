import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/extensions/build_context_extension.dart';
import 'package:ustadia_user_app/features/notifications/data/models/notification_model.dart';

class NotificationListItem extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;

  const NotificationListItem({super.key, required this.notification, this.onTap});

  Color _titleColor(BuildContext context) =>
      notification.isRead ? context.cs.onTertiary : context.cs.onSurface;

  Color _messageColor(BuildContext context) =>
      notification.isRead ? context.cs.onTertiary.withValues(alpha: 0.7) : context.cs.onTertiary;

  ColorFilter? _iconTint(BuildContext context) => notification.isRead
      ? ColorFilter.mode(context.cs.onTertiary.withValues(alpha: 0.6), BlendMode.srcIn)
      : null;

  Widget _icon(BuildContext context) =>
      SvgPicture.asset(notification.iconAsset, colorFilter: _iconTint(context));

  Widget _textContent(BuildContext context) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(notification.title,
              style: Style.bodyw6(context).copyWith(color: _titleColor(context))),
          const SizedBox(height: 4),
          Text(notification.message,
              style: Style.small3w4(context).copyWith(color: _messageColor(context))),
        ]),
      );

  Row view(BuildContext context) =>
      Row(children: [_icon(context), const SizedBox(width: 12), _textContent(context)]);

  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
          onTap: onTap,
          borderRadius: Style.border16,
          child: Ink(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: context.cs.surface, borderRadius: Style.border16),
              child: view(context))));
}
