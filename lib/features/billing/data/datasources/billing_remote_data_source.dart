import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_history_item_model.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_order_model.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_plan_model.dart';
import 'package:ustadia_user_app/features/billing/data/models/billing_subscription_model.dart';

class BillingRemoteDataSource {
  final Dio dio;

  BillingRemoteDataSource({required this.dio});

  /// Billing state changes outside the app (webhooks, admin), so it is never cached.
  Options get freshRequestOptions =>
      CacheOptions(policy: CachePolicy.noCache, store: MemCacheStore()).toOptions();

  Future<List<BillingPlanModel>> fetchPlans() async {
    final response = await dio.get('/students/billing/plans', options: freshRequestOptions);
    final plans = _list(response.data)
        .whereType<Map<String, dynamic>>()
        .map(BillingPlanModel.fromJson)
        .where((plan) => plan.id.isNotEmpty)
        .toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return plans;
  }

  Future<BillingSubscriptionModel> fetchMySubscription() async {
    final response = await dio.get('/students/billing/me', options: freshRequestOptions);
    return BillingSubscriptionModel.fromJson(_map(response.data));
  }

  /// The server picks the payment provider; sending one is rejected.
  Future<BillingPurchaseModel> purchase({required String planId}) async {
    final response = await dio.post('/students/billing/purchase',
        data: {'planId': planId}, options: freshRequestOptions);
    return BillingPurchaseModel.fromJson(_map(response.data));
  }

  Future<BillingOrderModel> fetchOrder(String orderId) async {
    final response = await dio.get('/payments/orders/$orderId', options: freshRequestOptions);
    return BillingOrderModel.fromJson(_map(response.data));
  }

  Future<List<BillingHistoryItemModel>> fetchHistory() async {
    final response = await dio.get('/students/billing/history', options: freshRequestOptions);
    return _list(response.data)
        .whereType<Map<String, dynamic>>()
        .map(BillingHistoryItemModel.fromJson)
        .toList();
  }

  Map<String, dynamic> _map(Object? data) {
    if (data is! Map<String, dynamic>) return <String, dynamic>{};
    final wrapped = data['data'];
    return wrapped is Map<String, dynamic> ? wrapped : data;
  }

  List<dynamic> _list(Object? data) {
    if (data is List) return data;
    if (data is Map<String, dynamic>) {
      final items = data['data'] ?? data['items'];
      if (items is List) return items;
    }
    return const [];
  }
}
