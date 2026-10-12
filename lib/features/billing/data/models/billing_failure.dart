import 'package:dio/dio.dart';
import 'package:ustadia_user_app/core/network/dio_error_message.dart';

/// Documented billing errors, so the UI can react (reload plans, refresh `/me`)
/// instead of only printing the backend text.
enum BillingFailureType {
  alreadyLifetime,
  providerDisabled,
  planNotFound,
  orderNotFound,
  checkoutUnavailable,
  other,
}

class BillingFailure {
  static const alreadyLifetimeMessage = 'You already have a lifetime plan';
  static const providerDisabledMessage = 'This payment method is not available right now';
  static const planNotFoundMessage = 'This plan is no longer available. The list has been updated';
  static const orderNotFoundMessage = 'Payment not found. Check your subscription status';
  static const checkoutUnavailableMessage =
      'Could not open the payment page. Please try again later';

  final BillingFailureType type;
  final String message;

  const BillingFailure({required this.type, required this.message});

  factory BillingFailure.fromDio(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final code = data is Map ? data['code']?.toString() : null;
    final backendMessage = data is Map ? data['message']?.toString().toLowerCase() ?? '' : '';

    if (code == 'ALREADY_LIFETIME') {
      return const BillingFailure(
          type: BillingFailureType.alreadyLifetime, message: alreadyLifetimeMessage);
    }
    if (code == 'PROVIDER_DISABLED') {
      return const BillingFailure(
          type: BillingFailureType.providerDisabled, message: providerDisabledMessage);
    }
    if (statusCode == 404 && backendMessage.contains('order')) {
      return const BillingFailure(
          type: BillingFailureType.orderNotFound, message: orderNotFoundMessage);
    }
    if (statusCode == 404) {
      return const BillingFailure(
          type: BillingFailureType.planNotFound, message: planNotFoundMessage);
    }
    if (statusCode != null && statusCode >= 500) {
      return const BillingFailure(
          type: BillingFailureType.checkoutUnavailable, message: checkoutUnavailableMessage);
    }
    return BillingFailure(type: BillingFailureType.other, message: DioErrorMessage.from(error));
  }

  factory BillingFailure.fromUnknown(Object error) => error is DioException
      ? BillingFailure.fromDio(error)
      : BillingFailure(type: BillingFailureType.other, message: DioErrorMessage.fromUnknown(error));
}
