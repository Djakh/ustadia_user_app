import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:ustadia_user_app/core/enums/status.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';
import 'package:ustadia_user_app/features/billing/data/datasources/billing_remote_data_source.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_failure.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_plan_model.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_subscription_model.dart';
import 'package:ustadia_user_app/features/billing/data/services/payment_order_poller.dart';
import 'package:ustadia_user_app/features/billing/data/services/subscription_store.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_bloc/subscription_event.dart';
import 'package:ustadia_user_app/features/billing/presentation/bloc/subscription_bloc/subscription_state.dart';

class SubscriptionBloc extends Bloc<SubscriptionEvent, SubscriptionState> {
  final BillingRemoteDataSource billingRemoteDataSource;
  final SubscriptionStore subscriptionStore;
  final PaymentOrderPoller paymentOrderPoller;

  SubscriptionBloc(
      {required this.billingRemoteDataSource,
      required this.subscriptionStore,
      required this.paymentOrderPoller})
      : super(SubscriptionState(subscription: subscriptionStore.subscription.value)) {
    on<SubscriptionRequested>(handleRequested);
    on<SubscriptionPlanSelected>(handlePlanSelected);
    on<SubscriptionPurchaseRequested>(handlePurchaseRequested);
    on<SubscriptionCheckoutClosed>(handleCheckoutClosed);
    on<SubscriptionPurchaseAcknowledged>(handlePurchaseAcknowledged);
  }

  Future<void> handleRequested(SubscriptionRequested event, Emitter<SubscriptionState> emit) async {
    final showLoading = event.showLoading || state.plans.isEmpty;
    emit(state.copyWith(status: showLoading ? Status.loading : state.status));
    try {
      final results = await Future.wait<Object>(
          [billingRemoteDataSource.fetchPlans(), subscriptionStore.refresh()]);
      final plans = results[0] as List<BillingPlanModel>;
      final subscription = results[1] as BillingSubscriptionModel;
      emit(state.copyWith(
          status: Status.success,
          plans: plans,
          subscription: subscription,
          selectedPlanId: resolveSelectedPlanId(plans, subscription)));
    } on DioException catch (error) {
      emit(state.copyWith(
          status: showLoading ? Status.error : state.status,
          errorMessage: DioErrorMessage.from(error)));
    } catch (error) {
      emit(state.copyWith(
          status: showLoading ? Status.error : state.status,
          errorMessage: DioErrorMessage.fromUnknown(error)));
    } finally {
      event.completer?.complete();
    }
  }

  /// Keeps the student's choice if it still exists, otherwise suggests
  /// extending the current plan, otherwise the first plan.
  String? resolveSelectedPlanId(
      List<BillingPlanModel> plans, BillingSubscriptionModel subscription) {
    bool exists(String? id) => id != null && plans.any((plan) => plan.id == id);
    if (exists(state.selectedPlanId)) return state.selectedPlanId;
    final currentPlanId = subscription.plan?.id;
    if (!subscription.isTrial && exists(currentPlanId)) return currentPlanId;
    return plans.isEmpty ? null : plans.first.id;
  }

  void handlePlanSelected(SubscriptionPlanSelected event, Emitter<SubscriptionState> emit) {
    if (state.purchaseStatus.isBusy) return;
    if (!state.plans.any((plan) => plan.id == event.planId)) return;
    emit(state.copyWith(selectedPlanId: event.planId));
  }

  Future<void> handlePurchaseRequested(
      SubscriptionPurchaseRequested event, Emitter<SubscriptionState> emit) async {
    final plan = state.selectedPlan;
    // Every call opens a new order on the server, so a second tap is ignored.
    if (plan == null || !state.canStartPurchase) return;
    emit(state.copyWith(purchaseStatus: PurchaseStatus.creatingOrder, clearPurchase: true));
    try {
      final purchase = await billingRemoteDataSource.purchase(planId: plan.id);
      final checkoutUri = Uri.tryParse(purchase.checkoutUrl);
      if (purchase.id.isEmpty || checkoutUri == null || !checkoutUri.isScheme('https')) {
        emit(state.copyWith(
            purchaseStatus: PurchaseStatus.failure,
            purchaseMessage: BillingFailure.checkoutUnavailableMessage));
        return;
      }
      emit(state.copyWith(purchaseStatus: PurchaseStatus.awaitingCheckout, purchase: purchase));
    } catch (error) {
      final failure = BillingFailure.fromUnknown(error);
      emit(
          state.copyWith(purchaseStatus: PurchaseStatus.failure, purchaseMessage: failure.message));
      if (failure.type == BillingFailureType.planNotFound ||
          failure.type == BillingFailureType.alreadyLifetime) {
        add(const SubscriptionRequested(showLoading: false));
      }
    }
  }

  Future<void> handleCheckoutClosed(
      SubscriptionCheckoutClosed event, Emitter<SubscriptionState> emit) async {
    final purchase = state.purchase;
    if (purchase == null || state.purchaseStatus != PurchaseStatus.awaitingCheckout) return;
    emit(state.copyWith(purchaseStatus: PurchaseStatus.verifying));
    try {
      // Closed by hand: the student may still have paid, so check once.
      final outcome = await paymentOrderPoller.poll(purchase.id,
          maxAttempts: event.reachedReturnUrl ? null : 1, isAborted: () => isClosed);
      switch (outcome) {
        case PaymentOrderOutcome.aborted:
          return;
        case PaymentOrderOutcome.success:
          final subscription = await refreshSubscription();
          emit(state.copyWith(purchaseStatus: PurchaseStatus.success, subscription: subscription));
        case PaymentOrderOutcome.cancelled:
          emit(state.copyWith(purchaseStatus: PurchaseStatus.cancelled));
        case PaymentOrderOutcome.timeout:
          if (!event.reachedReturnUrl) {
            emit(state.copyWith(purchaseStatus: PurchaseStatus.notCompleted));
            return;
          }
          subscriptionStore.markStale();
          emit(state.copyWith(purchaseStatus: PurchaseStatus.pending));
        case PaymentOrderOutcome.notFound:
          final subscription = await refreshSubscription();
          emit(state.copyWith(
              purchaseStatus: PurchaseStatus.pending,
              subscription: subscription,
              purchaseMessage: BillingFailure.orderNotFoundMessage));
      }
    } catch (error) {
      emit(state.copyWith(
          purchaseStatus: PurchaseStatus.failure,
          purchaseMessage: BillingFailure.fromUnknown(error).message));
    }
  }

  /// A failed refresh must not hide a confirmed payment.
  Future<BillingSubscriptionModel?> refreshSubscription() async {
    try {
      return await subscriptionStore.refresh();
    } catch (_) {
      subscriptionStore.markStale();
      return null;
    }
  }

  void handlePurchaseAcknowledged(
      SubscriptionPurchaseAcknowledged event, Emitter<SubscriptionState> emit) {
    if (state.purchaseStatus.isBusy) return;
    emit(state.copyWith(purchaseStatus: PurchaseStatus.idle, clearPurchase: true));
  }
}
