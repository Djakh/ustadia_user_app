import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/battle_assist.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/battle_models.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/combat_config.dart';
import 'package:ustadia_user_app/features/word_forge/domain/content/region_definition.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/challenge_type.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/buffs.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/map_rules.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/player_level.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/reward_calculator.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/star_rating.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/upgrades.dart';
import 'package:ustadia_user_app/features/word_forge/domain/sandbox/sandbox_progression.dart';
import 'package:ustadia_user_app/features/word_forge/domain/save/word_forge_save.dart';

import 'helpers.dart';

ChallengeRecord _record({bool firstTry = true, double seconds = 3, List<String> words = const ['hot', 'cold']}) =>
    ChallengeRecord(
      type: ChallengeType.antonym,
      turn: BattleTurn.enemy,
      wordIds: words,
      focusWordId: words.first,
      success: true,
      firstTry: firstTry,
      attempts: firstTry ? 1 : 2,
      responseSeconds: seconds,
      targetSeconds: 6,
    );

BattleResult _result({
  bool victory = true,
  int correct = 10,
  int wrong = 0,
  double seconds = 3,
  bool abandoned = false,
  Map<BuffType, int> consumed = const {},
  int maxCombo = 3,
  Set<String> tutorials = const {},
  int attackTurns = 4,
}) =>
    BattleResult(
      victory: victory,
      abandoned: abandoned,
      attackTurns: attackTurns,
      records: [
        for (var i = 0; i < correct; i++) _record(seconds: seconds),
        for (var i = 0; i < wrong; i++) _record(firstTry: false, words: const ['big', 'small']),
      ],
      maxCombo: maxCombo,
      score: 1000,
      playerHpFraction: 0.8,
      buffsConsumed: consumed,
      durationSeconds: 60,
      tutorialsSeen: tutorials,
    );

void main() {
  final content = loadShippedContent();
  const progression = SandboxProgression();
  const rules = MapRules();
  final road = content.regions.first;
  final forest = content.regions[1];

  group('StarRating', () {
    const rating = StarRating();

    test('one star for winning, one for accuracy, one for efficiency', () {
      expect(rating.starsFor(_result(victory: false), turnBudget: 6), 0);
      expect(rating.starsFor(_result(correct: 5, wrong: 5, attackTurns: 9), turnBudget: 6), 1);
      expect(rating.starsFor(_result(correct: 8, wrong: 2, attackTurns: 9), turnBudget: 6), 2, reason: 'accurate but slow');
      expect(rating.starsFor(_result(correct: 5, wrong: 5, attackTurns: 5), turnBudget: 6), 2, reason: 'quick but inaccurate');
      expect(rating.starsFor(_result(correct: 8, wrong: 2, attackTurns: 6), turnBudget: 6), 3);
    });

    test('the turn budget follows the enemy: durable, shielded and multi-phase enemies allow more turns', () {
      int budget(String id) {
        final battle = content.battles[id]!;
        return rating.turnBudget(
          battle: battle,
          enemies: [for (final slot in battle.enemies) content.enemies[slot.enemyId]!],
          enemyHp: [for (final slot in battle.enemies) slot.hp ?? content.enemies[slot.enemyId]!.maxHp],
          config: content.combat,
        );
      }

      expect(budget('r1_n1'), inInclusiveRange(3, 5), reason: 'goblin scout');
      expect(budget('r1_n3'), greaterThan(budget('r1_n1')), reason: 'stone sentinel has stone skin and shields');
      expect(budget('r1_boss'), greaterThan(budget('r1_mb')), reason: 'four phases');
      expect(budget('r1_n8'), greaterThan(budget('r1_n2')), reason: 'two enemies');
    });
  });

  group('PlayerLevel', () {
    test('derives level from total XP with a gentle curve', () {
      expect(PlayerLevel.fromXp(0).level, 1);
      expect(PlayerLevel.fromXp(79).level, 1);
      expect(PlayerLevel.fromXp(80).level, 2);
      expect(PlayerLevel.fromXp(80 + 120).level, 3);
      expect(PlayerLevel.fromXp(100).xpIntoLevel, 20);
      expect(PlayerLevel.fromXp(100).xpForNextLevel, 120);
    });
  });

  group('RewardCalculator', () {
    const rewards = RewardCalculator();
    final battle = content.battles['r1_mb']!;

    test('first clear pays full XP and buffs, replays pay less and no buffs', () {
      final first = rewards.forBattle(
          battle: battle, nodeType: MapNodeType.miniBoss, result: _result(), stars: 2, firstClear: true, previousBestStars: 0);
      final replay = rewards.forBattle(
          battle: battle, nodeType: MapNodeType.miniBoss, result: _result(), stars: 2, firstClear: false, previousBestStars: 2);
      expect(first.xp, (battle.rewards.xp * 1.25).round());
      expect(first.buffs, battle.rewards.buffs);
      expect(replay.xp, lessThan(first.xp ~/ 2));
      expect(replay.buffs, isEmpty);
    });

    test('three stars for the first time grants a bonus buff', () {
      final grant = rewards.forBattle(
          battle: battle, nodeType: MapNodeType.miniBoss, result: _result(), stars: 3, firstClear: false, previousBestStars: 2);
      expect(grant.buffs[BuffType.timeFreeze], 1);
    });

    test('a defeat still pays a little XP', () {
      final grant = rewards.forBattle(
          battle: battle, nodeType: MapNodeType.battle, result: _result(victory: false), stars: 0, firstClear: false, previousBestStars: 0);
      expect(grant.xp, greaterThan(0));
    });
  });

  group('MapRules', () {
    test('only the start node is available on a fresh save', () {
      final save = WordForgeSave.fresh('p');
      expect(rules.nodeState(content, save, road, road.node('r1_n1')!), NodeState.available);
      expect(rules.nodeState(content, save, road, road.node('r1_n2')!), NodeState.locked);
      expect(rules.isRegionUnlocked(content, save, forest), isFalse);
      expect(rules.nodeState(content, save, forest, forest.node(forest.startNodeId)!), NodeState.locked);
    });

    test('completing a node unlocks every branch it leads to', () {
      final save = WordForgeSave.fresh('p').copyWith(nodes: {
        for (final id in ['r1_n1', 'r1_n2', 'r1_n3']) id: const NodeProgress(completed: true, bestStars: 1),
      });
      expect(rules.nodeState(content, save, road, road.node('r1_n4')!), NodeState.available);
      expect(rules.nodeState(content, save, road, road.node('r1_x1')!), NodeState.available);
      expect(rules.nodeState(content, save, road, road.node('r1_n5')!), NodeState.locked);
    });

    test('a merge node opens from either branch', () {
      final viaRest = WordForgeSave.fresh('p').copyWith(nodes: {'r1_r1': const NodeProgress(completed: true)});
      expect(rules.nodeState(content, viaRest, road, road.node('r1_n9')!), NodeState.available);
    });

    test('beating the boss opens the next region', () {
      final save = WordForgeSave.fresh('p').copyWith(nodes: {road.bossNodeId: const NodeProgress(completed: true)});
      expect(rules.isRegionUnlocked(content, save, forest), isTrue);
      expect(rules.currentRegion(content, save).id, forest.id);
    });

    test('focus prefers the main path over optional nodes', () {
      final save = WordForgeSave.fresh('p').copyWith(nodes: {
        for (final id in ['r1_n1', 'r1_n2', 'r1_n3']) id: const NodeProgress(completed: true),
      });
      expect(rules.focusNode(content, save, road).id, 'r1_n4');
    });
  });

  group('SandboxProgression', () {
    test('a won battle saves stars, XP, words and unlocks the next node', () {
      final save = WordForgeSave.fresh('p');
      final node = road.node('r1_n1')!;
      final applied = progression.applyBattle(
          content: content, save: save, node: node, result: _result(correct: 6, wrong: 1, attackTurns: 9, tutorials: {'attack', 'defence'}));
      final next = applied.save;
      expect(next.isCompleted('r1_n1'), isTrue);
      expect(next.progressOf('r1_n1').bestStars, 2, reason: 'accurate but took too many turns');
      expect(applied.summary.turnBudget, lessThan(9));
      expect(next.xp, applied.summary.xpGained);
      expect(next.unlockedNodeIds, contains('r1_n2'));
      expect(next.words['hot']!.correct, 6);
      expect(next.words['big']!.wrong, 1);
      expect(next.battleCount, 1);
      expect(next.tutorialFlags, containsAll(['attack', 'defence']));
      expect(next.battleWins, 1);
      expect(applied.summary.firstClear, isTrue);
      expect(applied.summary.discoveredWordIds, containsAll(['hot', 'cold', 'big', 'small']));
      expect(applied.summary.reviewWordIds, containsAll(['big', 'small']));
      expect(rules.nodeState(content, next, road, road.node('r1_n2')!), NodeState.available);
    });

    test('losing never removes progress and builds up silent assistance', () {
      var save = WordForgeSave.fresh('p');
      final node = road.node('r1_n1')!;
      for (var i = 0; i < 3; i++) {
        save = progression.applyBattle(content: content, save: save, node: node, result: _result(victory: false)).save;
      }
      expect(save.isCompleted('r1_n1'), isFalse);
      expect(save.progressOf('r1_n1').failureStreak, 3);
      final setup = progression.buildSetup(content: content, save: save, node: node)!;
      expect(setup.assist, const AssistPolicy().forFailures(3));
      expect(setup.assist.reducedOptions, isTrue);
      save = progression.applyBattle(content: content, save: save, node: node, result: _result()).save;
      expect(save.progressOf('r1_n1').failureStreak, 0);
    });

    test('used buffs are removed and rewards added', () {
      final save = WordForgeSave.fresh('p');
      final applied = progression.applyBattle(
        content: content,
        save: save,
        node: road.node('r1_mb')!,
        result: _result(consumed: {BuffType.hint: 1}),
      );
      expect(applied.save.buffs[BuffType.hint], starterBuffs[BuffType.hint]! - 1 + (applied.summary.leveledUp ? 1 : 0));
      expect(applied.save.buffs[BuffType.shield], starterBuffs[BuffType.shield]! + 1);
    });

    test('replaying a node cannot farm buffs', () {
      var save = WordForgeSave.fresh('p');
      final node = road.node('r1_mb')!;
      save = progression.applyBattle(content: content, save: save, node: node, result: _result(correct: 8, wrong: 2)).save;
      final shields = save.buffs[BuffType.shield];
      final replay = progression.applyBattle(content: content, save: save, node: node, result: _result(correct: 8, wrong: 2));
      expect(replay.save.buffs[BuffType.shield], shields);
      expect(replay.summary.firstClear, isFalse);
    });

    test('bonus nodes pay once', () {
      final save = WordForgeSave.fresh('p');
      final node = road.node('r1_x1')!;
      final first = progression.claimNode(content: content, save: save, node: node);
      expect(first.summary.alreadyClaimed, isFalse);
      expect(first.save.buffs[BuffType.hint], starterBuffs[BuffType.hint]! + 1);
      final second = progression.claimNode(content: content, save: first.save, node: node);
      expect(second.summary.alreadyClaimed, isTrue);
      expect(second.save, first.save);
    });

    test('mystery outcomes are fixed per player', () {
      final node = road.node('r1_m1')!;
      final save = WordForgeSave.fresh('player-1');
      final outcome = progression.mysteryOutcomeFor(save, node);
      expect(progression.mysteryOutcomeFor(save, node), outcome);
      final revealed = progression.revealMystery(save, node);
      expect(revealed.progressOf(node.id).mysteryOutcome, node.outcomes.indexOf(outcome));
      final kinds = {
        for (var i = 0; i < 20; i++) progression.mysteryOutcomeFor(WordForgeSave.fresh('p$i'), node).kind,
      };
      expect(kinds, containsAll(MysteryOutcomeKind.values));
    });

    test('beating a boss for the first time unlocks the next region', () {
      final applied = progression.applyBattle(
          content: content, save: WordForgeSave.fresh('p'), node: road.node(road.bossNodeId)!, result: _result());
      expect(applied.summary.unlockedRegionId, forest.id);
      expect(applied.save.currentRegionId, forest.id);
    });

    test('skill points come from levels and upgrades are capped', () {
      var save = WordForgeSave.fresh('p');
      expect(progression.purchaseUpgrade(save, UpgradeType.focus), isNull);
      save = save.copyWith(xp: 10000);
      final points = progression.availableSkillPoints(save);
      expect(points, PlayerLevel.fromXp(10000).level - 1);
      for (var i = 0; i < 5; i++) {
        save = progression.purchaseUpgrade(save, UpgradeType.insight) ?? save;
      }
      expect(save.upgrades[UpgradeType.insight], UpgradeType.insight.maxLevel);
      expect(progression.availableSkillPoints(save), points - UpgradeType.insight.maxLevel);
    });

    test('battle setups carry every enemy of the encounter, combat config and per-save tutorials', () {
      final save = WordForgeSave.fresh('p').copyWith(tutorialFlags: {'attack'});
      final setup = progression.buildSetup(content: content, save: save, node: road.node('r1_n8')!)!;
      expect(setup.enemies.map((enemy) => enemy.id), ['goblin_raider', 'goblin_scout']);
      expect(setup.enemyHp, [45, 40]);
      expect(setup.knownTutorials, {'attack'});
      expect(setup.config.balance.normalDamage, content.combat.balance.normalDamage);
    });

    test('spells are witnessed on the first clear of a teaching node and learned with a skill point', () {
      var save = WordForgeSave.fresh('p');
      expect(progression.spellsFor(content, save), [content.combat.playerSpecial]);
      expect(progression.witnessedSpells(content, save), isEmpty);
      final boss = road.node(road.bossNodeId)!;
      expect(boss.teaches, 'guardian_ward');
      expect(progression.teacherOf(content, 'guardian_ward')?.id, boss.id);
      // Cannot learn before witnessing, even with points.
      save = save.copyWith(xp: 10000);
      expect(progression.learnSpell(content, save, 'guardian_ward'), isNull);

      final applied = progression.applyBattle(content: content, save: save, node: boss, result: _result());
      expect(applied.summary.witnessedSpellId, 'guardian_ward');
      save = applied.save;
      expect(save.spells, isEmpty, reason: 'witnessed, not yet learned');
      expect(progression.witnessedSpells(content, save), {'guardian_ward'});
      expect(progression.spellsFor(content, save), [content.combat.playerSpecial]);

      final points = progression.availableSkillPoints(save);
      save = progression.learnSpell(content, save, 'guardian_ward')!;
      expect(save.spells, ['guardian_ward']);
      expect(progression.availableSkillPoints(save), points - 1);
      expect(progression.learnSpell(content, save, 'guardian_ward'), isNull, reason: 'learned once');
      expect(progression.learnSpell(content, save, content.combat.playerSpecial), isNull, reason: 'starter is free');
      expect(progression.buildSetup(content: content, save: save, node: road.node('r1_n1')!)!.spells,
          [content.combat.playerSpecial, 'guardian_ward']);
      final again = progression.applyBattle(content: content, save: save, node: boss, result: _result());
      expect(again.summary.witnessedSpellId, isNull);
    });

    test('learning needs a free skill point', () {
      final save = WordForgeSave.fresh('p').copyWith(nodes: {road.bossNodeId: const NodeProgress(completed: true, wins: 1)});
      expect(progression.witnessedSpells(content, save), {'guardian_ward'});
      expect(progression.availableSkillPoints(save), 0);
      expect(progression.learnSpell(content, save, 'guardian_ward'), isNull);
      expect(progression.learnSpell(content, save.copyWith(xp: 100), 'guardian_ward'), isNotNull);
    });

    test('mechanics unlock gradually with wins', () {
      MechanicAccess access(int wins) => progression
          .buildSetup(content: content, save: WordForgeSave.fresh('p').copyWith(battleWins: wins), node: road.node('r1_n1')!)!
          .access;
      expect(access(0).critical, isFalse);
      expect(access(1).critical, isTrue);
      expect(access(1).special, isFalse);
      expect(access(2).special, isTrue);
      expect(access(3).protection, isTrue);
      expect(access(4).enemySpecials, isFalse);
      expect(access(5).enemySpecials, isTrue);
    });

    test('protection grants a free ward every few battles', () {
      var save = WordForgeSave.fresh('p').copyWith(upgrades: const UpgradeLevels({UpgradeType.protection: 1}));
      final node = road.node('r1_n1')!;
      final wards = <bool>[];
      for (var i = 0; i < 6; i++) {
        wards.add(progression.buildSetup(content: content, save: save, node: node)!.startWithWard);
        save = progression.applyBattle(content: content, save: save, node: node, result: _result()).save;
      }
      expect(wards, [false, false, true, false, false, true]);
    });
  });
}
