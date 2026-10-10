import 'dart:convert';

import '../domain/battle/combat_config.dart';
import '../domain/content/battle_definition.dart';
import '../domain/content/content_validator.dart';
import '../domain/content/enemy_definition.dart';
import '../domain/content/region_definition.dart';
import '../domain/content/sentence_content.dart';
import '../domain/content/word_entry.dart';
import '../domain/content/word_forge_content.dart';

/// Raw JSON documents, one per content file.
class ContentDocuments {
  final String words;
  final String runes;
  final String incantations;
  final String enemies;
  final String battles;
  final String regions;

  /// combat.json: balance, pacing, archetype behaviour and moves.
  final String combat;

  const ContentDocuments({
    required this.words,
    required this.runes,
    required this.incantations,
    required this.enemies,
    required this.battles,
    required this.regions,
    this.combat = '{}',
  });
}

/// Parses content JSON. A malformed entry is reported and skipped; it never
/// takes the rest of the file down with it.
class ContentParser {
  final ContentValidator validator;

  const ContentParser({this.validator = const ContentValidator()});

  WordForgeContent parse(ContentDocuments documents) {
    final issues = <ContentIssue>[];
    List<T> read<T>(String file, String document, String listKey,
        T Function(Map<String, dynamic> json) parse) {
      final Object? decoded;
      try {
        decoded = jsonDecode(document);
      } on FormatException catch (error) {
        issues.add(ContentIssue.error(file, 'invalid JSON: ${error.message}'));
        return const [];
      }
      final list = decoded is Map ? decoded[listKey] : null;
      if (list is! List) {
        issues.add(ContentIssue.error(file, 'missing "$listKey" list'));
        return const [];
      }
      final result = <T>[];
      for (var index = 0; index < list.length; index++) {
        final item = list[index];
        try {
          if (item is! Map) throw const FormatException('not an object');
          result.add(parse(Map<String, dynamic>.from(item)));
        } on Object catch (error) {
          final id = item is Map ? item['id'] : null;
          issues.add(ContentIssue.error('$file[${id ?? index}]', '$error'));
        }
      }
      return result;
    }

    var combat = const CombatConfig();
    try {
      final decoded = jsonDecode(documents.combat);
      if (decoded is Map) combat = CombatConfig.fromJson(Map<String, dynamic>.from(decoded));
    } on Object catch (error) {
      issues.add(ContentIssue.error('combat', 'using default balance: $error'));
    }

    final raw = RawWordForgeContent(
      words: read('words', documents.words, 'words', WordEntry.fromJson),
      runes: read('runes', documents.runes, 'runes', RuneTemplate.fromJson),
      incantations:
          read('incantations', documents.incantations, 'incantations', IncantationEntry.fromJson),
      enemies: read('enemies', documents.enemies, 'enemies', EnemyDefinition.fromJson),
      battles: read('battles', documents.battles, 'battles', BattleDefinition.fromJson),
      regions: read('regions', documents.regions, 'regions', RegionDefinition.fromJson),
      combat: combat,
      parseIssues: issues,
    );
    return validator.validate(raw);
  }
}
