import 'package:equatable/equatable.dart';

enum BillingHistoryStatus {
  trial,
  active,
  expired,
  canceled,
  unknown;

  static BillingHistoryStatus fromRaw(Object? value) => switch (value?.toString().toLowerCase()) {
        'trial' => BillingHistoryStatus.trial,
        'active' => BillingHistoryStatus.active,
        'expired' => BillingHistoryStatus.expired,
        'canceled' || 'cancelled' => BillingHistoryStatus.canceled,
        _ => BillingHistoryStatus.unknown,
      };
}

/// One row of `GET /students/billing/history`.
class BillingHistoryItemModel extends Equatable {
  final String id;
  final String planName;
  final BillingHistoryStatus status;
  final bool isPaid;
  final String? paidAmount;
  final String currency;
  final DateTime? startsAt;

  /// `null` for lifetime.
  final DateTime? endsAt;
  final DateTime? createdAt;

  const BillingHistoryItemModel(
      {required this.id,
      required this.planName,
      required this.status,
      required this.isPaid,
      required this.paidAmount,
      required this.currency,
      required this.startsAt,
      required this.endsAt,
      required this.createdAt});

  factory BillingHistoryItemModel.fromJson(Map<String, dynamic> json) {
    final paidAmount = json['paidAmount']?.toString();
    return BillingHistoryItemModel(
        id: json['id']?.toString() ?? '',
        planName: json['planName']?.toString() ?? '',
        status: BillingHistoryStatus.fromRaw(json['status']),
        isPaid: json['source']?.toString() == 'payment',
        paidAmount: paidAmount == null || paidAmount.isEmpty ? null : paidAmount,
        currency: json['currency']?.toString() ?? 'UZS',
        startsAt: _parseDate(json['startsAt']),
        endsAt: _parseDate(json['endsAt']),
        createdAt: _parseDate(json['createdAt']));
  }

  /// A plan bought on top of an active one waits for its turn.
  bool isQueued(DateTime now) =>
      status == BillingHistoryStatus.active && (startsAt?.isAfter(now) ?? false);

  static DateTime? _parseDate(Object? value) =>
      DateTime.tryParse(value?.toString() ?? '')?.toLocal();

  @override
  List<Object?> get props =>
      [id, planName, status, isPaid, paidAmount, currency, startsAt, endsAt, createdAt];
}
