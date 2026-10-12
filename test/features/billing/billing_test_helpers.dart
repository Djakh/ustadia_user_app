import 'package:dio/dio.dart';

/// A canned response; `statusCode >= 400` is delivered as a [DioException].
class FakeResponse {
  final int statusCode;
  final Object? data;

  const FakeResponse(this.data, {this.statusCode = 200});
}

typedef FakeHandler = FakeResponse Function(RequestOptions options);

/// In-memory billing backend: routes are `'METHOD /path'`, each call is recorded.
class FakeBillingApi {
  final Map<String, FakeHandler> routes = {};
  final List<RequestOptions> requests = [];
  late final Dio dio = Dio(BaseOptions(baseUrl: 'https://example.com'))
    ..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requests.add(options);
      final route = routes['${options.method} ${options.path}'];
      if (route == null) {
        handler
            .reject(_error(options, const FakeResponse({'message': 'Not found'}, statusCode: 404)));
        return;
      }
      final response = route(options);
      if (response.statusCode >= 400) {
        handler.reject(_error(options, response));
        return;
      }
      handler.resolve(Response<dynamic>(
          requestOptions: options, statusCode: response.statusCode, data: response.data));
    }));

  void on(String route, FakeResponse response) => routes[route] = (_) => response;

  /// Replies with [responses] in order, repeating the last one.
  void onSequence(String route, List<FakeResponse> responses) {
    var index = 0;
    routes[route] = (_) => responses[index < responses.length - 1 ? index++ : index];
  }

  int count(String route) =>
      requests.where((options) => '${options.method} ${options.path}' == route).length;

  static DioException _error(RequestOptions options, FakeResponse response) => DioException(
      requestOptions: options,
      type: DioExceptionType.badResponse,
      response: Response<dynamic>(
          requestOptions: options, statusCode: response.statusCode, data: response.data));
}

const standardPlanId = '474147b8-41a9-45e9-a442-b5ca37f90a47';
const plusPlanId = '5c1e7b0e-7a43-4a8f-9a1e-1f2b3c4d5e6f';
const maxPlanId = '9d8c7b6a-5f4e-4d3c-8b2a-1a0b9c8d7e6f';
const orderId = 'f0ad81b7-4b87-47aa-8bfa-baf90ca9b2ac';

Map<String, dynamic> planJson(
        {String id = standardPlanId,
        String name = 'Standard',
        String price = '36000',
        int? durationDays = 30,
        bool isLifetime = false,
        int sortOrder = 1,
        List<String> features = const [],
        String? description = '1 oylik obuna'}) =>
    {
      'id': id,
      'name': name,
      'audience': 'student',
      'description': description,
      'price': price,
      'currency': 'UZS',
      'duration_days': durationDays,
      'is_lifetime': isLifetime,
      'features': features,
      'sort_order': sortOrder,
      'is_active': true,
      'created_at': '2026-09-07T04:30:37.009Z',
      'updated_at': '2026-10-09T09:47:36.506Z',
    };

List<Map<String, dynamic>> prodPlans() => [
      planJson(),
      planJson(id: plusPlanId, name: 'Plus', price: '200000', durationDays: 180, sortOrder: 2),
      planJson(
          id: maxPlanId,
          name: 'Max',
          price: '590000',
          durationDays: null,
          isLifetime: true,
          sortOrder: 4,
          features: ['All courses forever']),
    ];

Map<String, dynamic> meJson(
        {bool isSubscribed = true,
        bool isTrial = false,
        Map<String, dynamic>? plan,
        String? endsAt = '2026-12-08T09:16:12.819Z',
        int? daysLeft = 60}) =>
    {
      'isSubscribed': isSubscribed,
      'isTrial': isTrial,
      'status': isSubscribed ? (isTrial ? 'trial' : 'active') : null,
      'plan': isSubscribed ? (plan ?? planJson()) : null,
      'startsAt': isSubscribed ? '2026-10-09T09:16:12.819Z' : null,
      'endsAt': isSubscribed ? endsAt : null,
      'daysLeft': isSubscribed ? daysLeft : 0,
    };

Map<String, dynamic> notSubscribedJson() => meJson(isSubscribed: false);

Map<String, dynamic> purchaseJson({String planId = standardPlanId}) => {
      'id': orderId,
      'external_id': 'plan-user-1760000000',
      'plan_id': planId,
      'order_id': 'order-1',
      'payment_id': null,
      'provider': 'paylov',
      'amount': '36000',
      'state': '1',
      'checkout_url': 'https://my.paylov.uz/checkout/abc',
      'return_url': 'https://students.ustadia.com/plans/return',
    };

Map<String, dynamic> orderJson(String state) => {
      'id': orderId,
      'plan_id': standardPlanId,
      'provider': 'paylov',
      'amount': '36000',
      'fee_amount': '360',
      'paid_amount': '36360',
      'state': state,
    };
