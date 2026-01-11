import 'package:dio/dio.dart';

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
    }));
    dio.interceptors.add(
      LogInterceptor(
        requestBody: true,
        responseBody: true,
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
}
