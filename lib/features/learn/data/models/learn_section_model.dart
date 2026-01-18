import 'package:ustadia_user_app/assets/constants/images.dart';

enum LearnSectionProgressState { completed, inProgress, locked }

enum LearnSectionType {
  listening,
  reading,
  writing,
  speaking,
  grammar,
  flashcardSprint,
  vocabulary
}

class LearnSectionModel {
  final String id;
  final String unitId;
  final String title;
  final String content;
  final int orderIndex;
  final int totalQuestions;
  final String? audioFileId;
  final String? audioFile;
  final String iconAsset;

  final LearnSectionProgressState progressState;
  final LearnSectionType lessonType;

  const LearnSectionModel(
      {required this.id,
      required this.unitId,
      required this.title,
      required this.content,
      required this.orderIndex,
      required this.totalQuestions,
      required this.audioFileId,
      required this.audioFile,
      required this.iconAsset,
      required this.progressState,
      required this.lessonType});

  int get lessonNumber => orderIndex;

  String get subtitle => content;

  factory LearnSectionModel.fromJson(Map<String, dynamic> json) {
    final orderIndex = _toInt(json['order_index']);
    final totalQuestions = _toInt(json['totalQuestions']);
    final type = LearnSectionTypeX.fromApi(json['type']?.toString() ?? '');

    return LearnSectionModel(
        id: json['id']?.toString() ?? '',
        unitId: json['unit_id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        content: json['content']?.toString() ?? '',
        orderIndex: orderIndex,
        totalQuestions: totalQuestions,
        audioFileId: json['audio_file_id']?.toString(),
        audioFile: json['audio_file']?.toString(),
        iconAsset: type.iconAsset,
        progressState: json['isCompleted']
            ? LearnSectionProgressState.completed
            : LearnSectionProgressState.inProgress,
        lessonType: type);
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
      case 'flashcard':
      case 'flashcard-sprint':
      case 'flashcard_sprint':
        return LearnSectionType.flashcardSprint;

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
      case LearnSectionType.flashcardSprint:
        return AppImages.flashcardSprint;
      case LearnSectionType.vocabulary:
        return AppImages.vocabulary;
    }
  }
}
