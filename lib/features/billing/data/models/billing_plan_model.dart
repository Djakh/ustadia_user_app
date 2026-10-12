import 'package:equatable/equatable.dart';

class BillingPlanModel extends Equatable {
  final String id;
  final String name;
  final String? description;

  /// Whole sum amount as sent by the backend (`"36000"`); never parsed to double.
  final String price;
  final String currency;

  /// `null` for a lifetime plan.
  final int? durationDays;
  final bool isLifetime;
  final List<String> features;
  final int sortOrder;

  const BillingPlanModel(
      {required this.id,
      required this.name,
      required this.description,
      required this.price,
      required this.currency,
      required this.durationDays,
      required this.isLifetime,
      required this.features,
      required this.sortOrder});

  factory BillingPlanModel.fromJson(Map<String, dynamic> json) {
    final description = json['description']?.toString().trim();
    final features = json['features'];
    return BillingPlanModel(
        id: json['id']?.toString() ?? '',
        name: json['name']?.toString() ?? '',
        description: description == null || description.isEmpty ? null : description,
        price: json['price']?.toString() ?? '0',
        currency: json['currency']?.toString() ?? 'UZS',
        durationDays: _parseInt(json['duration_days']),
        isLifetime: json['is_lifetime'] == true,
        features: features is List
            ? features
                .map((feature) => feature?.toString().trim() ?? '')
                .where((feature) => feature.isNotEmpty)
                .toList()
            : const [],
        sortOrder: _parseInt(json['sort_order']) ?? 0);
  }

  /// The backend marks lifetime plans both ways; trust either signal.
  bool get isLifetimePlan => isLifetime || durationDays == null;

  static int? _parseInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  @override
  List<Object?> get props =>
      [id, name, description, price, currency, durationDays, isLifetime, features, sortOrder];
}
