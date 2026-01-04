import 'package:flutter/material.dart';

mixin FormatDateMixin {
  String formatDateLabel(DateTime date, DateTime now) {
    final today = DateUtils.dateOnly(now);
    final target = DateUtils.dateOnly(date);
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final label = '${target.day} ${months[target.month - 1]} ${target.year}';

    if (target == today) {
      return 'Today, $label';
    }
    if (target == today.subtract(const Duration(days: 1))) {
      return 'Yesterday, $label';
    }
    return label;
  }
}
