import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_order_model.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_plan_model.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_subscription_model.dart';

enum PurchaseStatus {
  idle,
  creatingOrder,
  awaitingCheckout,
  verifying,
  success,
  cancelled,

  /// Returned from Paylov but no final state within the polling window.
  pending,

  /// Student closed the checkout and the single check found nothing final.
  notCompleted,
  failure;

  bool get isBusy =>
      this == PurchaseStatus.creatingOrder ||
      this == PurchaseStatus.awaitingCheckout ||
      this == PurchaseStatus.verifying;
}

class SubscriptionState extends Equatable {
  final Status status;
  final List<BillingPlanModel> plans;
  final BillingSubscriptionModel? subscription;
  final String? selectedPlanId;
  final String? errorMessage;
  final PurchaseStatus purchaseStatus;
  final BillingPurchaseModel? purchase;
  final String? purchaseMessage;

  const SubscriptionState(
      {this.status = Status.initial,
      this.plans = const [],
      this.subscription,
      this.selectedPlanId,
      this.errorMessage,
      this.purchaseStatus = PurchaseStatus.idle,
      this.purchase,
      this.purchaseMessage});

  BillingPlanModel? get selectedPlan {
    for (final plan in plans) {
      if (plan.id == selectedPlanId) return plan;
    }
    return null;
  }

  bool get canPurchase => subscription?.canPurchase ?? true;

  bool get canStartPurchase =>
      canPurchase && selectedPlan != null && !purchaseStatus.isBusy && status.isSuccess;

  SubscriptionState copyWith(
      {Status? status,
      List<BillingPlanModel>? plans,
      BillingSubscriptionModel? subscription,
      String? selectedPlanId,
      String? errorMessage,
      PurchaseStatus? purchaseStatus,
      BillingPurchaseModel? purchase,
      bool clearPurchase = false,
      String? purchaseMessage}) {
    return SubscriptionState(
        status: status ?? this.status,
        plans: plans ?? this.plans,
        subscription: subscription ?? this.subscription,
        selectedPlanId: selectedPlanId ?? this.selectedPlanId,
        errorMessage: errorMessage,
        purchaseStatus: purchaseStatus ?? this.purchaseStatus,
        purchase: clearPurchase ? null : purchase ?? this.purchase,
        purchaseMessage: purchaseMessage);
  }

  @override
  List<Object?> get props => [
        status,
        plans,
        subscription,
        selectedPlanId,
        errorMessage,
        purchaseStatus,
        purchase,
        purchaseMessage
      ];
}
