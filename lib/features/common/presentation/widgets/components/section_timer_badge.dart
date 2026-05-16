import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';

class SectionTimerBadge extends StatefulWidget {
  final int? timeRemainingSeconds;
  final bool compact;
  final VoidCallback? onExpired;

  const SectionTimerBadge(
      {super.key, this.timeRemainingSeconds, this.compact = false, this.onExpired});

  @override
  State<SectionTimerBadge> createState() => SectionTimerBadgeState();
}

class SectionTimerBadgeState extends State<SectionTimerBadge> {
  Timer? timer;
  int? remainingSeconds;
  bool notifiedExpired = false;

  @override
  void initState() {
    super.initState();
    syncDeadline();
  }

  @override
  void didUpdateWidget(covariant SectionTimerBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.timeRemainingSeconds == widget.timeRemainingSeconds) {
      return;
    }
    syncDeadline();
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  void syncDeadline() {
    timer?.cancel();
    notifiedExpired = false;
    final seconds = widget.timeRemainingSeconds;
    remainingSeconds = seconds;
    if (remainingSeconds == null) return;
    if (seconds != null && seconds <= 0) {
      WidgetsBinding.instance.addPostFrameCallback((_) => notifyExpired());
      return;
    }
    timer = Timer.periodic(const Duration(seconds: 1), (_) => tick());
  }

  Duration get remainingDuration {
    final seconds = remainingSeconds;
    if (seconds == null || seconds <= 0) return Duration.zero;
    return Duration(seconds: seconds);
  }

  String get label {
    final duration = remainingDuration;
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (hours > 0) return '$hours:$minutes:$seconds';
    return '$minutes:$seconds';
  }

  void tick() {
    if (!mounted) return;
    final seconds = remainingSeconds;
    if (seconds != null && seconds > 0) remainingSeconds = seconds - 1;
    if (remainingDuration == Duration.zero && !notifiedExpired) {
      notifyExpired();
      if (!mounted) return;
    }
    setState(() {});
  }

  void notifyExpired() {
    if (!mounted || notifiedExpired) return;
    notifiedExpired = true;
    timer?.cancel();
    widget.onExpired?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (remainingSeconds == null) return const SizedBox.shrink();
    return Container(
        padding: EdgeInsets.symmetric(
            horizontal: widget.compact ? 8 : 12, vertical: widget.compact ? 5 : 8),
        decoration: BoxDecoration(
            color: AppColors.blueFF,
            borderRadius: widget.compact ? Style.border8 : Style.border12,
            border: Border.all(color: AppColors.blueD3.withValues(alpha: 0.16))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.timer_outlined, size: 16, color: AppColors.blueD3),
          const SizedBox(width: 6),
          Text(label, style: Style.small2w5(context).copyWith(color: AppColors.blueD3))
        ]));
  }
}
