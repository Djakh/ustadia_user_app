import 'package:dio/dio.dart';
import 'dart:convert';

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
      output = _tryPrettyJsonString(data) ?? data;
    } else if (data is Map || data is List) {
      output = const JsonEncoder.withIndent('  ').convert(data);
    } else {
      output = data.toString();
    }
    // ignore: avoid_print
    print('[DIO] Response Pretty:\\n$output');
  }

  static String? _tryPrettyJsonString(String value) {
    try {
      final decoded = jsonDecode(value);
      return const JsonEncoder.withIndent('  ').convert(decoded);
    } catch (_) {
      return null;
    }
  }
}
