import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/mock_exam/data/datasources/mock_exam_remote_data_source.dart';

void main() {
  test('mock exam requests use the injected Dio base URL', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://backend.ustadia.findecor.io'));
    final requestedUris = <Uri>[];
    dio.interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
      requestedUris.add(options.uri);
      handler.resolve(Response(requestOptions: options, data: const {'items': []}));
    }));
    final dataSource = MockExamRemoteDataSource(dio: dio);

    await dataSource.fetchMockExams();
    await dataSource.generateMockExamTempToken(mockExamId: 'mock-1');

    expect(requestedUris.map((uri) => uri.origin),
        everyElement('https://backend.ustadia.findecor.io'));
    expect(requestedUris.map((uri) => uri.path), [
      '/student/ielts-mocks',
      '/student/ielts-mocks/mock-1/generate-temp-token',
    ]);
  });

  test('mock section start response keeps audio from data wrapper', () {
    final dataSource = MockExamRemoteDataSource(dio: Dio());

    final sectionData = dataSource.sectionStartData({
      'data': {
        'section': {'id': 'section-1', 'type': 'listening', 'title': 'Listening', 'order_index': 1},
        'questions': [
          {'id': 'question-1', 'type': 'fill-blank', 'order_index': 1}
        ],
        'audio': {
          'id': 'audio-1',
          'url': '/uploads/audio/mock-listening.mp3',
          'filename': 'mock-listening.mp3'
        },
        'time_remaining_seconds': 1200
      }
    });

    final section = SectionModel.fromJson(sectionData,
        source: SectionSource.mockExam, mockId: 'mock-1', mockAttemptId: 'attempt-1');

    expect(section.id, 'section-1');
    expect(section.sectionType, SectionType.listening);
    expect(section.questions, hasLength(1));
    expect(section.timeRemainingSeconds, 1200);
    expect(section.audioFile?.url, '/uploads/audio/mock-listening.mp3');
  });

  test('section model reads direct audio url aliases', () {
    final section = SectionModel.fromJson({
      'id': 'section-1',
      'type': 'listening',
      'title': 'Listening',
      'audio_url': '/uploads/audio/direct.mp3'
    });

    expect(section.audioFile?.url, '/uploads/audio/direct.mp3');
  });
}
