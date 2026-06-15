class SectionEvidencePosition {
  final int start;
  final int end;

  const SectionEvidencePosition({required this.start, required this.end});

  bool get isValid => start >= 0 && end > start;

  factory SectionEvidencePosition.fromJson(Map<String, dynamic> json) => SectionEvidencePosition(
      start: _toInt(json['start'] ?? json['start_position'] ?? json['startPosition']),
      end: _toInt(json['end'] ?? json['end_position'] ?? json['endPosition']));

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString()) ?? fallback;
  }
}

List<SectionEvidencePosition> sectionEvidencePositionsFromJson(dynamic value) {
  if (value is! List) return const [];
  return value
      .whereType<Map<String, dynamic>>()
      .map(SectionEvidencePosition.fromJson)
      .where((position) => position.isValid)
      .toList();
}

class SectionAnswerModel {
  final String id;
  final String questionId;
  final String answerText;
  final bool isCorrect;
  final bool userSelected;
  final int orderIndex;
  final String? transcript;
  final int? startPosition;
  final int? endPosition;
  final double? audioStartTime;
  final double? audioEndTime;
  final List<SectionEvidencePosition> positions;

  const SectionAnswerModel(
      {required this.id,
      required this.questionId,
      required this.answerText,
      required this.isCorrect,
      required this.userSelected,
      required this.orderIndex,
      required this.transcript,
      required this.startPosition,
      required this.endPosition,
      required this.audioStartTime,
      required this.audioEndTime,
      this.positions = const []});

  List<SectionEvidencePosition> get evidencePositions {
    if (positions.isNotEmpty) return positions;
    if (startPosition == null ||
        endPosition == null ||
        startPosition! < 0 ||
        endPosition! <= startPosition!) {
      return const [];
    }
    return [SectionEvidencePosition(start: startPosition!, end: endPosition!)];
  }

  bool get hasEvidenceRangeData => evidencePositions.isNotEmpty;

  bool get hasAudioEvidenceData =>
      audioStartTime != null &&
      audioEndTime != null &&
      audioStartTime! >= 0 &&
      audioEndTime! > audioStartTime!;

  bool get hasEvidenceRange => isCorrect && hasEvidenceRangeData;

  bool get hasAudioEvidence => isCorrect && hasAudioEvidenceData;

  bool get hasAnswerEvidence => hasEvidenceRange || hasAudioEvidence;

  bool get hasAnswerEvidenceData => hasEvidenceRangeData || hasAudioEvidenceData;

  factory SectionAnswerModel.fromJson(Map<String, dynamic> json, {String? selectedAnswerId}) =>
      SectionAnswerModel(
          id: json['id']?.toString() ?? '',
          questionId:
              json['question_id']?.toString() ?? json['assignment_question_id']?.toString() ?? '',
          answerText: json['answer_text']?.toString() ?? '',
          isCorrect: _extractIsCorrect(json),
          userSelected: _toBool(json['user_selected']) ||
              (selectedAnswerId != null && selectedAnswerId == json['id']?.toString()),
          orderIndex: _toInt(json['order_index']),
          transcript: json['transcript']?.toString(),
          startPosition: _toIntOrNull(json['start_position'] ?? json['startPosition']),
          endPosition: _toIntOrNull(json['end_position'] ?? json['endPosition']),
          audioStartTime: _toDoubleOrNull(json['audio_start_time'] ?? json['audioStartTime']),
          audioEndTime: _toDoubleOrNull(json['audio_end_time'] ?? json['audioEndTime']),
          positions: sectionEvidencePositionsFromJson(json['positions']));

  static int _toInt(dynamic value, {int fallback = 0}) {
    if (value == null) return fallback;
    if (value is int) return value;
    return int.tryParse(value.toString()) ?? fallback;
  }

  static int? _toIntOrNull(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    return int.tryParse(value.toString());
  }

  static double? _toDoubleOrNull(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
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

  static bool _extractIsCorrect(Map<String, dynamic> json) {
    const keys = [
      'is_correct',
      'isCorrect',
      'correct',
      'is_right',
      'isRight',
      'correct_answer',
      'correctAnswer',
      'is_answer_correct',
      'isAnswerCorrect',
    ];
    for (final key in keys) {
      if (!json.containsKey(key)) continue;
      if (_toBool(json[key])) return true;
    }
    return false;
  }
}
