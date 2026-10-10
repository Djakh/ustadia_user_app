import 'package:equatable/equatable.dart';

import '../language/text_normalizer.dart';
import 'difficulty.dart';
import 'json_utils.dart';

/// A vocabulary entry. Relationships ([synonyms], [antonyms]) are stored as
/// plain English text so they may point to words that are not entries yet.
///
/// [cluster] groups words that share a core meaning (e.g. "joy": happy, glad,
/// cheerful). It is used to keep distractors from accidentally being valid
/// answers. [domain] is a broader topic (e.g. "emotion").
class WordEntry extends Equatable {
  final String id;
  final String text;
  final String normalized;
  final String partOfSpeech;
  final int degree;
  final CefrLevel cefr;
  final String cluster;
  final String domain;
  final String definition;
  final List<String> synonyms;
  final List<String> antonyms;
  final List<String> examples;
  final List<String> tags;

  /// Words that look or sound similar (e.g. lose / loose). Used by Mimics.
  final List<String> confusables;

  WordEntry({
    required this.id,
    required this.text,
    required this.partOfSpeech,
    required this.degree,
    required this.cefr,
    required this.cluster,
    required this.domain,
    required this.definition,
    this.synonyms = const [],
    this.antonyms = const [],
    this.examples = const [],
    this.tags = const [],
    this.confusables = const [],
  }) : normalized = TextNormalizer.normalize(text);

  late final Set<String> normalizedSynonyms = synonyms.map(TextNormalizer.normalize).toSet();
  late final Set<String> normalizedAntonyms = antonyms.map(TextNormalizer.normalize).toSet();

  bool get canBeCountered => antonyms.isNotEmpty;
  bool get canResonate => synonyms.isNotEmpty;

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        id: JsonRead.string(json, 'id'),
        text: JsonRead.string(json, 'text'),
        partOfSpeech: JsonRead.optString(json, 'pos') ?? 'word',
        degree: JsonRead.integer(json, 'degree', fallback: 1),
        cefr: CefrLevel.parse(json['cefr']),
        cluster: JsonRead.optString(json, 'cluster') ?? JsonRead.string(json, 'id'),
        domain: JsonRead.optString(json, 'domain') ?? 'general',
        definition: JsonRead.string(json, 'definition'),
        synonyms: JsonRead.strings(json, 'synonyms'),
        antonyms: JsonRead.strings(json, 'antonyms'),
        examples: JsonRead.strings(json, 'examples'),
        tags: JsonRead.strings(json, 'tags'),
        confusables: JsonRead.strings(json, 'confusables'),
      );

  @override
  List<Object?> get props => [id];
}
