import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/learn/data/datasources/learn_remote_data_source.dart';

void main() {
  test('redo section posts to the reset endpoint', () async {
    String? requestedMethod;
    String? requestedPath;
    final dio = Dio(BaseOptions(baseUrl: 'https://dev.backend.ustadia.com'));
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requestedMethod = options.method;
      requestedPath = options.path;
      handler.resolve(Response<Map<String, dynamic>>(requestOptions: options, data: {
        'sectionId': 'section_1',
        'deletedAnswers': 4,
        'resetFlashcards': 0,
        'revokedXp': 0,
        'message': 'Section reset. You can complete it again.',
      }));
    }));

    await LearnRemoteDataSource(dio: dio).redoSection(sectionId: 'section_1');

    expect(requestedMethod, 'POST');
    expect(requestedPath, '/students/sections/section_1/redo');
  });
}
