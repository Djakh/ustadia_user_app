import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_question_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_audio_file_model.dart';

enum SectionProgressState { completed, inProgress, locked }

enum SectionType { listening, reading, writing, speaking, grammar, vocabulary }

enum SectionSource { learn, assignment, mockExam }

class SectionModel {
  final String id;
  final String unitId;
  final String? lessonId;
  final String title;
  final String content;
  final int orderIndex;
  final int totalQuestions;
  final int? answeredQuestions;
  final String? assignmentId;
  final String? mockId;
  final String? mockAttemptId;
  final String? audioFileId;
  final LearnAudioFileModel? audioFile;
  final String? flashCardSetId;
  final LearnFlashcardSetModel? flashCardSet;
  final bool? unitIsPublished;
  final bool? lessonIsPublic;
  final List<SectionQuestionModel> questions;
  final String iconAsset;
  final bool isLocked;
  final SectionProgressState progressState;
  final SectionType sectionType;
  final String? sectionStringType;
  final num? timeLimit;
  final int? timeRemainingSeconds;
  final DateTime? deadlineAt;
  final String status;
  final bool isAvailable;
  final SectionSource source;

  const SectionModel({
    required this.id,
    required this.unitId,
    required this.lessonId,
    required this.title,
    required this.content,
    required this.orderIndex,
    required this.totalQuestions,
    required this.answeredQuestions,
    required this.assignmentId,
    this.mockId,
    this.mockAttemptId,
    required this.audioFileId,
    required this.audioFile,
    required this.flashCardSetId,
    required this.flashCardSet,
    required this.unitIsPublished,
    required this.lessonIsPublic,
    required this.questions,
    required this.iconAsset,
    required this.progressState,
    required this.sectionType,
    required this.sectionStringType,
    required this.isLocked,
    this.timeLimit,
    this.timeRemainingSeconds,
    this.deadlineAt,
    this.status = '',
    this.isAvailable = true,
    this.source = SectionSource.learn,
  });

  int get lessonNumber => orderIndex;

  String get sectionTypeLabel {
    final value = sectionStringType?.trim();
    if (value == null || value.isEmpty) return formatTypeLabel(sectionType.name);
    return formatTypeLabel(value);
  }

  SectionModel copyWith({String? unitId, String? lessonId, List<SectionQuestionModel>? questions}) {
    return SectionModel(
        id: id,
        unitId: unitId ?? this.unitId,
        lessonId: lessonId ?? this.lessonId,
        title: title,
        content: content,
        orderIndex: orderIndex,
        totalQuestions: totalQuestions,
        answeredQuestions: answeredQuestions,
        assignmentId: assignmentId,
        mockId: mockId,
        mockAttemptId: mockAttemptId,
        audioFileId: audioFileId,
        audioFile: audioFile,
        flashCardSetId: flashCardSetId,
        flashCardSet: flashCardSet,
        unitIsPublished: unitIsPublished,
        lessonIsPublic: lessonIsPublic,
        questions: questions ?? this.questions,
        iconAsset: iconAsset,
        progressState: progressState,
        sectionType: sectionType,
        sectionStringType: sectionStringType,
        isLocked: isLocked,
        timeLimit: timeLimit,
        timeRemainingSeconds: timeRemainingSeconds,
        deadlineAt: deadlineAt,
        status: status,
        isAvailable: isAvailable,
        source: source);
  }

  factory SectionModel.fromJson(Map<String, dynamic> json,
      {SectionSource? source, String? mockId, String? mockAttemptId}) {
    final resolvedSectionId = json['id']?.toString() ??
        json['section_id']?.toString() ??
        json['sectionId']?.toString() ??
        json['sub_section_id']?.toString() ??
        json['subSectionId']?.toString() ??
        '';
    final orderIndex = toInt(json['order_index']);
    final questionsJson = json['questions'];
    final totalQuestions = toInt(json['totalQuestions'] ??
        json['taskCount'] ??
        (questionsJson is List ? questionsJson.length : null));
    final answeredQuestionsValue =
        json['answeredQuestions'] ?? json['CompletedTaskCount'] ?? json['completedTaskCount'];
    final answeredQuestions = answeredQuestionsValue == null ? null : toInt(answeredQuestionsValue);
    final type = SectionTypeX.fromApi(json['type']?.toString() ?? '');
    final assignmentId = json['assignment_id']?.toString();
    final resolvedMockId = mockId ?? json['mock_id']?.toString();
    final resolvedMockAttemptId =
        mockAttemptId ?? json['attempt_id']?.toString() ?? json['mock_attempt_id']?.toString();
    final lessonId = json['lesson_id']?.toString() ?? json['lessonId']?.toString();
    final resolvedSource = source ??
        (assignmentId != null
            ? SectionSource.assignment
            : resolvedMockId != null
                ? SectionSource.mockExam
                : SectionSource.learn);
    final questions = (questionsJson as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map((item) => SectionQuestionModel.fromJson(item,
                source: resolvedSource,
                assignmentId: assignmentId,
                mockExamId: resolvedMockId,
                mockAttemptId: resolvedMockAttemptId,
                sectionId: resolvedSectionId,
                unitId: json['unit_id']?.toString(),
                lessonId: lessonId))
            .toList() ??
        [];
    questions.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    final status = json['status']?.toString() ?? '';
    final isAvailable = _toBool(json['is_available'], fallback: status != 'locked');
    SectionProgressState progressState = _toBool(json['isLocked']) || status == 'locked'
        ? SectionProgressState.locked
        : _toBool(json['isCompleted'] ?? json['is_completed']) || status == 'completed'
            ? SectionProgressState.completed
            : SectionProgressState.inProgress;

    return SectionModel(
        id: resolvedSectionId,
        unitId: json['unit_id']?.toString() ?? '',
        lessonId: lessonId,
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        orderIndex: orderIndex,
        totalQuestions: totalQuestions,
        answeredQuestions: answeredQuestions,
        assignmentId: assignmentId,
        mockId: resolvedMockId,
        mockAttemptId: resolvedMockAttemptId,
        audioFileId: json['audio_file_id']?.toString(),
        audioFile: LearnAudioFileModel.fromDynamic(json['audio_file']),
        flashCardSetId: json['flashcard_set_id']?.toString(),
        flashCardSet: json['flashcard_set'] is Map<String, dynamic>
            ? LearnFlashcardSetModel.fromJson(json['flashcard_set'] as Map<String, dynamic>)
            : null,
        unitIsPublished: json['unit_ispublished'] == null ? null : json['unit_ispublished'] == true,
        lessonIsPublic: json['lesson_isPublic'] == null ? null : json['lesson_isPublic'] == true,
        questions: questions,
        iconAsset: type.iconAsset,
        progressState: progressState,
        sectionType: type,
        sectionStringType: json['type'],
        isLocked: _toBool(json['isLocked']) || status == 'locked' || !isAvailable,
        timeLimit: json['time_limit'] ?? json['time_limit_seconds'],
        timeRemainingSeconds: toIntOrNull(json['time_remaining_seconds']),
        deadlineAt: DateTime.tryParse(json['deadline_at']?.toString() ?? ''),
        status: status,
        isAvailable: isAvailable,
        source: resolvedSource);
  }

  static int toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }

  static int? toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool _toBool(dynamic value, {bool fallback = false}) {
    if (value == null) return fallback;
    if (value is bool) return value;
    if (value is num) return value != 0;
    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;
    return fallback;
  }

  static String formatTypeLabel(String value) {
    final normalized = value.trim().toLowerCase();
    switch (normalized) {
      case 'writing_task1':
      case 'writing_task_1':
        return 'Writing Task 1';
      case 'writing_task2':
      case 'writing_task_2':
        return 'Writing Task 2';
      case 'speaking_part1':
      case 'speaking_part_1':
        return 'Speaking Part 1';
      case 'speaking_part2':
      case 'speaking_part_2':
        return 'Speaking Part 2';
      case 'speaking_part3':
      case 'speaking_part_3':
        return 'Speaking Part 3';
    }
    return normalized
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(capitalizeTypePart)
        .join(' ');
  }

  static String capitalizeTypePart(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }
}

extension SectionTypeX on SectionType {
  static SectionType fromApi(String value) {
    final normalized = value.trim().toLowerCase();
    if (normalized.startsWith('writing')) return SectionType.writing;
    if (normalized.startsWith('speaking')) return SectionType.speaking;
    switch (normalized) {
      case 'listening':
        return SectionType.listening;
      case 'reading':
        return SectionType.reading;
      case 'writing':
        return SectionType.writing;
      case 'speaking':
        return SectionType.speaking;
      case 'grammar':
        return SectionType.grammar;

      case 'vocabulary':
        return SectionType.vocabulary;
      default:
        return SectionType.reading;
    }
  }

  String get iconAsset {
    switch (this) {
      case SectionType.listening:
        return AppImages.learnHeadphones;
      case SectionType.reading:
        return AppImages.learnNotebook;
      case SectionType.writing:
        return AppImages.learnPen;
      case SectionType.speaking:
        return AppImages.learnMicrophone;
      case SectionType.grammar:
        return AppImages.learnGrammar;

      case SectionType.vocabulary:
        return AppImages.vocabulary;
    }
  }
}
