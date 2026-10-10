import '../battle/combat_config.dart';
import '../language/challenge_type.dart';
import '../language/text_normalizer.dart';
import 'battle_definition.dart';
import 'enemy_definition.dart';
import 'region_definition.dart';
import 'sentence_content.dart';
import 'word_entry.dart';
import 'word_forge_content.dart';

/// Raw, already-parsed content before validation.
class RawWordForgeContent {
  final List<WordEntry> words;
  final List<RuneTemplate> runes;
  final List<IncantationEntry> incantations;
  final List<EnemyDefinition> enemies;
  final List<BattleDefinition> battles;
  final List<RegionDefinition> regions;
  final CombatConfig combat;
  final List<ContentIssue> parseIssues;

  const RawWordForgeContent({
    this.words = const [],
    this.runes = const [],
    this.incantations = const [],
    this.enemies = const [],
    this.battles = const [],
    this.regions = const [],
    this.combat = const CombatConfig(),
    this.parseIssues = const [],
  });
}

/// Validates content and drops anything that could produce an impossible or
/// misleading challenge. Never throws: production builds degrade gracefully,
/// debug builds surface [WordForgeContent.issues].
class ContentValidator {
  const ContentValidator();

  static const int minRuneOptions = 3;

  WordForgeContent validate(RawWordForgeContent raw) {
    final issues = <ContentIssue>[...raw.parseIssues];

    final words = _validateWords(raw.words, issues);
    final runes = _validateRunes(raw.runes, words, issues);
    final incantations = _validateIncantations(raw.incantations, issues);
    final enemies = {for (final enemy in _validateEnemies(raw.enemies, issues)) enemy.id: enemy};
    final battles = {
      for (final battle in _validateBattles(raw.battles, enemies, raw.combat, issues)) battle.id: battle,
    };
    final regions = _validateRegions(raw.regions, battles, raw.combat, issues);

    _checkMoves(raw.combat, enemies, issues);
    _checkCoverage(words, runes, incantations, battles, issues);

    return WordForgeContent(
      words: words,
      runes: runes,
      incantations: incantations,
      enemies: enemies,
      battles: battles,
      regions: regions,
      combat: raw.combat,
      issues: List.unmodifiable(issues),
    );
  }

  Map<String, WordEntry> _validateWords(List<WordEntry> input, List<ContentIssue> issues) {
    final result = <String, WordEntry>{};
    final texts = <String>{};
    for (final word in input) {
      final source = 'word:${word.id}';
      if (result.containsKey(word.id) || !texts.add(word.normalized)) {
        issues.add(ContentIssue.error(source, 'duplicate id or text'));
        continue;
      }
      final overlap = word.normalizedSynonyms.intersection(word.normalizedAntonyms);
      if (overlap.isNotEmpty) {
        issues.add(ContentIssue.error(source, 'both synonym and antonym: ${overlap.join(', ')}'));
        continue;
      }
      if (word.normalizedSynonyms.contains(word.normalized) ||
          word.normalizedAntonyms.contains(word.normalized)) {
        issues.add(ContentIssue.error(source, 'relates to itself'));
        continue;
      }
      if (word.degree < 1) {
        issues.add(ContentIssue.error(source, 'degree must be >= 1'));
        continue;
      }
      result[word.id] = word;
    }

    // Relationship sanity across entries.
    final byText = {for (final word in result.values) word.normalized: word};
    for (final word in result.values) {
      for (final antonym in word.normalizedAntonyms) {
        final other = byText[antonym];
        if (other != null && other.normalizedSynonyms.contains(word.normalized)) {
          issues.add(ContentIssue.warning(
              'word:${word.id}', '"$antonym" lists "${word.text}" as a synonym but is its antonym'));
        }
      }
    }
    return result;
  }

  List<RuneTemplate> _validateRunes(
      List<RuneTemplate> input, Map<String, WordEntry> words, List<ContentIssue> issues) {
    final result = <RuneTemplate>[];
    final ids = <String>{};
    for (final rune in input) {
      final source = 'rune:${rune.id}';
      final options = [rune.answer, ...rune.distractors].map(TextNormalizer.normalize).toList();
      if (!ids.add(rune.id)) {
        issues.add(ContentIssue.error(source, 'duplicate id'));
      } else if (!rune.sentence.contains(runeBlank)) {
        issues.add(ContentIssue.error(source, 'sentence has no "$runeBlank"'));
      } else if (options.toSet().length != options.length) {
        issues.add(ContentIssue.error(source, 'duplicate options'));
      } else if (options.length < minRuneOptions) {
        issues.add(ContentIssue.error(source, 'needs at least ${minRuneOptions - 1} distractors'));
      } else if (options.any((option) => option.isEmpty)) {
        issues.add(ContentIssue.error(source, 'empty option'));
      } else {
        for (final wordId in rune.wordIds) {
          if (!words.containsKey(wordId)) {
            issues.add(ContentIssue.warning(source, 'unknown word id "$wordId"'));
          }
        }
        result.add(rune);
      }
    }
    return result;
  }

  List<IncantationEntry> _validateIncantations(
      List<IncantationEntry> input, List<ContentIssue> issues) {
    final result = <IncantationEntry>[];
    final ids = <String>{};
    for (final entry in input) {
      final source = 'incantation:${entry.id}';
      final tokens = entry.tokens;
      final sortedTokens = [...tokens]..sort();
      final alternativesMatch = entry.alternatives.every((alternative) {
        final altTokens = TextNormalizer.tokenize(alternative)..sort();
        return altTokens.join(' ') == sortedTokens.join(' ');
      });
      if (!ids.add(entry.id)) {
        issues.add(ContentIssue.error(source, 'duplicate id'));
      } else if (tokens.length < 3 || tokens.length > 10) {
        issues.add(ContentIssue.error(source, 'sentence must have 3-10 words'));
      } else if (!alternativesMatch) {
        issues.add(ContentIssue.error(source, 'alternative uses different words'));
      } else if (tokens.toSet().length == 1) {
        issues.add(ContentIssue.error(source, 'cannot be shuffled'));
      } else {
        result.add(entry);
      }
    }
    return result;
  }

  List<EnemyDefinition> _validateEnemies(List<EnemyDefinition> input, List<ContentIssue> issues) {
    final result = <EnemyDefinition>[];
    final ids = <String>{};
    for (final enemy in input) {
      final source = 'enemy:${enemy.id}';
      if (!ids.add(enemy.id)) {
        issues.add(ContentIssue.error(source, 'duplicate id'));
      } else if (enemy.maxHp <= 0 || enemy.attack < 0) {
        issues.add(ContentIssue.error(source, 'invalid hp/attack'));
      } else {
        result.add(enemy);
      }
    }
    return result;
  }

  List<BattleDefinition> _validateBattles(List<BattleDefinition> input,
      Map<String, EnemyDefinition> enemies, CombatConfig combat, List<ContentIssue> issues) {
    final result = <BattleDefinition>[];
    final ids = <String>{};
    for (final battle in input) {
      final source = 'battle:${battle.id}';
      if (!ids.add(battle.id)) {
        issues.add(ContentIssue.error(source, 'duplicate id'));
        continue;
      }
      final unknown = battle.enemies.where((slot) => !enemies.containsKey(slot.enemyId)).toList();
      if (unknown.isNotEmpty) {
        issues.add(ContentIssue.error(source, 'unknown enemy "${unknown.first.enemyId}"'));
        continue;
      }
      var valid = true;
      for (var index = 0; index < battle.stages.length; index++) {
        final stage = battle.stages[index];
        final isLast = index == battle.stages.length - 1;
        final threshold = stage.untilHpFraction;
        if (!isLast && threshold == null) {
          issues.add(ContentIssue.error(source, 'stage $index needs "untilHp" (not last stage)'));
          valid = false;
        }
        if (threshold != null && (threshold <= 0 || threshold >= 1)) {
          issues.add(ContentIssue.error(source, 'stage $index "untilHp" must be between 0 and 1'));
          valid = false;
        }
        if (stage.opensWith != null && combat.move(stage.opensWith!) == null) {
          issues.add(ContentIssue.warning(source, 'stage $index opens with unknown move "${stage.opensWith}"'));
        }
      }
      if (valid) result.add(battle);
    }
    return result;
  }

  void _checkMoves(CombatConfig combat, Map<String, EnemyDefinition> enemies, List<ContentIssue> issues) {
    for (final enemy in enemies.values) {
      final behaviour = combat.behaviourFor(enemy.archetype.name).merge(enemy.behaviour);
      for (final id in [...behaviour.specials, if (behaviour.signature != null) behaviour.signature!]) {
        if (combat.move(id) == null) issues.add(ContentIssue.warning('enemy:${enemy.id}', 'unknown move "$id"'));
      }
    }
    for (final id in [...combat.playerCriticals, ...combat.allSpecials]) {
      if (combat.move(id) == null) issues.add(ContentIssue.error('combat', 'unknown player move "$id"'));
    }
  }

  List<RegionDefinition> _validateRegions(List<RegionDefinition> input,
      Map<String, BattleDefinition> battles, CombatConfig combat, List<ContentIssue> issues) {
    final result = <RegionDefinition>[];
    final regionIds = <String>{};
    final nodeIds = <String>{};
    for (final region in input) {
      final source = 'region:${region.id}';
      if (!regionIds.add(region.id)) {
        issues.add(ContentIssue.error(source, 'duplicate id'));
        continue;
      }
      var valid = true;
      for (final node in region.nodes) {
        if (!nodeIds.add(node.id)) {
          issues.add(ContentIssue.error(source, 'duplicate node id "${node.id}"'));
          valid = false;
        }
        for (final target in node.next) {
          if (region.node(target) == null) {
            issues.add(ContentIssue.error(source, 'node ${node.id} links to unknown "$target"'));
            valid = false;
          }
        }
        final taught = node.teaches;
        if (taught != null && combat.move(taught)?.kind != MoveKind.special) {
          issues.add(ContentIssue.warning(source, 'node ${node.id} teaches unknown spell "$taught"'));
        }
        final needsBattle = node.type.isCombat;
        if (needsBattle && (node.battleId == null || !battles.containsKey(node.battleId))) {
          issues.add(ContentIssue.error(source, 'node ${node.id} has no valid battle'));
          valid = false;
        }
        if (node.type == MapNodeType.mystery) {
          for (final outcome in node.outcomes) {
            if (outcome.kind == MysteryOutcomeKind.battle &&
                !battles.containsKey(outcome.battleId)) {
              issues.add(ContentIssue.error(source, 'mystery ${node.id} has unknown battle'));
              valid = false;
            }
          }
          if (node.outcomes.isEmpty) {
            issues.add(ContentIssue.error(source, 'mystery ${node.id} has no outcomes'));
            valid = false;
          }
        }
      }
      if (region.node(region.startNodeId) == null || region.node(region.bossNodeId) == null) {
        issues.add(ContentIssue.error(source, 'start or boss node missing'));
        valid = false;
      }
      if (valid && !_bossReachable(region)) {
        issues.add(ContentIssue.error(source, 'boss is not reachable from start'));
        valid = false;
      }
      if (valid) result.add(region);
    }
    return result;
  }

  bool _bossReachable(RegionDefinition region) {
    final visited = <String>{};
    final queue = [region.startNodeId];
    while (queue.isNotEmpty) {
      final id = queue.removeLast();
      if (!visited.add(id)) continue;
      if (id == region.bossNodeId) return true;
      queue.addAll(region.node(id)?.next ?? const []);
    }
    return false;
  }

  void _checkCoverage(
      Map<String, WordEntry> words,
      List<RuneTemplate> runes,
      List<IncantationEntry> incantations,
      Map<String, BattleDefinition> battles,
      List<ContentIssue> issues) {
    for (final battle in battles.values) {
      // Every battle uses relationship words; Criticals and Specials also
      // draw sentences, so check all mechanics.
      const types = ChallengeType.values;
      bool covered(ChallengeType type) => switch (type) {
            ChallengeType.antonym =>
              words.values.where((w) => w.canBeCountered && battle.degrees.contains(w.degree)).length >= 4,
            ChallengeType.synonym =>
              words.values.where((w) => w.canResonate && battle.degrees.contains(w.degree)).length >= 4,
            ChallengeType.missingRune =>
              runes.where((rune) => battle.degrees.contains(rune.degree)).length >= 2,
            ChallengeType.incantation =>
              incantations.where((entry) => battle.degrees.contains(entry.degree)).length >= 2,
            ChallengeType.wordMatch =>
              words.values.where((w) => w.canBeCountered && battle.degrees.contains(w.degree)).length >= 6,
          };
      for (final type in types) {
        if (!covered(type)) {
          issues.add(ContentIssue.warning(
              'battle:${battle.id}', 'little ${type.name} content in ${battle.degrees}'));
        }
      }
    }
  }
}
