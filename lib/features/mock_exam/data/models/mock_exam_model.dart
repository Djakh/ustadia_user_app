class MockExamAssignModel {
  final String assignId;
  final DateTime? startedAt;
  final bool isFinished;
  final DateTime? finishedAt;
  final int? timeLimitMinutes;
  final int? timeRemainingSeconds;
  final num? overallBand;
  final num? listeningBand;
  final num? readingBand;
  final num? writingBand;
  final num? speakingBand;

  const MockExamAssignModel(
      {required this.assignId,
      required this.startedAt,
      required this.isFinished,
      required this.finishedAt,
      required this.timeLimitMinutes,
      required this.timeRemainingSeconds,
      required this.overallBand,
      required this.listeningBand,
      required this.readingBand,
      required this.writingBand,
      required this.speakingBand});

  factory MockExamAssignModel.fromJson(Map<String, dynamic> json) => MockExamAssignModel(
      assignId: json['assign_id']?.toString() ?? '',
      startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
      isFinished: mockExamModelBool(json['is_finished']),
      finishedAt: DateTime.tryParse(json['finished_at']?.toString() ?? ''),
      timeLimitMinutes: mockExamModelIntOrNull(json['time_limit_minutes']),
      timeRemainingSeconds: mockExamModelIntOrNull(json['time_remaining_seconds']),
      overallBand: mockExamModelNumOrNull(json['overall_band']),
      listeningBand: mockExamModelNumOrNull(json['listening_band']),
      readingBand: mockExamModelNumOrNull(json['reading_band']),
      writingBand: mockExamModelNumOrNull(json['writing_band']),
      speakingBand: mockExamModelNumOrNull(json['speaking_band']));
}

class MockExamAssignmentClassModel {
  final String id;
  final String name;
  final String description;

  const MockExamAssignmentClassModel(
      {required this.id, required this.name, required this.description});

  factory MockExamAssignmentClassModel.fromJson(Map<String, dynamic> json) =>
      MockExamAssignmentClassModel(
          id: json['id']?.toString() ?? '',
          name: json['name']?.toString() ?? '',
          description: json['description']?.toString() ?? '');
}

class MockExamAssignmentModel {
  final String id;
  final String classId;
  final DateTime? startTime;
  final DateTime? endTime;
  final bool isActive;
  final String status;
  final bool finished;
  final MockExamAssignmentAttemptModel? attempt;
  final MockExamAssignmentClassModel? classModel;

  const MockExamAssignmentModel(
      {required this.id,
      required this.classId,
      required this.startTime,
      required this.endTime,
      required this.isActive,
      required this.status,
      required this.finished,
      required this.attempt,
      required this.classModel});

  factory MockExamAssignmentModel.fromJson(Map<String, dynamic> json) => MockExamAssignmentModel(
      id: json['id']?.toString() ?? '',
      classId: json['class_id']?.toString() ?? '',
      startTime: DateTime.tryParse(json['start_time']?.toString() ?? ''),
      endTime: DateTime.tryParse(json['end_time']?.toString() ?? ''),
      isActive: mockExamModelBool(json['is_active'], fallback: true),
      status: json['status']?.toString() ?? '',
      finished: mockExamModelBool(json['finished']),
      attempt: json['attempt'] is Map<String, dynamic>
          ? MockExamAssignmentAttemptModel.fromJson(json['attempt'] as Map<String, dynamic>)
          : null,
      classModel: json['class'] is Map<String, dynamic>
          ? MockExamAssignmentClassModel.fromJson(json['class'] as Map<String, dynamic>)
          : null);
}

class MockExamAssignmentAttemptModel {
  final String id;
  final String status;
  final bool isStarted;
  final bool isFinished;
  final DateTime? startedAt;
  final DateTime? finishedAt;
  final String currentComponentId;
  final String currentSubSectionId;

  const MockExamAssignmentAttemptModel(
      {required this.id,
      required this.status,
      required this.isStarted,
      required this.isFinished,
      required this.startedAt,
      required this.finishedAt,
      required this.currentComponentId,
      required this.currentSubSectionId});

  factory MockExamAssignmentAttemptModel.fromJson(Map<String, dynamic> json) =>
      MockExamAssignmentAttemptModel(
          id: json['id']?.toString() ?? json['attempt_id']?.toString() ?? '',
          status: json['status']?.toString() ?? '',
          isStarted: mockExamModelBool(json['is_started']),
          isFinished: mockExamModelBool(json['is_finished']),
          startedAt: DateTime.tryParse(json['started_at']?.toString() ?? ''),
          finishedAt: DateTime.tryParse(json['finished_at']?.toString() ?? ''),
          currentComponentId: json['current_component_id']?.toString() ?? '',
          currentSubSectionId: json['current_sub_section_id']?.toString() ?? '');
}

class MockExamModel {
  final String id;
  final String title;
  final String description;
  final String status;
  final String teacherId;
  final int? timeLimit;
  final int? timeRemainingSeconds;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final MockExamAssignModel? assign;
  final MockExamAssignmentModel? assignment;
  final List<MockExamAssignmentModel> assignments;
  final DateTime? deadlineAt;

  const MockExamModel(
      {required this.id,
      required this.title,
      required this.description,
      required this.status,
      required this.teacherId,
      required this.timeLimit,
      required this.timeRemainingSeconds,
      required this.createdAt,
      required this.updatedAt,
      required this.assign,
      required this.assignment,
      required this.assignments,
      required this.deadlineAt});

  factory MockExamModel.fromJson(Map<String, dynamic> json) {
    final timeLimit = mockExamModelIntOrNull(json['time_limit'] ?? json['time_limit_minutes']);
    final timeRemainingSeconds = mockExamModelIntOrNull(json['time_remaining_seconds']);
    final assign = json['assign'] is Map<String, dynamic>
        ? MockExamAssignModel.fromJson(json['assign'] as Map<String, dynamic>)
        : null;
    final assignment = json['assignment'] is Map<String, dynamic>
        ? MockExamAssignmentModel.fromJson(json['assignment'] as Map<String, dynamic>)
        : null;
    final isFinished = assignment?.finished == true ||
        assignment?.attempt?.isFinished == true ||
        assign?.isFinished == true;
    final hasStarted = assignment?.attempt != null || assign?.startedAt != null;
    return MockExamModel(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
        status:
            json['status']?.toString() ?? (mockExamModelBool(json['is_active']) ? 'active' : ''),
        teacherId: json['teacher_id']?.toString() ?? '',
        timeLimit: timeLimit,
        timeRemainingSeconds: timeRemainingSeconds ?? assign?.timeRemainingSeconds,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
        updatedAt: DateTime.tryParse(json['updated_at']?.toString() ?? ''),
        assign: assign,
        assignment: assignment,
        assignments: (json['assignments'] as List<dynamic>?)
                ?.whereType<Map<String, dynamic>>()
                .map(MockExamAssignmentModel.fromJson)
                .toList() ??
            const [],
        deadlineAt: !isFinished && hasStarted
            ? deadlineFromRemainingTime(
                timeRemainingSeconds: timeRemainingSeconds ?? assign?.timeRemainingSeconds)
            : null);
  }

  bool get isFinished =>
      assignment?.finished == true ||
      assignment?.attempt?.isFinished == true ||
      assign?.isFinished == true;

  String get resultAttemptId => assignment?.attempt?.id ?? '';

  bool get isStarted => assignment?.attempt != null || assign?.startedAt != null;

  bool get hasDeadline => deadlineAt != null && !isFinished;

  Duration get remainingDuration {
    final deadline = deadlineAt;
    if (deadline == null) return Duration.zero;
    final remaining = deadline.difference(DateTime.now());
    return remaining.isNegative ? Duration.zero : remaining;
  }

  bool get isExpired => hasDeadline && remainingDuration == Duration.zero;
}

int? mockExamModelIntOrNull(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

num? mockExamModelNumOrNull(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

bool mockExamModelBool(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  final normalized = value.toString().trim().toLowerCase();
  if (normalized == 'true' || normalized == '1') return true;
  if (normalized == 'false' || normalized == '0') return false;
  return fallback;
}

DateTime? deadlineFromRemainingTime({int? timeRemainingSeconds}) {
  if (timeRemainingSeconds != null) {
    return DateTime.now().add(Duration(seconds: timeRemainingSeconds));
  }
  return null;
}
