import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/common/data/models/section_model/section_question_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_audio_file_model.dart';

enum SectionProgressState { completed, inProgress, locked }

enum SectionType { listening, reading, writing, speaking, grammar, vocabulary }

enum SectionSource { learn, assignment }

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
    this.source = SectionSource.learn,
  });

  int get lessonNumber => orderIndex;

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
        source: source);
  }

  factory SectionModel.fromJson(Map<String, dynamic> json) {
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
    final lessonId = json['lesson_id']?.toString() ?? json['lessonId']?.toString();
    final source = assignmentId != null ? SectionSource.assignment : SectionSource.learn;
    final questions = (questionsJson as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map((item) => SectionQuestionModel.fromJson(item,
                source: source,
                assignmentId: assignmentId,
                unitId: json['unit_id']?.toString(),
                lessonId: lessonId))
            .toList() ??
        [];
    questions.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    SectionProgressState progressState = json['isLocked'] == true
        ? SectionProgressState.locked
        : json['isCompleted'] == true
            ? SectionProgressState.completed
            : SectionProgressState.inProgress;

    return SectionModel(
        id: json['id']?.toString() ?? '',
        unitId: json['unit_id']?.toString() ?? '',
        lessonId: lessonId,
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        orderIndex: orderIndex,
        totalQuestions: totalQuestions,
        answeredQuestions: answeredQuestions,
        assignmentId: assignmentId,
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
        isLocked: json['isLocked'] == true,
        timeLimit: json['time_limit'],
        source: source);
  }

  static int toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}

extension SectionTypeX on SectionType {
  static SectionType fromApi(String value) {
    switch (value.toLowerCase()) {
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
