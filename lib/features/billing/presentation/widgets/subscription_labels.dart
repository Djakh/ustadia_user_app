import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_plan_model.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_subscription_model.dart';

/// Labels shared by the profile card, the subscription page and history.
class SubscriptionLabels {
  SubscriptionLabels._();

  static String date(DateTime value) {
    String twoDigits(int number) => number.toString().padLeft(2, '0');
    return '${twoDigits(value.day)}.${twoDigits(value.month)}.${value.year}';
  }

  static String daysLeft(int days) =>
      days == 1 ? '1 day left'.tr() : '{days} days left'.tr(namedArgs: {'days': days.toString()});

  static String duration(BillingPlanModel plan) {
    final days = plan.durationDays;
    if (plan.isLifetimePlan || days == null) return 'Lifetime'.tr();
    if (days >= 365 && days % 365 == 0) {
      final years = days ~/ 365;
      return years == 1 ? '1 year'.tr() : '{n} years'.tr(namedArgs: {'n': years.toString()});
    }
    if (days >= 30 && days % 30 == 0) {
      final months = days ~/ 30;
      return months == 1 ? '1 month'.tr() : '{n} months'.tr(namedArgs: {'n': months.toString()});
    }
    return '{n} days'.tr(namedArgs: {'n': days.toString()});
  }
}

enum SubscriptionTone { active, trial, lifetime, inactive }

/// How the current subscription is shown: one place decides tone, icon and text.
class SubscriptionStatusViewData {
  final SubscriptionTone tone;
  final String title;
  final String subtitle;
  final IconData icon;

  const SubscriptionStatusViewData(
      {required this.tone, required this.title, required this.subtitle, required this.icon});

  factory SubscriptionStatusViewData.from(BillingSubscriptionModel subscription) {
    final planName = subscription.plan?.name.trim() ?? '';
    final endsAt = subscription.endsAt;
    final daysLeft = subscription.daysLeft ?? 0;
    final remaining = endsAt == null
        ? SubscriptionLabels.daysLeft(daysLeft)
        : '${SubscriptionLabels.daysLeft(daysLeft)} · ${'until {date}'.tr(namedArgs: {
                'date': SubscriptionLabels.date(endsAt)
              })}';

    if (!subscription.isSubscribed) {
      return SubscriptionStatusViewData(
          tone: SubscriptionTone.inactive,
          title: 'No active subscription'.tr(),
          subtitle: 'Choose a plan to keep learning'.tr(),
          icon: Icons.lock_outline_rounded);
    }
    if (subscription.isLifetime) {
      return SubscriptionStatusViewData(
          tone: SubscriptionTone.lifetime,
          title: planName.isEmpty ? 'Lifetime'.tr() : planName,
          subtitle: 'Lifetime access'.tr(),
          icon: Icons.all_inclusive_rounded);
    }
    if (subscription.isTrial) {
      return SubscriptionStatusViewData(
          tone: SubscriptionTone.trial,
          title: 'Free trial'.tr(),
          subtitle: remaining,
          icon: Icons.hourglass_top_rounded);
    }
    return SubscriptionStatusViewData(
        tone: SubscriptionTone.active,
        title: planName.isEmpty ? 'Active subscription'.tr() : planName,
        subtitle: remaining,
        icon: Icons.workspace_premium_rounded);
  }

  Color get accent => switch (tone) {
        SubscriptionTone.active || SubscriptionTone.lifetime => AppColors.green36,
        SubscriptionTone.trial => AppColors.orange5A,
        SubscriptionTone.inactive => AppColors.error,
      };

  Color get background => switch (tone) {
        SubscriptionTone.active || SubscriptionTone.lifetime => AppColors.greenE7,
        SubscriptionTone.trial => AppColors.orangeEB,
        SubscriptionTone.inactive => AppColors.redE2,
      };

  String get badge => switch (tone) {
        SubscriptionTone.active => 'Active'.tr(),
        SubscriptionTone.lifetime => 'Lifetime'.tr(),
        SubscriptionTone.trial => 'Trial'.tr(),
        SubscriptionTone.inactive => 'Inactive'.tr(),
      };

  String get actionLabel => switch (tone) {
        SubscriptionTone.active => 'Extend'.tr(),
        SubscriptionTone.lifetime => 'Details'.tr(),
        SubscriptionTone.trial => 'Upgrade'.tr(),
        SubscriptionTone.inactive => 'Choose plan'.tr(),
      };
}
