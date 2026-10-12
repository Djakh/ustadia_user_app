import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ustadia_user_app/assets/themes/app_colors.dart';
import 'package:ustadia_user_app/assets/themes/style.dart';
import 'package:ustadia_user_app/core/widgets/buttons/button.dart';
import 'package:ustadia_user_app/core/widgets/cards/primary_background.dart';
import 'package:ustadia_user_app/core/widgets/content_checkers/primary_content_checker.dart';
import 'package:ustadia_user_app/core/widgets/loading/shimmer_list.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_history_item_model.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_history_bloc/subscription_history_bloc.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_history_bloc/subscription_history_event.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_history_bloc/subscription_history_state.dart';
import 'package:ustadia_user_app/features/billing/presentation/widgets/subscription_history_card.dart';
import 'package:ustadia_user_app/injection_container.dart';

class SubscriptionHistoryPage extends StatefulWidget {
  const SubscriptionHistoryPage({super.key});

  @override
  State<SubscriptionHistoryPage> createState() => SubscriptionHistoryPageState();
}

class SubscriptionHistoryPageState extends State<SubscriptionHistoryPage> {
  final SubscriptionHistoryBloc historyBloc = sl<SubscriptionHistoryBloc>();

  @override
  void initState() {
    super.initState();
    historyBloc.add(const SubscriptionHistoryRequested());
  }

  @override
  void dispose() {
    historyBloc.close();
    super.dispose();
  }

  Future<void> reload() {
    final completer = Completer<void>();
    historyBloc.add(SubscriptionHistoryRequested(showLoading: false, completer: completer));
    return completer.future;
  }

  /// --- Widgets ---

  Widget emptyState(BuildContext context) => Center(
      child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
                height: 68,
                width: 68,
                decoration: const BoxDecoration(color: AppColors.greenE7, shape: BoxShape.circle),
                child: const Icon(Icons.receipt_long_rounded, color: AppColors.green36, size: 32)),
            const SizedBox(height: 14),
            Text('No subscriptions yet'.tr(),
                textAlign: TextAlign.center, style: Style.bodyw6(context)),
            const SizedBox(height: 6),
            Text('Your plans and payments will appear here'.tr(),
                textAlign: TextAlign.center,
                style: Style.small3w4(context, color: TextColorRole.greyColor))
          ])));

  Widget errorView(String message) => Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(message.tr(),
            textAlign: TextAlign.center,
            style: Style.small3w4(context, color: TextColorRole.greyColor)),
        const SizedBox(height: 8),
        Button.text(
            onTap: () => historyBloc.add(const SubscriptionHistoryRequested()), text: 'Reload'.tr())
      ]));

  Widget list(List<BillingHistoryItemModel> items) {
    final now = DateTime.now();
    return RefreshIndicator(
        onRefresh: reload,
        child: ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 16, bottom: 24),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, index) => SubscriptionHistoryCard(item: items[index], now: now)));
  }

  Widget body(BuildContext context) => BlocStatusView<SubscriptionHistoryBloc,
          SubscriptionHistoryState, List<BillingHistoryItemModel>>(
      bloc: historyBloc,
      statusOf: (state) => state.status,
      errorOf: (state) => state.errorMessage,
      data: (state) => state.items,
      isEmpty: (items) => items.isEmpty,
      keepDataOnLoading: true,
      loading: ShimmerList(
          itemCount: 4,
          itemHeight: 84,
          padding: const EdgeInsets.only(top: 16),
          borderRadius: Style.border20),
      empty: RefreshIndicator(
          onRefresh: reload,
          child: ListView(
              physics: const AlwaysScrollableScrollPhysics(), children: [emptyState(context)])),
      errorBuilder: errorView,
      builder: (context, items) => list(items));

  @override
  Widget build(BuildContext context) => Scaffold(
      body: PrimaryBackground(
          title: 'Subscription history'.tr(), isScrollable: false, child: body(context)));
}
