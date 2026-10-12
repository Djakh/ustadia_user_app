import 'package:equatable/equatable.dart';

/// `POST /students/billing/purchase` — a fresh order and where to pay it.
class BillingPurchaseModel extends Equatable {
  final String id;
  final String planId;
  final String amount;
  final String checkoutUrl;
  final String returnUrl;

  const BillingPurchaseModel(
      {required this.id,
      required this.planId,
      required this.amount,
      required this.checkoutUrl,
      required this.returnUrl});

  factory BillingPurchaseModel.fromJson(Map<String, dynamic> json) => BillingPurchaseModel(
      id: json['id']?.toString() ?? '',
      planId: json['plan_id']?.toString() ?? '',
      amount: json['amount']?.toString() ?? '0',
      checkoutUrl: json['checkout_url']?.toString() ?? '',
      returnUrl: json['return_url']?.toString() ?? '');

  @override
  List<Object?> get props => [id, planId, amount, checkoutUrl, returnUrl];
}

enum BillingOrderState {
  success,
  cancelled,
  pending;

  /// Only `SUCCESS` and `CANCELLED` are final; any other value is still in progress.
  static BillingOrderState fromRaw(Object? value) => switch (value?.toString().toUpperCase()) {
        'SUCCESS' => BillingOrderState.success,
        'CANCELLED' => BillingOrderState.cancelled,
        _ => BillingOrderState.pending,
      };
}

/// `GET /payments/orders/:id` — only the fields the app may rely on.
class BillingOrderModel extends Equatable {
  final String id;
  final BillingOrderState state;

  const BillingOrderModel({required this.id, required this.state});

  factory BillingOrderModel.fromJson(Map<String, dynamic> json) => BillingOrderModel(
      id: json['id']?.toString() ?? '', state: BillingOrderState.fromRaw(json['state']));

  @override
  List<Object?> get props => [id, state];
}
