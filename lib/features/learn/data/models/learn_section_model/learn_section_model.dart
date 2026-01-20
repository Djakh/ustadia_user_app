import 'package:ustadia_user_app/assets/constants/images.dart';
import 'package:ustadia_user_app/features/common/data/models/flash_card_model/flash_card_set_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_audio_file_model.dart';
import 'package:ustadia_user_app/features/learn/data/models/learn_section_model/learn_section_question_model.dart';

enum LearnSectionProgressState { completed, inProgress, locked }

enum LearnSectionType {
  listening,
  reading,
  writing,
  speaking,
  grammar,
  vocabulary
}

class LearnSectionModel {
  final String id;
  final String unitId;
  final String title;
  final String content;
  final int orderIndex;
  final int totalQuestions;
  final int? answeredQuestions;
  final String? audioFileId;
  final LearnAudioFileModel? audioFile;
  final String? flashCardSetId;
  final LearnFlashcardSetModel? flashCardSet;
  final bool? unitIsPublished;
  final bool? lessonIsPublic;
  final List<LearnSectionQuestionModel> questions;
  final String iconAsset;
  final bool isLocked;
  final LearnSectionProgressState progressState;
  final LearnSectionType sectionType;

  const LearnSectionModel(
      {required this.id,
      required this.unitId,
      required this.title,
      required this.content,
      required this.orderIndex,
      required this.totalQuestions,
      required this.answeredQuestions,
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
      required this.isLocked});

  int get lessonNumber => orderIndex;

  factory LearnSectionModel.fromJson(Map<String, dynamic> json) {
    final orderIndex = _toInt(json['order_index']);
    final totalQuestions = _toInt(json['totalQuestions']);
    final answeredQuestions =
        json['answeredQuestions'] == null ? null : _toInt(json['answeredQuestions']);
    final type = LearnSectionTypeX.fromApi(json['type']?.toString() ?? '');
    final questions = (json['questions'] as List<dynamic>?)
            ?.whereType<Map<String, dynamic>>()
            .map(LearnSectionQuestionModel.fromJson)
            .toList() ??
        [];
    questions.sort((a, b) => a.orderIndex.compareTo(b.orderIndex));
    LearnSectionProgressState progressState = json['isLocked'] == true
        ? LearnSectionProgressState.locked
        : json['isCompleted'] == true
            ? LearnSectionProgressState.completed
            : LearnSectionProgressState.inProgress;

    return LearnSectionModel(
        id: json['id']?.toString() ?? '',
        unitId: json['unit_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        orderIndex: orderIndex,
        totalQuestions: totalQuestions,
        answeredQuestions: answeredQuestions,
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
        isLocked: json['isLocked'] == true);
  }

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }
}

extension LearnSectionTypeX on LearnSectionType {
  static LearnSectionType fromApi(String value) {
    switch (value.toLowerCase()) {
      case 'listening':
        return LearnSectionType.listening;
      case 'reading':
        return LearnSectionType.reading;
      case 'writing':
        return LearnSectionType.writing;
      case 'speaking':
        return LearnSectionType.speaking;
      case 'grammar':
        return LearnSectionType.grammar;

      case 'vocabulary':
        return LearnSectionType.vocabulary;
      default:
        return LearnSectionType.reading;
    }
  }

  String get iconAsset {
    switch (this) {
      case LearnSectionType.listening:
        return AppImages.learnHeadphones;
      case LearnSectionType.reading:
        return AppImages.learnNotebook;
      case LearnSectionType.writing:
        return AppImages.learnPen;
      case LearnSectionType.speaking:
        return AppImages.learnMicrophone;
      case LearnSectionType.grammar:
        return AppImages.learnGrammar;

      case LearnSectionType.vocabulary:
        return AppImages.vocabulary;
    }
  }
}
