import 'package:ustadia_user_app/features/common/data/models/section_model/section_model.dart';

class MockExamAttemptModel {
  final String attemptId;
  final String mockExamId;
  final String status;
  final bool isFinished;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final int? timeLimitMinutes;
  final int? timeRemainingSeconds;
  final String currentComponent;
  final String currentSubSectionId;
  final List<MockExamComponentModel> components;

  const MockExamAttemptModel(
      {required this.attemptId,
      required this.mockExamId,
      required this.status,
      required this.isFinished,
      required this.startedAt,
      required this.finishedAt,
      required this.timeLimitMinutes,
      required this.timeRemainingSeconds,
      required this.currentComponent,
      required this.currentSubSectionId,
      required this.components});

  factory MockExamAttemptModel.fromJson(Map<String, dynamic> json, {String? mockExamId}) {
    final attemptData =
        json['attempt'] is Map<String, dynamic> ? json['attempt'] as Map<String, dynamic> : json;
    final resolvedAttemptId =
        attemptData['attempt_id']?.toString() ?? attemptData['id']?.toString() ?? '';
    final resolvedMockExamId = attemptData['mock_exam_id']?.toString() ??
        mockExamId ??
        json['mock_exam_id']?.toString() ??
        '';
    final componentsJson = json['components'] ?? attemptData['components'];
    final components = (componentsJson as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map((item) => MockExamComponentModel.fromJson(item,
                mockExamId: resolvedMockExamId, attemptId: resolvedAttemptId))
            .toList() ??
        const [];
    components.sort((first, second) => first.orderIndex.compareTo(second.orderIndex));
    return MockExamAttemptModel(
        attemptId: resolvedAttemptId,
        mockExamId: resolvedMockExamId,
        status: attemptData['status']?.toString() ?? '',
        isFinished: mockExamBool(attemptData['is_finished']),
        startedAt: DateTime.tryParse(attemptData['started_at']?.toString() ?? ''),
        finishedAt: DateTime.tryParse(attemptData['finished_at']?.toString() ?? ''),
        timeLimitMinutes:
            mockExamIntOrNull(json['time_limit_minutes'] ?? attemptData['time_limit_minutes']),
        timeRemainingSeconds: mockExamIntOrNull(
            json['time_remaining_seconds'] ?? attemptData['time_remaining_seconds']),
        currentComponent: attemptData['current_component']?.toString() ?? '',
        currentSubSectionId: attemptData['current_sub_section_id']?.toString() ?? '',
        components: components);
  }
}

class MockExamComponentModel {
  final String id;
  final String type;
  final String title;
  final int orderIndex;
  final String status;
  final bool isAvailable;
  final bool isCompleted;
  final int? timeLimitSeconds;
  final int? timeRemainingSeconds;
  final num? bandScore;
  final List<SectionModel> subSections;
  final SectionModel directSection;

  const MockExamComponentModel(
      {required this.id,
      required this.type,
      required this.title,
      required this.orderIndex,
      required this.status,
      required this.isAvailable,
      required this.isCompleted,
      required this.timeLimitSeconds,
      required this.timeRemainingSeconds,
      required this.bandScore,
      required this.subSections,
      required this.directSection});

  bool get isLocked => status == 'locked' || !isAvailable;

  bool get canOpen => !isLocked;

  String get label => SectionModel.formatTypeLabel(type);

  String get statusLabel => SectionModel.formatTypeLabel(status);

  factory MockExamComponentModel.fromJson(Map<String, dynamic> json,
      {required String mockExamId, required String attemptId}) {
    final type = json['type']?.toString() ?? '';
    final status = json['status']?.toString() ?? '';
    final subSections = (json['sub_sections'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map((item) => SectionModel.fromJson(item,
                source: SectionSource.mockExam, mockId: mockExamId, mockAttemptId: attemptId))
            .toList() ??
        const [];
    subSections.sort((first, second) => first.orderIndex.compareTo(second.orderIndex));
    final directSection = SectionModel.fromJson(json,
        source: SectionSource.mockExam, mockId: mockExamId, mockAttemptId: attemptId);
    return MockExamComponentModel(
        id: json['id']?.toString() ?? '',
        type: type,
        title: json['title']?.toString() ?? SectionModel.formatTypeLabel(type),
        orderIndex: mockExamInt(json['order_index']),
        status: status,
        isAvailable: mockExamBool(json['is_available'], fallback: status != 'locked'),
        isCompleted: mockExamBool(json['is_completed']) || status == 'completed',
        timeLimitSeconds: mockExamIntOrNull(json['time_limit_seconds']),
        timeRemainingSeconds: mockExamIntOrNull(json['time_remaining_seconds']),
        bandScore: mockExamNumOrNull(json['band_score']),
        subSections: subSections,
        directSection: directSection);
  }
}

class MockExamResultModel {
  final String attemptId;
  final String mockExamId;
  final String status;
  final String gradingStatus;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final num? overallBand;
  final num? listeningBand;
  final num? readingBand;
  final num? writingBand;
  final num? speakingBand;
  final String feedback;
  final List<MockExamResultComponentModel> components;

  const MockExamResultModel(
      {required this.attemptId,
      required this.mockExamId,
      required this.status,
      required this.gradingStatus,
      required this.startedAt,
      required this.finishedAt,
      required this.overallBand,
      required this.listeningBand,
      required this.readingBand,
      required this.writingBand,
      required this.speakingBand,
      required this.feedback,
      required this.components});

  factory MockExamResultModel.fromJson(Map<String, dynamic> json) {
    final scores = json['component_scores'] is Map<String, dynamic>
        ? json['component_scores'] as Map<String, dynamic>
        : const <String, dynamic>{};
    final components = (json['components'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(MockExamResultComponentModel.fromJson)
            .toList() ??
        const [];
    return MockExamResultModel(
        attemptId: json['attempt_id']?.toString() ?? '',
        mockExamId: json['mock_exam_id']?.toString() ?? '',
        status: json['status']?.toString() ?? '',
        gradingStatus: json['grading_status']?.toString() ?? '',
        startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
        finishedAt: DateTime.tryParse(json['finished_at']?.toString() ?? ''),
        overallBand: mockExamNumOrNull(json['overall_band'] ?? json['total_band_score']),
        listeningBand:
            mockExamBand(scores['listening']) ?? mockExamNumOrNull(json['listening_band']),
        readingBand: mockExamBand(scores['reading']) ?? mockExamNumOrNull(json['reading_band']),
        writingBand: mockExamBand(scores['writing']) ?? mockExamNumOrNull(json['writing_band']),
        speakingBand: mockExamBand(scores['speaking']) ?? mockExamNumOrNull(json['speaking_band']),
        feedback: json['feedback']?.toString() ?? '',
        components: components);
  }
}

class MockExamResultComponentModel {
  final String type;
  final num? bandScore;
  final int totalQuestions;

  const MockExamResultComponentModel(
      {required this.type, required this.bandScore, required this.totalQuestions});

  factory MockExamResultComponentModel.fromJson(Map<String, dynamic> json) =>
      MockExamResultComponentModel(
          type: json['type']?.toString() ?? '',
          bandScore: mockExamNumOrNull(json['band_score']),
          totalQuestions: mockExamInt(json['total_questions']));

  String get title => SectionModel.formatTypeLabel(type);
}

class MockExamHistoryModel {
  final String attemptId;
  final String mockExamId;
  final String mockExamTitle;
  final String mockExamDescription;
  final int? timeLimitMinutes;
  final int attemptNumber;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final bool isFinished;
  final num? overallBand;
  final num? listeningBand;
  final num? readingBand;
  final num? writingBand;
  final num? speakingBand;

  const MockExamHistoryModel(
      {required this.attemptId,
      required this.mockExamId,
      required this.mockExamTitle,
      required this.mockExamDescription,
      required this.timeLimitMinutes,
      required this.attemptNumber,
      required this.startedAt,
      required this.finishedAt,
      required this.isFinished,
      required this.overallBand,
      required this.listeningBand,
      required this.readingBand,
      required this.writingBand,
      required this.speakingBand});

  factory MockExamHistoryModel.fromJson(Map<String, dynamic> json, int index) {
    final mockExam = json['mock_exam'] is Map<String, dynamic>
        ? json['mock_exam'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return MockExamHistoryModel(
        attemptId: json['attempt_id']?.toString() ?? '',
        mockExamId: mockExam['id']?.toString() ?? json['mock_exam_id']?.toString() ?? '',
        mockExamTitle: mockExam['title']?.toString() ?? '',
        mockExamDescription: mockExam['description']?.toString() ?? '',
        timeLimitMinutes: mockExamIntOrNull(mockExam['time_limit_minutes']),
        attemptNumber: mockExamInt(json['attempt_number'], fallback: index + 1),
        startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
        finishedAt: DateTime.tryParse(json['finished_at']?.toString() ?? ''),
        isFinished: mockExamBool(json['is_finished']),
        overallBand: mockExamNumOrNull(json['overall_band'] ?? json['total_band_score']),
        listeningBand: mockExamNumOrNull(json['listening_band']),
        readingBand: mockExamNumOrNull(json['reading_band']),
        writingBand: mockExamNumOrNull(json['writing_band']),
        speakingBand: mockExamNumOrNull(json['speaking_band']));
  }
}

int mockExamInt(dynamic value, {int fallback = 0}) => mockExamIntOrNull(value) ?? fallback;

int? mockExamIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

num? mockExamNumOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

num? mockExamBand(dynamic value) {
  if (value is Map<String, dynamic>) return mockExamNumOrNull(value['band_score']);
  return mockExamNumOrNull(value);
}

bool mockExamBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}
