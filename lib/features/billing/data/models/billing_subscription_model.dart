import 'package:equatable/equatable.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_plan_model.dart';

/// `GET /students/billing/me` — the subscription the student has right now.
class BillingSubscriptionModel extends Equatable {
  final bool isSubscribed;
  final bool isTrial;
  final String? status;
  final BillingPlanModel? plan;
  final DateTime? startsAt;

  /// End of the paid period including queued plans; `null` for lifetime.
  final DateTime? endsAt;

  /// `null` means lifetime, not "0 days left".
  final int? daysLeft;

  const BillingSubscriptionModel(
      {required this.isSubscribed,
      required this.isTrial,
      required this.status,
      required this.plan,
      required this.startsAt,
      required this.endsAt,
      required this.daysLeft});

  const BillingSubscriptionModel.none()
      : isSubscribed = false,
        isTrial = false,
        status = null,
        plan = null,
        startsAt = null,
        endsAt = null,
        daysLeft = 0;

  factory BillingSubscriptionModel.fromJson(Map<String, dynamic> json) {
    final plan = json['plan'];
    final daysLeft = json['daysLeft'];
    return BillingSubscriptionModel(
        isSubscribed: json['isSubscribed'] == true,
        isTrial: json['isTrial'] == true,
        status: json['status']?.toString(),
        plan: plan is Map<String, dynamic> ? BillingPlanModel.fromJson(plan) : null,
        startsAt: DateTime.tryParse(json['startsAt']?.toString() ?? '')?.toLocal(),
        endsAt: DateTime.tryParse(json['endsAt']?.toString() ?? '')?.toLocal(),
        daysLeft: daysLeft is num ? daysLeft.toInt() : int.tryParse(daysLeft?.toString() ?? ''));
  }

  bool get isLifetime => isSubscribed && daysLeft == null;

  /// A lifetime student gets `400 ALREADY_LIFETIME`, so buying is hidden for them.
  bool get canPurchase => !isLifetime;

  @override
  List<Object?> get props => [isSubscribed, isTrial, status, plan, startsAt, endsAt, daysLeft];
}
