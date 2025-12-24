import 'package:dio/dio.dart';

class DioClient {
  DioClient._();

  static Dio create() {
    final options = BaseOptions(
      baseUrl: 'https://jsonplaceholder.typicode.com',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      responseType: ResponseType.json,
    );

    final dio = Dio(options);
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
    Dio dio = Dio(BaseOptions(baseUrl: "https://example.com"));

    dio.get("/some");
    // Keep logging minimal; swap with a proper logger if needed.
    // ignore: avoid_print
    print('[DIO] $message');
  }
}
