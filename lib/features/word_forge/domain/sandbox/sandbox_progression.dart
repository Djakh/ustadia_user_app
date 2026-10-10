import '../battle/battle_assist.dart';
import '../battle/battle_models.dart';
import '../battle/combat_config.dart';
import '../content/enemy_definition.dart';
import '../content/region_definition.dart';
import '../content/word_forge_content.dart';
import '../language/word_selector.dart';
import '../progression/buffs.dart';
import '../progression/map_rules.dart';
import '../progression/player_level.dart';
import '../progression/reward_calculator.dart';
import '../progression/star_rating.dart';
import '../progression/upgrades.dart';
import '../progression/word_mastery.dart';
import '../save/word_forge_save.dart';

class MasteryChange {
  final String wordId;
  final int from;
  final int to;

  const MasteryChange({required this.wordId, required this.from, required this.to});
}

/// Everything the results screen needs to celebrate a finished battle.
class BattleOutcomeSummary {
  final String nodeId;
  final BattleResult result;
  final int stars;
  final int previousBestStars;
  final bool firstClear;
  final int xpGained;
  final PlayerLevel levelBefore;
  final PlayerLevel levelAfter;
  final Map<BuffType, int> buffsGained;
  final List<String> discoveredWordIds;
  final List<MasteryChange> masteryChanges;

  /// Words answered wrong this battle; they will come back later.
  final List<String> reviewWordIds;
  final List<String> unlockedNodeIds;
  final String? unlockedRegionId;

  /// Attack turns allowed for the efficiency star, and the turns used.
  final int turnBudget;
  final int attackTurns;

  /// Special spell witnessed by this victory (move id): it can now be
  /// learned on the Skills page for a skill point.
  final String? witnessedSpellId;

  const BattleOutcomeSummary({
    required this.nodeId,
    required this.result,
    required this.stars,
    required this.previousBestStars,
    required this.firstClear,
    required this.xpGained,
    required this.levelBefore,
    required this.levelAfter,
    required this.buffsGained,
    required this.discoveredWordIds,
    required this.masteryChanges,
    required this.reviewWordIds,
    required this.unlockedNodeIds,
    this.unlockedRegionId,
    required this.turnBudget,
    required this.attackTurns,
    this.witnessedSpellId,
  });

  bool get victory => result.victory;
  bool get leveledUp => levelAfter.level > levelBefore.level;
  bool get newBestStars => stars > previousBestStars;
}

class NodeClaimSummary {
  final String nodeId;
  final Map<BuffType, int> buffsGained;
  final bool alreadyClaimed;
  final List<String> unlockedNodeIds;

  const NodeClaimSummary({
    required this.nodeId,
    required this.buffsGained,
    required this.alreadyClaimed,
    required this.unlockedNodeIds,
  });
}

/// Word stats view over a save, used by adaptive selection.
class SaveStatsLookup implements WordStatsLookup {
  final WordForgeSave save;

  const SaveStatsLookup(this.save);

  @override
  WordStats? statsFor(String wordId) => save.words[wordId];

  @override
  int get battleIndex => save.battleCount + 1;

  @override
  Set<String> get recentContentKeys => save.recentContentKeys.toSet();
}

/// Sandbox rules: turns map nodes into battles and battle results into
/// progress. Pure functions over immutable saves, so every rule is testable.
class SandboxProgression {
  final RewardCalculator rewards;
  final StarRating starRating;
  final MasteryCalculator mastery;
  final AssistPolicy assistPolicy;
  final MapRules mapRules;

  const SandboxProgression({
    this.rewards = const RewardCalculator(),
    this.starRating = const StarRating(),
    this.mastery = const MasteryCalculator(),
    this.assistPolicy = const AssistPolicy(),
    this.mapRules = const MapRules(),
  });

  static const int hintsPerLevelUp = 1;

  /// One point per level; passives and spells draw from the same pool.
  int availableSkillPoints(WordForgeSave save) =>
      (PlayerLevel.fromXp(save.xp).level - 1 - save.upgrades.spentPoints - save.spells.length).clamp(0, 999);

  /// Spells available to [save]: the starter plus every spell learned with
  /// a skill point, in the spellbook's order.
  List<String> spellsFor(WordForgeContent content, WordForgeSave save) {
    final combat = content.combat;
    return [
      for (final id in combat.allSpecials)
        if (id == combat.playerSpecial || save.spells.contains(id))
          if (combat.move(id) != null) id,
    ];
  }

  /// Spells the player has seen an enemy use (cleared its teaching node);
  /// only these can be learned.
  Set<String> witnessedSpells(WordForgeContent content, WordForgeSave save) => {
        for (final region in content.regions)
          for (final node in region.nodes)
            if (node.teaches != null && save.isCompleted(node.id)) node.teaches!,
      };

  /// Node that teaches [spellId], for "defeat X to witness this spell".
  MapNodeDefinition? teacherOf(WordForgeContent content, String spellId) {
    for (final region in content.regions) {
      for (final node in region.nodes) {
        if (node.teaches == spellId) return node;
      }
    }
    return null;
  }

  /// Spends one skill point on a witnessed spell. Null when not allowed.
  WordForgeSave? learnSpell(WordForgeContent content, WordForgeSave save, String spellId) {
    final combat = content.combat;
    if (spellId == combat.playerSpecial || save.spells.contains(spellId)) return null;
    if (combat.move(spellId)?.kind != MoveKind.special) return null;
    if (!witnessedSpells(content, save).contains(spellId)) return null;
    if (availableSkillPoints(save) <= 0) return null;
    return save.copyWith(spells: [...save.spells, spellId]);
  }

  int turnBudgetFor(WordForgeContent content, BattleSetup setup) => starRating.turnBudget(
        battle: setup.battle,
        enemies: setup.enemies,
        enemyHp: setup.enemyHp,
        config: setup.config,
      );

  bool _wardGranted(WordForgeSave save) {
    final interval = save.upgrades.protectionInterval;
    return interval != null && save.battlesSinceWard + 1 >= interval;
  }

  /// Resolves which battle a node starts, or null for non-combat nodes.
  String? battleIdFor(WordForgeSave save, MapNodeDefinition node) {
    if (node.type != MapNodeType.mystery) return node.battleId;
    final outcome = mysteryOutcomeFor(save, node);
    return outcome.kind == MysteryOutcomeKind.battle ? outcome.battleId : null;
  }

  BattleSetup? buildSetup({
    required WordForgeContent content,
    required WordForgeSave save,
    required MapNodeDefinition node,
  }) {
    final battleId = battleIdFor(save, node);
    final battle = battleId == null ? null : content.battles[battleId];
    if (battle == null) return null;
    final enemies = [for (final slot in battle.enemies) content.enemies[slot.enemyId]];
    if (enemies.any((enemy) => enemy == null)) return null;
    return BattleSetup(
      battle: battle,
      enemies: enemies.whereType<EnemyDefinition>().toList(),
      degrees: battle.degrees,
      config: content.combat,
      access: content.combat.gates.forWins(save.battleWins),
      assist: assistPolicy.forFailures(save.progressOf(node.id).failureStreak),
      upgrades: save.upgrades,
      inventory: save.buffs,
      startWithWard: _wardGranted(save),
      playerLevel: PlayerLevel.fromXp(save.xp).level,
      knownTutorials: save.tutorialFlags,
      spells: spellsFor(content, save),
    );
  }

  /// Deterministic per player, so reopening the app never re-rolls it.
  MysteryOutcome mysteryOutcomeFor(WordForgeSave save, MapNodeDefinition node) {
    final stored = save.progressOf(node.id).mysteryOutcome;
    if (stored != null && stored >= 0 && stored < node.outcomes.length) return node.outcomes[stored];
    return node.outcomes[stableHash('${save.playerId}:${node.id}') % node.outcomes.length];
  }

  WordForgeSave revealMystery(WordForgeSave save, MapNodeDefinition node) {
    final outcome = mysteryOutcomeFor(save, node);
    final index = node.outcomes.indexOf(outcome);
    return save.copyWith(nodes: {
      ...save.nodes,
      node.id: save.progressOf(node.id).copyWith(mysteryOutcome: index),
    });
  }

  ({WordForgeSave save, BattleOutcomeSummary summary}) applyBattle({
    required WordForgeContent content,
    required WordForgeSave save,
    required MapNodeDefinition node,
    required BattleResult result,
  }) {
    final region = content.regionOfNode(node.id);
    final battleId = battleIdFor(save, node);
    final battle = battleId == null ? null : content.battles[battleId];
    final before = save.progressOf(node.id);
    final turnBudget = battle == null
        ? 0
        : starRating.turnBudget(
            battle: battle,
            enemies: [for (final slot in battle.enemies) content.enemies[slot.enemyId]].whereType<EnemyDefinition>().toList(),
            enemyHp: [for (final slot in battle.enemies) slot.hp ?? content.enemies[slot.enemyId]?.maxHp ?? 0],
            config: content.combat,
          );
    final stars = starRating.starsFor(result, turnBudget: turnBudget);
    final firstClear = result.victory && !before.completed;
    final taught = node.teaches;
    final witnessedSpellId = firstClear && taught != null && content.combat.move(taught) != null && !save.spells.contains(taught)
        ? taught
        : null;

    final grant = battle == null
        ? const BattleRewardGrant(xp: 0)
        : rewards.forBattle(
            battle: battle,
            nodeType: node.type,
            result: result,
            stars: stars,
            firstClear: firstClear,
            previousBestStars: before.bestStars,
          );

    // --- words ---
    final battleIndex = save.battleCount + 1;
    final words = Map<String, WordStats>.of(save.words);
    final levelsBefore = <String, int>{};
    final discovered = <String>[];
    final review = <String>{};
    for (final record in result.records) {
      for (final wordId in record.wordIds) {
        if (!content.words.containsKey(wordId)) continue;
        final current = words[wordId];
        levelsBefore.putIfAbsent(wordId, () => mastery.level(current));
        if (current == null || current.seen == 0) {
          if (!discovered.contains(wordId)) discovered.add(wordId);
        }
        words[wordId] = (current ?? const WordStats()).record(
          isCorrect: record.firstTry,
          type: record.type,
          battleIndex: battleIndex,
          responseMs: record.timedOut ? null : (record.responseSeconds * 1000).round(),
        );
        if (!record.firstTry) review.add(wordId);
      }
    }
    final masteryChanges = [
      for (final entry in levelsBefore.entries)
        if (mastery.level(words[entry.key]) != entry.value)
          MasteryChange(wordId: entry.key, from: entry.value, to: mastery.level(words[entry.key])),
    ];

    // --- xp, level, buffs ---
    final levelBefore = PlayerLevel.fromXp(save.xp);
    final xp = save.xp + grant.xp;
    final levelAfter = PlayerLevel.fromXp(xp);
    var gained = grant.buffs;
    final levelsGained = levelAfter.level - levelBefore.level;
    if (levelsGained > 0) gained = addBuffs(gained, {BuffType.hint: levelsGained * hintsPerLevelUp});
    final buffs = addBuffs(addBuffs(save.buffs, result.buffsConsumed, sign: -1), gained);

    // --- node & map ---
    final progress = before.copyWith(
      completed: before.completed || result.victory,
      bestStars: stars > before.bestStars ? stars : before.bestStars,
      bestScore: result.victory && result.score > before.bestScore ? result.score : before.bestScore,
      attempts: before.attempts + 1,
      wins: before.wins + (result.victory ? 1 : 0),
      failureStreak: result.victory ? 0 : (result.abandoned ? before.failureStreak : before.failureStreak + 1),
    );
    final unlocked = <String>[];
    var unlockedNodeIds = save.unlockedNodeIds;
    String? unlockedRegionId;
    String? currentRegionId = save.currentRegionId ?? region?.id;
    if (result.victory && region != null) {
      for (final id in mapRules.unlockedBy(region, node.id)) {
        if (!save.isCompleted(id) && !save.unlockedNodeIds.contains(id)) unlocked.add(id);
      }
      unlockedNodeIds = {...save.unlockedNodeIds, ...unlocked};
      if (firstClear && node.id == region.bossNodeId) {
        final index = content.regions.indexOf(region);
        if (index >= 0 && index + 1 < content.regions.length) {
          final next = content.regions[index + 1];
          unlockedRegionId = next.id;
          currentRegionId = next.id;
          unlockedNodeIds = {...unlockedNodeIds, next.startNodeId};
        }
      }
    }

    final recent = <String>{
      ...result.records.map((record) => record.contentKey).where((key) => key.isNotEmpty),
      ...save.recentContentKeys,
    }.take(WordForgeSave.recentContentLimit).toList();

    final counted = !result.abandoned || result.records.isNotEmpty;
    final nextSave = save.copyWith(
      xp: xp,
      buffs: buffs,
      currentRegionId: currentRegionId,
      lastNodeId: node.id,
      nodes: {...save.nodes, node.id: progress},
      unlockedNodeIds: unlockedNodeIds,
      words: words,
      battleCount: counted ? battleIndex : save.battleCount,
      battleWins: save.battleWins + (result.victory ? 1 : 0),
      battlesSinceWard: result.abandoned
          ? save.battlesSinceWard
          : (_wardGranted(save) ? 0 : save.battlesSinceWard + 1),
      tutorialFlags: {...save.tutorialFlags, ...result.tutorialsSeen},
      recentContentKeys: recent,
    );

    return (
      save: nextSave,
      summary: BattleOutcomeSummary(
        nodeId: node.id,
        result: result,
        stars: stars,
        previousBestStars: before.bestStars,
        firstClear: firstClear,
        xpGained: grant.xp,
        levelBefore: levelBefore,
        levelAfter: levelAfter,
        buffsGained: gained,
        discoveredWordIds: discovered,
        masteryChanges: masteryChanges,
        reviewWordIds: review.toList(),
        unlockedNodeIds: unlocked,
        unlockedRegionId: unlockedRegionId,
        turnBudget: turnBudget,
        attackTurns: result.attackTurns,
        witnessedSpellId: witnessedSpellId,
      ),
    );
  }

  /// Bonus, recovery and mystery-treasure nodes. Rewards are paid once.
  ({WordForgeSave save, NodeClaimSummary summary}) claimNode({
    required WordForgeContent content,
    required WordForgeSave save,
    required MapNodeDefinition node,
  }) {
    final region = content.regionOfNode(node.id);
    if (save.isCompleted(node.id)) {
      return (
        save: save,
        summary: NodeClaimSummary(
            nodeId: node.id, buffsGained: const {}, alreadyClaimed: true, unlockedNodeIds: const []),
      );
    }
    final rewards = node.type == MapNodeType.mystery ? mysteryOutcomeFor(save, node).buffs : node.rewards;
    final unlocked = [
      if (region != null)
        for (final id in mapRules.unlockedBy(region, node.id))
          if (!save.isCompleted(id) && !save.unlockedNodeIds.contains(id)) id,
    ];
    final revealed = node.type == MapNodeType.mystery ? revealMystery(save, node) : save;
    final nextSave = revealed.copyWith(
      buffs: addBuffs(save.buffs, rewards),
      lastNodeId: node.id,
      nodes: {
        ...revealed.nodes,
        node.id: revealed.progressOf(node.id).copyWith(completed: true, wins: 1, attempts: 1),
      },
      unlockedNodeIds: {...save.unlockedNodeIds, ...unlocked},
    );
    return (
      save: nextSave,
      summary: NodeClaimSummary(
          nodeId: node.id, buffsGained: rewards, alreadyClaimed: false, unlockedNodeIds: unlocked),
    );
  }

  WordForgeSave? purchaseUpgrade(WordForgeSave save, UpgradeType type) {
    if (availableSkillPoints(save) <= 0 || save.upgrades[type] >= type.maxLevel) return null;
    return save.copyWith(upgrades: save.upgrades.increment(type));
  }

  WordForgeSave markTutorials(WordForgeSave save, Iterable<String> keys) =>
      save.copyWith(tutorialFlags: {...save.tutorialFlags, ...keys});
}

/// FNV-1a, stable across platforms and Dart versions (unlike String.hashCode).
int stableHash(String input) {
  var hash = 0x811c9dc5;
  for (final unit in input.codeUnits) {
    hash ^= unit;
    hash = (hash * 0x01000193) & 0xFFFFFFFF;
  }
  return hash;
}
