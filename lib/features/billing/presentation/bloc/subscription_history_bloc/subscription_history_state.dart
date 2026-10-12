import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_history_item_model.dart';

class SubscriptionHistoryState extends Equatable {
  final Status status;
  final List<BillingHistoryItemModel> items;
  final String? errorMessage;

  const SubscriptionHistoryState(
      {this.status = Status.initial, this.items = const [], this.errorMessage});

  SubscriptionHistoryState copyWith(
      {Status? status, List<BillingHistoryItemModel>? items, String? errorMessage}) {
    return SubscriptionHistoryState(
        status: status ?? this.status, items: items ?? this.items, errorMessage: errorMessage);
  }

  @override
  List<Object?> get props => [status, items, errorMessage];
}
