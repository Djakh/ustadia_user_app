import 'package:equatable/equatable.dart';

import '../language/text_normalizer.dart';
import 'difficulty.dart';
import 'json_utils.dart';

/// Marker used inside [RuneTemplate.sentence] for the missing rune.
const runeBlank = '___';

/// A curated "Missing Rune" sentence. Distractors are curated by hand because
/// grammar distractors generated automatically are often accidentally valid.
class RuneTemplate extends Equatable {
  final String id;
  final String sentence;
  final String answer;
  final List<String> distractors;
  final int degree;
  final CefrLevel cefr;
  final String topic;
  final List<String> wordIds;

  const RuneTemplate({
    required this.id,
    required this.sentence,
    required this.answer,
    required this.distractors,
    required this.degree,
    required this.cefr,
    required this.topic,
    this.wordIds = const [],
  });

  factory RuneTemplate.fromJson(Map<String, dynamic> json) => RuneTemplate(
        id: JsonRead.string(json, 'id'),
        sentence: JsonRead.string(json, 'sentence'),
        answer: JsonRead.string(json, 'answer'),
        distractors: JsonRead.strings(json, 'distractors'),
        degree: JsonRead.integer(json, 'degree', fallback: 1),
        cefr: CefrLevel.parse(json['cefr']),
        topic: JsonRead.optString(json, 'topic') ?? 'general',
        wordIds: JsonRead.strings(json, 'wordIds'),
      );

  @override
  List<Object?> get props => [id];
}

/// A sentence the player assembles word by word ("Spell Construction").
/// [alternatives] lists other word orders that are also correct.
class IncantationEntry extends Equatable {
  final String id;
  final String text;
  final List<String> alternatives;
  final int degree;
  final CefrLevel cefr;
  final List<String> wordIds;

  const IncantationEntry({
    required this.id,
    required this.text,
    this.alternatives = const [],
    required this.degree,
    required this.cefr,
    this.wordIds = const [],
  });

  List<String> get tokens => TextNormalizer.tokenize(text);

  String get terminator => TextNormalizer.terminatorOf(text);

  /// All accepted answers as normalised, space-joined token sequences.
  List<String> get acceptedAnswers => [text, ...alternatives]
      .map((sentence) => TextNormalizer.tokenize(sentence).join(' '))
      .toSet()
      .toList();

  factory IncantationEntry.fromJson(Map<String, dynamic> json) => IncantationEntry(
        id: JsonRead.string(json, 'id'),
        text: JsonRead.string(json, 'text'),
        alternatives: JsonRead.strings(json, 'alternatives'),
        degree: JsonRead.integer(json, 'degree', fallback: 1),
        cefr: CefrLevel.parse(json['cefr']),
        wordIds: JsonRead.strings(json, 'wordIds'),
      );

  @override
  List<Object?> get props => [id];
}
