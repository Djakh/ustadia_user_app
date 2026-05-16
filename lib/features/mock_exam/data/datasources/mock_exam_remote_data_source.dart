import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:ustadia_user_app/core/pagination/pagination_meta.dart';
import 'package:ustadia_user_app/core/pagination/pagination_result.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_stats_model.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_attempt_model.dart';
import 'package:ustadia_user_app/features/mock_exam/data/models/mock_exam_model.dart';

class MockExamRemoteDataSource {
  final Dio dio;

  MockExamRemoteDataSource({required this.dio});

  Options get freshRequestOptions =>
      CacheOptions(policy: CachePolicy.noCache, store: MemCacheStore()).toOptions();

  String get baseUrl => 'https://dev.backend.ustadia.findecor.io/student/ielts-mocks';

  Future<PaginationResult<MockExamModel>> fetchMockExams({int page = 1, int limit = 10}) async {
    final response = await dio.get(baseUrl,
        queryParameters: {'page': page, 'limit': limit}, options: freshRequestOptions);
    final responseData = response.data;
    final data = responseData is Map<String, dynamic> ? responseData : <String, dynamic>{};
    final items = responseData is List ? responseData : data['items'] as List<dynamic>? ?? [];
    final exams = items.whereType<Map<String, dynamic>>().map(MockExamModel.fromJson).toList();
    final pagination = PaginationMeta.fromJson(data);
    return PaginationResult(items: exams, meta: pagination);
  }

  Future<MockExamAttemptModel> startMockExamAttempt({required String mockExamId}) async {
    final response =
        await dio.post('$baseUrl/$mockExamId/attempts/start', options: freshRequestOptions);
    return MockExamAttemptModel.fromJson(response.data as Map<String, dynamic>,
        mockExamId: mockExamId);
  }

  Future<MockExamAttemptModel> startMockExamAttemptFromExam(MockExamModel exam) async {
    if (exam.isFinished) {
      return MockExamAttemptModel(
          attemptId: exam.resultAttemptId,
          mockExamId: exam.id,
          status: 'finished',
          isFinished: true,
          startedAt: exam.assignment?.attempt?.startedAt ?? exam.assign?.startedAt,
          finishedAt: exam.assignment?.attempt?.finishedAt ?? exam.assign?.finishedAt,
          timeLimitMinutes: exam.timeLimit,
          timeRemainingSeconds: exam.timeRemainingSeconds,
          currentComponent: '',
          currentSubSectionId: exam.assignment?.attempt?.currentSubSectionId ?? '',
          components: const []);
    }
    return startMockExamAttempt(mockExamId: exam.id);
  }

  Future<MockExamAttemptModel> fetchMockExamAttempt({
    required String mockExamId,
    required String attemptId,
  }) async {
    final response =
        await dio.get('$baseUrl/$mockExamId/attempts/$attemptId', options: freshRequestOptions);
    return MockExamAttemptModel.fromJson(response.data as Map<String, dynamic>,
        mockExamId: mockExamId);
  }

  Future<List<SectionModel>> fetchMockExamSections({required String mockExamId}) async {
    final attempt = await startMockExamAttempt(mockExamId: mockExamId);
    return attempt.components
        .expand((component) =>
            component.subSections.isNotEmpty ? component.subSections : [component.directSection])
        .toList();
  }

  Future<SectionModel> fetchMockExamSectionDetail({
    required String mockExamId,
    required String attemptId,
    required String sectionId,
  }) async {
    final response = await dio.post(
        '$baseUrl/$mockExamId/attempts/$attemptId/sections/$sectionId/start',
        options: freshRequestOptions);
    final data = response.data as Map<String, dynamic>;
    final sectionData = data['section'] is Map<String, dynamic>
        ? Map<String, dynamic>.from(data['section'] as Map<String, dynamic>)
        : data['sub_section'] is Map<String, dynamic>
            ? Map<String, dynamic>.from(data['sub_section'] as Map<String, dynamic>)
            : Map<String, dynamic>.from(data);
    sectionData['questions'] ??= data['questions'];
    sectionData['time_remaining_seconds'] ??= data['time_remaining_seconds'];
    sectionData['time_limit_seconds'] ??= data['time_limit_seconds'];
    sectionData['deadline_at'] ??= data['deadline_at'];
    sectionData['status'] ??= data['status'];
    return SectionModel.fromJson(sectionData,
        source: SectionSource.mockExam, mockId: mockExamId, mockAttemptId: attemptId);
  }

  Future<Map<String, dynamic>> submitMockExamAnswer({
    required String mockExamId,
    required String attemptId,
    required String sectionId,
    required Map<String, dynamic> answer,
  }) async {
    final response = await dio.post(
      '$baseUrl/$mockExamId/attempts/$attemptId/sections/$sectionId/submit',
      data: {
        'answers': [answer]
      },
    );
    return response.data as Map<String, dynamic>;
  }

  Future<SectionStatsModel> fetchMockExamSectionStats({
    required String mockExamId,
    required String attemptId,
    required String sectionId,
  }) async {
    final result = await fetchMockExamResult(mockExamId: mockExamId, attemptId: attemptId);
    final total = result.overallBand == null ? 0 : 1;
    return SectionStatsModel(
        sectionId: sectionId,
        sectionType: '',
        totalQuestions: total,
        answeredQuestions: total,
        unansweredQuestions: 0,
        correct: 0,
        incorrect: 0,
        pending: total);
  }

  Future<Map<String, dynamic>> finishMockExamSection({
    required String mockExamId,
    required String attemptId,
    required String sectionId,
  }) async {
    final response =
        await dio.post('$baseUrl/$mockExamId/attempts/$attemptId/sections/$sectionId/finish');
    return response.data as Map<String, dynamic>;
  }

  Future<MockExamResultModel> finishMockExam({
    required String mockExamId,
    required String attemptId,
  }) async {
    final response = await dio.post('$baseUrl/$mockExamId/attempts/$attemptId/finish');
    return MockExamResultModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<MockExamResultModel> fetchMockExamResult({
    required String mockExamId,
    required String attemptId,
  }) async {
    final response = await dio.get('$baseUrl/$mockExamId/attempts/$attemptId/result',
        options: freshRequestOptions);
    return MockExamResultModel.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MockExamHistoryModel>> fetchAllMockExamHistory() async {
    final response = await dio.get('$baseUrl/results/all', options: freshRequestOptions);
    final data = response.data;
    final items = data is List
        ? data
        : data is Map<String, dynamic>
            ? data['items'] as List<dynamic>? ?? data['attempts'] as List<dynamic>? ?? const []
            : const [];
    return items
        .whereType<Map<String, dynamic>>()
        .toList()
        .asMap()
        .entries
        .map((entry) => MockExamHistoryModel.fromJson(entry.value, entry.key))
        .toList();
  }
}
