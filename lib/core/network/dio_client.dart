import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';

class DioClient {
  DioClient._();

  static Dio create({String? baseUrl, String Function()? accessTokenGetter}) {
    final options = BaseOptions(
      baseUrl: baseUrl ?? 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    );

    final dio = Dio(options);
    final cacheOptions = CacheOptions(
        store: MemCacheStore(),
        policy: CachePolicy.request,
        hitCacheOnErrorExcept: [401, 403],
        maxStale: const Duration(days: 7));
    dio.interceptors.add(DioCacheInterceptor(options: cacheOptions));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      final accessToken = accessTokenGetter?.call() ?? '';
      if (accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
        // ignore: avoid_print
        print('[DIO] accessToken: $accessToken');
      }
      return handler.next(options);
    }, onResponse: (response, handler) {
      _logResponsePretty(response);
      return handler.next(response);
    }));
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: false,
        logPrint: (obj) => _log(obj.toString()),
      ),
    );
    return dio;
  }

  static void _log(String message) {
    // Keep logging minimal; swap with a proper logger if needed.
    // ignore: avoid_print
    print('[DIO] $message');
  }

  static void _logResponsePretty(Response<dynamic> response) {
    final data = response.data;
    if (data == null) return;
    String output;
    if (data is String) {
      final decoded = _tryDecodeJson(data);
      if (decoded != null) {
        output = const JsonEncoder.withIndent('  ').convert(_sanitizeForLog(decoded));
      } else {
        output = _singleLine(data);
      }
    } else if (data is Map || data is List) {
      output = const JsonEncoder.withIndent('  ').convert(_sanitizeForLog(data));
    } else {
      output = data.toString();
    }
    // ignore: avoid_print
    print('[DIO] Response Pretty:\\n$output');
  }

  static dynamic _tryDecodeJson(String value) {
    try {
      return jsonDecode(value);
    } catch (_) {
      return null;
    }
  }

  static dynamic _sanitizeForLog(dynamic value) {
    if (value is Map) {
      return value.map((key, val) => MapEntry(key, _sanitizeForLog(val)));
    }
    if (value is List) {
      return value.map(_sanitizeForLog).toList();
    }
    if (value is String) {
      return _singleLine(value);
    }
    return value?.toString() ?? 'null';
  }

  static String _singleLine(String input) {
    final normalized = input.replaceAll(RegExp(r'\s+'), ' ').trim();
    if (normalized.length <= 120) return normalized;
    return '${normalized.substring(0, 117)}...';
  }
}
