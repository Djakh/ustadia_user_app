import 'dart:convert';

import 'word_forge_save.dart';

typedef SaveMigration = Map<String, dynamic> Function(Map<String, dynamic> json);

/// Encodes/decodes saves and upgrades old save formats step by step.
///
/// To change the format: bump [WordForgeSave.currentVersion] and add a
/// migration from the previous version to [migrations].
class SaveCodec {
  final Map<int, SaveMigration> migrations;

  const SaveCodec({this.migrations = defaultMigrations});

  /// Version 0 = saves written before versioning existed (none shipped yet;
  /// kept as the template for future migrations).
  static const Map<int, SaveMigration> defaultMigrations = {0: _v0ToV1, 1: _v1ToV2, 2: _v2ToV3, 3: _v3ToV4};

  static Map<String, dynamic> _v0ToV1(Map<String, dynamic> json) => {...json, 'version': 1};

  /// v2 adds save slots, characters and tutorial flags. Introduced
  /// mechanics map onto the new tutorial keys; wins are estimated from
  /// completed nodes so unlocked mechanics stay unlocked.
  static Map<String, dynamic> _v1ToV2(Map<String, dynamic> json) {
    final introduced = json['introduced'];
    final tutorials = <String>{
      if (introduced is List && introduced.contains('antonym')) 'defence',
      if (introduced is List && introduced.contains('synonym')) 'attack',
    };
    final nodes = json['nodes'];
    final wins = nodes is Map
        ? nodes.values.where((node) => node is Map && node['w'] is num && (node['w'] as num) > 0).length
        : 0;
    return {
      ...json,
      'version': 2,
      'slot': json['slot'] ?? 1,
      'tutorials': [...tutorials],
      'battleWins': json['battleWins'] ?? wins,
    };
  }

  /// v3 adds learned Special spells. Saves that already beat a teaching node
  /// receive its spell retroactively when the node is next looked at
  /// (see `SandboxProgression.spellsFor`), so nothing is lost.
  static Map<String, dynamic> _v2ToV3(Map<String, dynamic> json) => {
        ...json,
        'version': 3,
        'spells': json['spells'] ?? const <String>[],
      };

  /// v4: spells cost a skill point. Spells granted for free by v3 are
  /// dropped; the teaching nodes stay cleared, so the same spells are still
  /// witnessed and can be learned with the points the save has.
  static Map<String, dynamic> _v3ToV4(Map<String, dynamic> json) => {
        ...json,
        'version': 4,
        'spells': const <String>[],
      };

  String encode(WordForgeSave save) => jsonEncode(save.toJson());

  /// Returns null when [raw] is not a readable save.
  WordForgeSave? decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return null;
      var json = Map<String, dynamic>.from(decoded);
      var version = (json['version'] as num?)?.toInt() ?? 0;
      while (version < WordForgeSave.currentVersion) {
        final migration = migrations[version];
        if (migration == null) return null;
        json = migration(json);
        version++;
      }
      // Saves from a newer app version are read best-effort: unknown fields
      // are ignored, known ones keep their meaning.
      return WordForgeSave.fromJson(json);
    } on FormatException {
      return null;
    } on TypeError {
      return null;
    }
  }
}
