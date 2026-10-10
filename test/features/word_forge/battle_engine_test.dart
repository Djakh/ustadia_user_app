import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/battle_assist.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/battle_engine.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/battle_events.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/battle_models.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/combat_config.dart';
import 'package:ustadia_user_app/features/word_forge/domain/content/battle_definition.dart';
import 'package:ustadia_user_app/features/word_forge/domain/content/difficulty.dart';
import 'package:ustadia_user_app/features/word_forge/domain/content/word_forge_content.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/challenge_type.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/buffs.dart';

import 'helpers.dart';

/// Config with chosen probabilities, so tests never depend on luck.
CombatConfig _config(
  WordForgeContent content, {
  double playerCritical = 0,
  int criticalCooldown = 3,
  Map<String, EnemyBehaviour> archetypes = const {},
  int minNormalEnemyTurns = 1,
  int specialCooldown = 3,
}) =>
    CombatConfig(
      balance: content.combat.balance,
      meter: content.combat.meter,
      timers: content.combat.timers,
      gates: content.combat.gates,
      moves: content.combat.moves,
      archetypes: {...content.combat.archetypes, ...archetypes},
      pacing: PacingConfig(
        playerCriticalChance: playerCritical,
        playerCriticalCap: 1,
        comboCriticalBonus: 0,
        criticalCooldownTurns: criticalCooldown,
        enemySpecialCooldown: specialCooldown,
        minNormalEnemyTurns: minNormalEnemyTurns,
      ),
    );

const _calm = EnemyBehaviour(criticalChance: 0, specialChance: 0);

BattleSetup _setup(
  WordForgeContent content, {
  List<String> enemies = const ['goblin_scout'],
  List<int>? hp,
  CombatConfig? config,
  List<BattleStage> stages = const [BattleStage()],
  MechanicAccess access = MechanicAccess.all,
  Map<BuffType, int> inventory = const {},
  bool ward = false,
  BattleAssist assist = BattleAssist.none,
}) {
  final definitions = [for (final id in enemies) content.enemies[id]!];
  return BattleSetup(
    battle: BattleDefinition(
      id: 'test',
      enemies: [for (final id in enemies) BattleEnemy(id)],
      degrees: const DegreeRange(1, 2),
      stages: stages,
      rewards: const BattleRewards(xp: 10),
    ),
    enemies: definitions,
    enemyHp: hp ?? [for (final enemy in definitions) enemy.maxHp],
    degrees: const DegreeRange(1, 2),
    config: config ?? _config(content, archetypes: {'goblin': _calm}),
    access: access,
    inventory: inventory,
    startWithWard: ward,
    assist: assist,
  );
}

List<BattleEvent> _record(BattleEngine engine) {
  final events = <BattleEvent>[];
  engine.events.listen(events.add);
  return events;
}

/// Answers correctly until mana is full (every known spell affordable).
void _chargeSpecial(BattleEngine engine) {
  var guard = 0;
  while (engine.mana < engine.manaMax && guard++ < 80) {
    runUntilInput(engine);
    if (engine.mana >= engine.manaMax && engine.canActivateSpecial) break;
    answerCorrectly(engine);
    runUntilInput(engine);
  }
  while (!engine.canActivateSpecial && guard++ < 100) {
    answerCorrectly(engine);
    runUntilInput(engine);
  }
}

void main() {
  final content = loadShippedContent();

  group('turns', () {
    test('player attacks with a similar word, then the enemy attacks and is defended with the opposite', () {
      final engine = buildEngine(content, _setup(content));
      final events = _record(engine);
      engine.start();
      runUntilInput(engine);
      expect(engine.snapshot.turn, BattleTurn.player);
      expect(engine.snapshot.moveKind, MoveKind.normal);
      expect(engine.snapshot.challenge!.type, ChallengeType.synonym);
      answerCorrectly(engine);
      runUntilInput(engine);
      expect(engine.snapshot.turn, BattleTurn.enemy);
      expect(engine.snapshot.challenge!.type, ChallengeType.antonym);
      answerCorrectly(engine);
      runUntilInput(engine);
      expect(engine.snapshot.turn, BattleTurn.player);
      final turns = events.whereType<TurnStarted>().map((event) => event.turn).toList();
      expect(turns, [BattleTurn.player, BattleTurn.enemy, BattleTurn.player]);
    });

    test('a correct normal attack damages the target; a wrong one is a Weak Cast that still lands a little', () {
      final engine = buildEngine(content, _setup(content));
      engine.start();
      runUntilInput(engine);
      expect(engine.snapshot.hasTimer, isTrue, reason: 'normal attacks are gently timed');
      expect(engine.snapshot.timerTotal, inInclusiveRange(5.0, 12.0));
      final hp = engine.snapshot.primary.hp;
      answerCorrectly(engine);
      expect(engine.snapshot.primary.hp, hp - content.combat.balance.normalDamage);
      runUntilInput(engine);
      answerCorrectly(engine);
      runUntilInput(engine);
      final before = engine.snapshot;
      answerWrongly(engine);
      final counter = (content.enemies['goblin_scout']!.attack * content.combat.balance.weakCastCounterShare).round();
      expect(engine.snapshot.playerHp, before.playerHp - counter, reason: 'a wrong word leaves the player open to a small counter');
      expect(engine.snapshot.primary.hp, before.primary.hp - content.combat.balance.weakCastDamage);
      expect(engine.snapshot.lastOutcome!.weakCast, isTrue);
      expect(engine.snapshot.combo, 0);
    });

    test('a normal attack that times out is a Weak Cast, never a lost turn', () {
      final engine = buildEngine(content, _setup(content));
      engine.start();
      runUntilInput(engine);
      final hp = engine.snapshot.primary.hp;
      for (var i = 0; i < 400 && engine.phase == BattlePhase.awaitingInput; i++) {
        engine.tick(0.1);
      }
      expect(engine.snapshot.lastOutcome!.timedOut, isTrue);
      expect(engine.snapshot.lastOutcome!.weakCast, isTrue);
      expect(engine.snapshot.primary.hp, hp - content.combat.balance.weakCastDamage);
      expect(engine.snapshot.playerHp, 100, reason: 'hesitating is not punished, only being wrong');
    });

    test('enemy normal attacks are timed too, and slow enemies give more time than quick ones', () {
      double defenceTimer(String enemy) {
        final engine = buildEngine(content, _setup(content, enemies: [enemy], hp: [400], config: _config(content)), seed: 2);
        engine.start();
        runUntilInput(engine);
        answerCorrectly(engine);
        runUntilInput(engine);
        expect(engine.snapshot.turn, BattleTurn.enemy);
        return engine.snapshot.timerTotal;
      }

      final goblin = defenceTimer('goblin_scout');
      final golem = defenceTimer('stone_sentinel');
      expect(goblin, greaterThan(0));
      expect(golem, greaterThan(goblin), reason: 'stone guardians telegraph slowly');
    });

    test('stone skin reduces normal hits but not Criticals or Specials', () {
      final engine = buildEngine(content, _setup(content, enemies: ['stone_sentinel'], hp: [400], config: _config(content)));
      engine.start();
      runUntilInput(engine);
      final hp = engine.snapshot.primary.hp;
      answerCorrectly(engine);
      final armor = content.combat.behaviourFor('stoneGuardian').armor;
      expect(armor, greaterThan(0));
      expect(engine.snapshot.primary.hp, hp - (content.combat.balance.normalDamage * (1 - armor)).round());
    });

    test('a failed defence lets the attack land; a successful one counters', () {
      final engine = buildEngine(content, _setup(content));
      engine.start();
      runUntilInput(engine);
      answerCorrectly(engine);
      runUntilInput(engine);
      final enemyHp = engine.snapshot.primary.hp;
      answerCorrectly(engine);
      expect(engine.snapshot.playerHp, 100);
      expect(engine.snapshot.primary.hp, lessThan(enemyHp));
      runUntilInput(engine);
      answerCorrectly(engine);
      runUntilInput(engine);
      answerWrongly(engine);
      expect(engine.snapshot.playerHp, 100 - content.enemies['goblin_scout']!.attack);
    });
  });

  group('critical attacks', () {
    BattleEngine criticalEngine() => buildEngine(
        content, _setup(content, hp: [999], config: _config(content, playerCritical: 1, archetypes: {'goblin': _calm})));

    /// Plays to the first Critical Opportunity; returns enemy HP right after the normal hit.
    int toFirstCritical(BattleEngine engine) {
      engine.start();
      var hp = 0;
      for (var guard = 0; guard < 10 && !engine.snapshot.criticalOpportunity; guard++) {
        runUntilInput(engine);
        if (engine.snapshot.criticalOpportunity) break;
        answerCorrectly(engine);
        hp = engine.snapshot.primary.hp;
      }
      runUntilInput(engine);
      return hp;
    }

    test('a correct normal attack can open a Critical Opportunity that adds bonus damage', () {
      final engine = criticalEngine();
      final events = _record(engine);
      final afterNormal = toFirstCritical(engine);
      expect(events.whereType<CriticalOpportunity>(), hasLength(1));
      expect(engine.snapshot.criticalOpportunity, isTrue);
      expect(engine.snapshot.hasTimer, isTrue);
      expect(events.whereType<TurnStarted>().where((event) => event.turn == BattleTurn.player).length, greaterThan(1),
          reason: 'never on the very first player turn');
      while (engine.snapshot.criticalOpportunity && engine.phase == BattlePhase.awaitingInput) {
        answerCorrectly(engine);
        runUntilInput(engine);
      }
      expect(engine.snapshot.primary.hp, lessThan(afterNormal));
    });

    test('a failed Critical Opportunity never removes the normal attack damage', () {
      final engine = criticalEngine();
      final afterNormal = toFirstCritical(engine);
      expect(engine.snapshot.criticalOpportunity, isTrue);
      for (var i = 0; i < 2000 && engine.snapshot.criticalOpportunity && !engine.isOver; i++) {
        engine.tick(0.1);
      }
      expect(engine.snapshot.primary.hp, afterNormal);
      expect(engine.snapshot.playerHp, 100);
    });

    test('criticals respect the cooldown', () {
      final engine = criticalEngine();
      final sequence = StringBuffer();
      engine.events.listen((event) {
        if (event is CriticalOpportunity) sequence.write('C');
        if (event is TurnStarted && event.kind == MoveKind.normal) sequence.write(event.turn == BattleTurn.player ? 'P' : 'E');
      });
      playBattle(engine, (_) => true, maxTasks: 60, useSpecial: false);
      final text = sequence.toString();
      expect('C'.allMatches(text).length, greaterThan(2), reason: text);
      final gaps = text.split('C').skip(1).toList()..removeLast();
      for (final gap in gaps) {
        expect(gap.length, greaterThanOrEqualTo(3), reason: text);
      }
    });

    test('enemy Critical is telegraphed, timed, and hits harder when failed', () {
      final engine = buildEngine(content,
          _setup(content, config: _config(content, archetypes: {'goblin': const EnemyBehaviour(criticalChance: 1, specialChance: 0)})));
      final events = _record(engine);
      engine.start();
      for (var i = 0; i < 3; i++) {
        runUntilInput(engine);
        answerCorrectly(engine);
      }
      runUntilInput(engine);
      expect(engine.snapshot.turn, BattleTurn.enemy);
      expect(engine.snapshot.moveKind, MoveKind.critical);
      expect(events.whereType<TurnStarted>().last.kind, MoveKind.critical);
      expect(engine.snapshot.hasTimer, isTrue);
      expect(engine.snapshot.timerTotal, inInclusiveRange(3.5, 9.0));
      answerWrongly(engine);
      final attack = content.enemies['goblin_scout']!.attack;
      expect(engine.snapshot.playerHp, 100 - (attack * content.combat.balance.enemyCriticalMultiplier).round());
    });

    test('mechanics stay locked until unlocked by progress', () {
      final engine = buildEngine(
        content,
        _setup(content,
            hp: [400],
            access: MechanicAccess.none,
            config: _config(content, playerCritical: 1, archetypes: {'goblin': const EnemyBehaviour(criticalChance: 1)})),
      );
      final events = _record(engine);
      playBattle(engine, (_) => true, maxTasks: 30);
      expect(events.whereType<CriticalOpportunity>(), isEmpty);
      expect(events.whereType<TurnStarted>().where((event) => event.kind != MoveKind.normal), isEmpty);
      expect(engine.snapshot.specialCharge, 0);
    });
  });

  group('special attack', () {
    test('mana grows from correct answers, a cast spends it, and the starter uses three English stages', () {
      final engine = buildEngine(content, _setup(content, hp: [999]));
      final events = _record(engine);
      engine.start();
      expect(engine.mana, content.combat.meter.start);
      _chargeSpecial(engine);
      expect(events.whereType<SpecialReady>(), hasLength(1), reason: 'once, when the first spell became affordable');
      expect(engine.snapshot.specialReady, isTrue);
      final cost = content.combat.move('apprentice_incantation')!.manaCost;
      final manaBefore = engine.mana;
      expect(engine.activateSpecial(), isTrue);
      expect(engine.mana, manaBefore - cost);
      expect(engine.snapshot.spell('apprentice_incantation')!.manaCost, cost);
      runUntilInput(engine);
      expect(engine.snapshot.moveKind, MoveKind.special);
      expect(engine.snapshot.taskCount, 3);
      final types = <ChallengeType>[];
      final hpBefore = engine.snapshot.primary.hp;
      while (engine.snapshot.moveKind == MoveKind.special && engine.phase == BattlePhase.awaitingInput) {
        types.add(engine.snapshot.challenge!.type);
        answerCorrectly(engine);
        runUntilInput(engine);
      }
      expect(types.take(2), [ChallengeType.antonym, ChallengeType.synonym]);
      expect(types[2], anyOf(ChallengeType.missingRune, ChallengeType.incantation));
      expect(hpBefore - engine.snapshot.primary.hp, greaterThanOrEqualTo(content.combat.balance.specialDamage));
    });

    test('a partly completed Special still deals reduced damage', () {
      int specialDamage(bool Function(int stage) correct) {
        final engine = buildEngine(content, _setup(content, hp: [999]), seed: 3);
        engine.start();
        _chargeSpecial(engine);
        engine.activateSpecial();
        runUntilInput(engine);
        final before = engine.snapshot.primary.hp;
        var stage = 0;
        while (engine.snapshot.moveKind == MoveKind.special && engine.phase == BattlePhase.awaitingInput) {
          correct(stage++) ? answerCorrectly(engine) : answerWrongly(engine);
          runUntilInput(engine);
        }
        return before - engine.snapshot.primary.hp;
      }

      final full = specialDamage((_) => true);
      final twoThirds = specialDamage((stage) => stage != 1);
      final none = specialDamage((_) => false);
      expect(full, greaterThan(twoThirds));
      expect(twoThirds, greaterThan(0));
      expect(none, 0, reason: 'no stage solved = fizzle');
    });

    test('cannot be cast without enough mana, and the reason is reported', () {
      final engine = buildEngine(content, _setup(content));
      engine.start();
      runUntilInput(engine);
      expect(engine.activateSpecial(), isFalse);
      expect(engine.spellBlock('apprentice_incantation'), SpellBlock.mana);
      expect(engine.snapshot.spells.single.block, SpellBlock.mana);
    });

    test('a successful cast starts that spell\'s cooldown in attack turns; a fizzle does not', () {
      final cooldown = content.combat.move('apprentice_incantation')!.cooldown;
      expect(cooldown, greaterThan(0));
      final engine = buildEngine(content, _setup(content, hp: [999]), seed: 3);
      engine.start();
      _chargeSpecial(engine);
      engine.activateSpecial();
      runUntilInput(engine);
      while (engine.snapshot.moveKind == MoveKind.special && engine.phase == BattlePhase.awaitingInput) {
        answerCorrectly(engine);
        runUntilInput(engine);
      }
      expect(engine.cooldownLeft('apprentice_incantation'), cooldown + 1, reason: 'counts down at the next attack turn');
      var blockedTurns = 0;
      while (engine.cooldownLeft('apprentice_incantation') > 0 && blockedTurns < 10) {
        runUntilInput(engine);
        if (engine.snapshot.turn == BattleTurn.player && engine.snapshot.moveKind == MoveKind.normal) {
          expect(engine.spellBlock('apprentice_incantation'), SpellBlock.cooldown);
          blockedTurns++;
        }
        answerCorrectly(engine);
        runUntilInput(engine);
      }
      expect(blockedTurns, cooldown);
      expect(engine.spellBlock('apprentice_incantation'), isNot(SpellBlock.cooldown));

      final fizzle = buildEngine(content, _setup(content, hp: [999]), seed: 3);
      fizzle.start();
      _chargeSpecial(fizzle);
      final mana = fizzle.mana;
      fizzle.activateSpecial();
      runUntilInput(fizzle);
      while (fizzle.snapshot.moveKind == MoveKind.special && fizzle.phase == BattlePhase.awaitingInput) {
        answerWrongly(fizzle);
        runUntilInput(fizzle);
      }
      expect(fizzle.snapshot.lastOutcome!.spellFizzled, isTrue);
      expect(fizzle.mana, mana - content.combat.move('apprentice_incantation')!.manaCost, reason: 'mana is spent');
      expect(fizzle.cooldownLeft('apprentice_incantation'), 0, reason: 'no cooldown on a fizzle');
      expect(fizzle.snapshot.playerHp, 100, reason: 'no counter either');
    });

    BattleEngine withSpells(List<String> spells, {List<String> enemies = const ['goblin_scout']}) {
      final definitions = [for (final id in enemies) content.enemies[id]!];
      final engine = buildEngine(
        content,
        BattleSetup(
          battle: BattleDefinition(
            id: 'spells',
            enemies: [for (final id in enemies) BattleEnemy(id)],
            degrees: const DegreeRange(1, 2),
            rewards: const BattleRewards(xp: 10),
          ),
          enemies: definitions,
          enemyHp: [for (final _ in definitions) 999],
          degrees: const DegreeRange(1, 2),
          config: _config(content, archetypes: {'goblin': _calm, 'stoneGuardian': _calm}),
          spells: spells,
        ),
        seed: 5,
      );
      engine.start();
      _chargeSpecial(engine);
      return engine;
    }

    void finishSpecial(BattleEngine engine, bool Function(int stage) correct) {
      var stage = 0;
      while (engine.snapshot.moveKind == MoveKind.special && engine.phase == BattlePhase.awaitingInput) {
        correct(stage++) ? answerCorrectly(engine) : answerWrongly(engine);
        runUntilInput(engine);
      }
    }

    test('only known spells can be cast; the first castable spell is the default', () {
      final engine = withSpells(['apprentice_incantation', 'guardian_ward']);
      expect(engine.knownSpells, ['apprentice_incantation', 'guardian_ward']);
      expect(engine.activateSpecial('rune_bind'), isFalse, reason: 'not learned yet');
      expect(engine.snapshot.spells.map((spell) => spell.castable), [true, true]);
      expect(engine.activateSpecial(), isTrue);
      runUntilInput(engine);
      expect(engine.snapshot.moveId, 'apprentice_incantation');
      expect(engine.snapshot.spell('guardian_ward')!.castable, isFalse, reason: 'not during a Special');
      expect(engine.snapshot.spell('guardian_ward')!.block, SpellBlock.turn);
    });

    test('Guardian Ward absorbs the next two enemy hits on full success, one on partial, and reflects damage', () {
      final engine = withSpells(['guardian_ward']);
      final reflect = content.combat.move('guardian_ward')!.reflect;
      expect(reflect, greaterThan(0));
      expect(engine.activateSpecial('guardian_ward'), isTrue);
      runUntilInput(engine);
      expect(engine.snapshot.taskCount, 2);
      finishSpecial(engine, (_) => true);
      expect(engine.snapshot.wardCharges, 2);
      expect(engine.snapshot.lastOutcome!.wardCharges, 2);
      // Two failed defences cost nothing and hurt the attacker, the third hurts.
      var blocked = 0;
      var reflected = 0;
      for (var i = 0; i < 3; i++) {
        runUntilInput(engine);
        if (engine.snapshot.turn == BattleTurn.player) {
          answerCorrectly(engine);
          runUntilInput(engine);
        }
        expect(engine.snapshot.turn, BattleTurn.enemy);
        answerWrongly(engine);
        final outcome = engine.snapshot.lastOutcome!;
        if (outcome.blockedByWard) blocked++;
        reflected += outcome.reflected;
      }
      expect(blocked, 2);
      expect(reflected, reflect * 2);
      expect(engine.snapshot.playerHp, lessThan(100));

      final partial = withSpells(['guardian_ward']);
      partial.activateSpecial('guardian_ward');
      runUntilInput(partial);
      finishSpecial(partial, (stage) => stage == 0);
      expect(partial.snapshot.wardCharges, 1);
    });

    test('Rune Bind makes the enemy lose its next turn on full success and always deals damage', () {
      final engine = withSpells(['rune_bind']);
      final events = _record(engine);
      final hp = engine.snapshot.primary.hp;
      expect(engine.activateSpecial('rune_bind'), isTrue);
      runUntilInput(engine);
      finishSpecial(engine, (_) => true);
      expect(engine.snapshot.lastOutcome!.staggerApplied, isTrue);
      expect(engine.snapshot.primary.hp, lessThan(hp));
      runUntilInput(engine);
      expect(events.whereType<TurnSkipped>().where((event) => event.reason == 'staggered'), hasLength(1));
      expect(engine.snapshot.turn, BattleTurn.player, reason: 'the enemy turn was skipped');

      final partial = withSpells(['rune_bind']);
      final partialHp = partial.snapshot.primary.hp;
      partial.activateSpecial('rune_bind');
      runUntilInput(partial);
      finishSpecial(partial, (stage) => stage == 0);
      expect(partial.snapshot.lastOutcome!.staggerApplied, isFalse);
      expect(partial.snapshot.primary.hp, lessThan(partialHp));
    });

    test('Thorn Blight poisons the target: ticks before each enemy turn, through stone skin and shields', () {
      final move = content.combat.move('thorn_blight')!;
      final engine = withSpells(['thorn_blight'], enemies: ['stone_sentinel']);
      final events = _record(engine);
      final hp = engine.snapshot.primary.hp;
      expect(engine.activateSpecial('thorn_blight'), isTrue);
      runUntilInput(engine);
      expect(engine.snapshot.taskCount, 2);
      finishSpecial(engine, (_) => true);
      expect(engine.snapshot.lastOutcome!.poisonApplied, move.duration);
      // The first tick lands right after the cast, before the enemy's turn.
      expect(engine.snapshot.primary.poisonTicks, move.duration - 1);
      expect(hp - engine.snapshot.primary.hp, greaterThanOrEqualTo(move.amount));
      // Play on: every enemy turn is preceded by one tick of at least `amount`.
      for (var i = 0; i < 8 && engine.snapshot.primary.poisoned; i++) {
        runUntilInput(engine);
        answerCorrectly(engine);
      }
      final ticks = events.whereType<PoisonTick>().toList();
      expect(ticks, hasLength(move.duration));
      for (final tick in ticks) {
        expect(tick.target, 0);
        expect(tick.damage, greaterThanOrEqualTo(move.amount), reason: 'stone skin does not apply');
      }
      expect(engine.snapshot.primary.poisoned, isFalse);

      final partial = withSpells(['thorn_blight']);
      partial.activateSpecial('thorn_blight');
      runUntilInput(partial);
      finishSpecial(partial, (stage) => stage == 0);
      expect(partial.snapshot.primary.poisonTicks, move.duration - 2, reason: 'one tick fewer, first already landed');
    });

    test('ethereal enemies cannot be poisoned, and the spell is blocked rather than wasted', () {
      final engine = withSpells(['thorn_blight', 'apprentice_incantation'], enemies: ['road_wisp']);
      expect(engine.spellBlock('thorn_blight'), SpellBlock.immune);
      expect(engine.activateSpecial('thorn_blight'), isFalse);
      expect(engine.activateSpecial(), isTrue, reason: 'the default skips the blocked spell');
      runUntilInput(engine);
      expect(engine.snapshot.moveId, 'apprentice_incantation');
    });

    test('an enemy Thorn Curse poisons the player on a failed defence; a ward absorbs it', () {
      BattleEngine cursed({bool ward = false}) {
        final engine = buildEngine(
          content,
          _setup(
            content,
            enemies: ['thornmother'],
            hp: [999],
            ward: ward,
            config: _config(content, minNormalEnemyTurns: 0, specialCooldown: 0, archetypes: {
              'boss': const EnemyBehaviour(criticalChance: 0, specialChance: 1, specials: ['thorn_curse']),
            }),
          ),
          seed: 4,
        );
        engine.start();
        return engine;
      }

      final move = content.combat.move('thorn_curse')!;
      final engine = cursed();
      final events = _record(engine);
      var guard = 0;
      while (engine.snapshot.playerPoisonTicks == 0 && guard++ < 12) {
        runUntilInput(engine);
        if (engine.snapshot.turn == BattleTurn.enemy && engine.snapshot.moveId == 'thorn_curse') {
          answerWrongly(engine);
        } else {
          answerCorrectly(engine);
        }
      }
      expect(engine.snapshot.playerPoisonTicks, move.duration);
      final hpAfterHit = engine.snapshot.playerHp;
      runUntilInput(engine);
      expect(events.whereType<PoisonTick>().where((tick) => tick.target == -1), hasLength(1), reason: 'ticks before the player turn');
      expect(engine.snapshot.playerHp, hpAfterHit - move.amount);

      final warded = cursed(ward: true);
      guard = 0;
      while (warded.snapshot.playerHp == 100 && warded.snapshot.playerPoisonTicks == 0 && guard++ < 12) {
        runUntilInput(warded);
        if (warded.snapshot.turn == BattleTurn.enemy && warded.snapshot.moveId == 'thorn_curse') {
          answerWrongly(warded);
          break;
        }
        answerCorrectly(warded);
      }
      expect(warded.snapshot.lastOutcome!.blockedByWard, isTrue);
      expect(warded.snapshot.playerPoisonTicks, 0);
    });

    test('Word Storm (multi-hit effect, kept for v2 content) hits once per correct word and is timed', () {
      int stormDamage(bool Function(int) correct) {
        final engine = withSpells(['word_storm_spell']);
        final hp = engine.snapshot.primary.hp;
        engine.activateSpecial('word_storm_spell');
        runUntilInput(engine);
        expect(engine.snapshot.hasTimer, isTrue);
        expect(engine.snapshot.taskCount, 3);
        finishSpecial(engine, correct);
        return hp - engine.snapshot.primary.hp;
      }

      // Combo and flow multipliers apply (and a wrong word resets the combo),
      // so compare hit counts rather than exact numbers.
      final perHit = content.combat.move('word_storm_spell')!.amount;
      final full = stormDamage((_) => true);
      final twoHits = stormDamage((stage) => stage != 1);
      expect(full, greaterThanOrEqualTo(perHit * 3));
      expect(twoHits, inInclusiveRange(perHit * 2, full - perHit));
      expect(stormDamage((_) => false), 0);
    });

    test('Specials pierce stone skin', () {
      final engine = withSpells(['word_storm_spell'], enemies: ['stone_sentinel']);
      final hp = engine.snapshot.primary.hp;
      engine.activateSpecial('word_storm_spell');
      runUntilInput(engine);
      finishSpecial(engine, (_) => true);
      expect(hp - engine.snapshot.primary.hp, greaterThanOrEqualTo(content.combat.move('word_storm_spell')!.amount * 3));
    });

    test('attack turns are counted for the efficiency star', () {
      final engine = buildEngine(content, _setup(content));
      final result = playBattle(engine, (_) => true, useSpecial: false);
      expect(result.victory, isTrue);
      expect(result.attackTurns, result.records.where((r) => r.turn == BattleTurn.player && r.kind == MoveKind.normal).length);
    });
  });

  group('enemy specials', () {
    CombatConfig only(String special, {String archetype = 'stoneGuardian', int shield = 2}) => _config(content,
        minNormalEnemyTurns: 0,
        specialCooldown: 0,
        archetypes: {
          archetype: EnemyBehaviour(criticalChance: 0, specialChance: 1, specials: [special], shieldStrength: shield),
        });

    test('Protection raises a shield that normal attacks must break with similar words', () {
      final engine = buildEngine(content, _setup(content, enemies: ['stone_sentinel'], hp: [400], config: only('protection')));
      final events = _record(engine);
      engine.start();
      runUntilInput(engine);
      answerCorrectly(engine); // player
      runUntilInput(engine);
      answerCorrectly(engine); // first enemy turn is always normal
      runUntilInput(engine);
      answerCorrectly(engine); // player
      runUntilInput(engine); // enemy raises the shield, then it is the player's turn
      expect(events.whereType<ActionResolved>().last.outcome.shieldRaised, isTrue);
      expect(engine.snapshot.primary.shield, const ShieldSnapshot(strength: 2, remaining: 2));
      expect(engine.snapshot.turn, BattleTurn.player);
      final hp = engine.snapshot.primary.hp;
      answerCorrectly(engine);
      expect(engine.snapshot.primary.shield!.remaining, 1);
      expect(engine.snapshot.primary.hp, hp, reason: 'the shield absorbs the hit');
      runUntilInput(engine);
      answerCorrectly(engine); // enemy: already shielded -> normal attack
      runUntilInput(engine);
      answerCorrectly(engine);
      expect(engine.snapshot.primary.shield, isNull);
      expect(engine.snapshot.primary.staggered, isTrue);
      expect(events.whereType<ActionResolved>().last.outcome.shieldShattered, isTrue);
      runUntilInput(engine);
      expect(events.whereType<TurnSkipped>().single.reason, 'staggered');
      expect(engine.snapshot.turn, BattleTurn.player);
    });

    test('Rune Lock failure skips the next player attack', () {
      final engine = buildEngine(
          content, _setup(content, enemies: ['goblin_shaman'], hp: [400], config: only('rune_lock', archetype: 'rogueMage')));
      final events = _record(engine);
      engine.start();
      for (var i = 0; i < 3; i++) {
        runUntilInput(engine);
        answerCorrectly(engine);
      }
      runUntilInput(engine);
      expect(engine.snapshot.moveId, 'rune_lock');
      expect(engine.snapshot.challenge!.type, ChallengeType.missingRune);
      answerWrongly(engine);
      expect(engine.snapshot.playerLocked, isTrue);
      runUntilInput(engine);
      expect(events.whereType<TurnSkipped>().single.reason, 'locked');
      expect(engine.snapshot.turn, BattleTurn.enemy);
    });

    test('multi-task specials resolve every stage with one shared timer', () {
      final engine = buildEngine(
          content, _setup(content, enemies: ['goblin_shaman'], hp: [400], config: only('double_threat', archetype: 'rogueMage')));
      engine.start();
      for (var i = 0; i < 3; i++) {
        runUntilInput(engine);
        answerCorrectly(engine);
      }
      runUntilInput(engine);
      expect(engine.snapshot.moveId, 'double_threat');
      expect(engine.snapshot.taskCount, 2);
      final timer = engine.snapshot.timerTotal;
      expect(timer, greaterThan(0));
      answerWrongly(engine);
      runUntilInput(engine);
      expect(engine.snapshot.taskIndex, 1);
      expect(engine.snapshot.timerTotal, timer, reason: 'shared timer is not restarted');
      answerCorrectly(engine);
      final attack = content.enemies['goblin_shaman']!.attack;
      expect(engine.snapshot.lastOutcome!.damageToPlayer, (attack * 0.65).round());
    });

    test('non-normal enemy moves always have a normal turn in between', () {
      final engine = buildEngine(
        content,
        _setup(content, enemies: ['goblin_shaman'], hp: [999], config: _config(content, minNormalEnemyTurns: 1, specialCooldown: 0, archetypes: {
          'rogueMage': const EnemyBehaviour(criticalChance: 0.5, specialChance: 0.5, specials: ['rune_lock']),
        })),
      );
      final kinds = <MoveKind>[];
      engine.events.listen((event) {
        if (event is TurnStarted && event.turn == BattleTurn.enemy) kinds.add(event.kind);
      });
      playBattle(engine, (_) => true, maxTasks: 60, useSpecial: false);
      expect(kinds.where((kind) => kind != MoveKind.normal), isNotEmpty);
      for (var i = 1; i < kinds.length; i++) {
        if (kinds[i] != MoveKind.normal) expect(kinds[i - 1], MoveKind.normal, reason: '$kinds');
      }
    });
  });

  group('two enemies', () {
    test('only one enemy acts per enemy turn, alternating', () {
      final engine = buildEngine(content, _setup(content, enemies: ['goblin_scout', 'goblin_raider'], hp: [500, 500]));
      final actors = <int>[];
      engine.events.listen((event) {
        if (event is TurnStarted && event.turn == BattleTurn.enemy) actors.add(event.actor);
      });
      playBattle(engine, (_) => true, maxTasks: 12, useSpecial: false);
      expect(actors.length, greaterThan(3));
      for (var i = 1; i < actors.length; i++) {
        expect(actors[i], isNot(actors[i - 1]));
      }
    });

    test('tapping an enemy switches the target; defeated enemies stop acting', () {
      final engine = buildEngine(content, _setup(content, enemies: ['goblin_scout', 'goblin_raider'], hp: [14, 500]));
      final events = _record(engine);
      engine.start();
      runUntilInput(engine);
      expect(engine.selectTarget(1), isTrue);
      expect(engine.snapshot.targetIndex, 1);
      expect(engine.selectTarget(0), isTrue);
      answerCorrectly(engine);
      expect(engine.snapshot.enemies[0].alive, isFalse);
      expect(events.whereType<EnemyDefeated>().single.index, 0);
      runUntilInput(engine);
      expect(engine.snapshot.actor, 1);
      answerCorrectly(engine);
      runUntilInput(engine);
      expect(engine.snapshot.targetIndex, 1);
    });

    test('guardians shield their ally', () {
      final engine = buildEngine(
        content,
        _setup(content, enemies: ['goblin_scout', 'stone_sentinel'], hp: [300, 300], config: _config(content, minNormalEnemyTurns: 0, specialCooldown: 0, archetypes: {
          'goblin': _calm,
          'stoneGuardian': const EnemyBehaviour(specialChance: 1, criticalChance: 0, specials: ['protection'], role: EnemyRole.guardian),
        })),
      );
      final events = _record(engine);
      playBattle(engine, (_) => true, maxTasks: 8, useSpecial: false);
      final raised = events.whereType<ActionResolved>().where((event) => event.outcome.shieldRaised);
      expect(raised, isNotEmpty);
      expect(raised.first.outcome.target, 0, reason: 'the guardian protects its ally');
    });
  });

  group('outcome', () {
    test('every shipped battle is won by a player who answers correctly', () {
      for (final battle in content.battles.values) {
        for (final seed in [1, 7]) {
          final engine = buildEngine(content, setupFor(content, battle.id), seed: seed);
          expect(playBattle(engine, (_) => true).victory, isTrue, reason: battle.id);
          engine.dispose();
        }
      }
    });

    test('players with ~80% accuracy win, and battles stay within the target length', () {
      for (final battle in content.battles.values) {
        final engine = buildEngine(content, setupFor(content, battle.id), seed: 4);
        final result = playBattle(engine, (index) => index % 5 != 2, thinkSeconds: 2.5);
        expect(result.victory, isTrue, reason: battle.id);
        final limit = battle.stages.length > 2 ? 200 : (battle.isMultiStage ? 130 : 110);
        expect(result.durationSeconds, lessThan(limit), reason: battle.id);
        engine.dispose();
      }
    });

    test('always answering wrong ends in defeat (battles terminate)', () {
      for (final id in ['r1_n1', 'r1_n3', 'r2_n2', 'r1_boss', 'r1_n8']) {
        final engine = buildEngine(content, setupFor(content, id));
        final result = playBattle(engine, (_) => false);
        expect(result.victory, isFalse, reason: id);
        expect(engine.phase, BattlePhase.defeat);
        engine.dispose();
      }
    });

    test('bosses escalate through every phase; the finishing phase opens with the signature and grants a Special', () {
      final engine = buildEngine(content, setupFor(content, 'r1_boss'));
      final events = _record(engine);
      final result = playBattle(engine, (_) => true);
      expect(result.victory, isTrue);
      expect(events.whereType<StageChanged>().map((event) => event.stageIndex), [1, 2, 3]);
      expect(events.whereType<TurnStarted>().where((event) => event.move?.id == 'mirror_spell'), isNotEmpty);
      expect(events.whereType<TurnStarted>().where((event) => event.move?.id == 'protection'), isNotEmpty);
      expect(result.specialsUsed, greaterThanOrEqualTo(1));
    });

    test('first-time coaching is reported once per tutorial key', () {
      final engine = buildEngine(content, setupFor(content, 'r1_n1'));
      final result = playBattle(engine, (_) => true);
      expect(result.tutorialsSeen, containsAll(['attack', 'defence']));
      final again = buildEngine(content, BattleSetup(
        battle: content.battles['r1_n1']!,
        enemies: [content.enemies['goblin_scout']!],
        degrees: const DegreeRange(1, 1),
        config: content.combat,
        knownTutorials: result.tutorialsSeen,
      ));
      expect(playBattle(again, (_) => true).tutorialsSeen, isNot(contains('attack')));
    });

    test('abandoning keeps answered records for learning', () {
      final engine = buildEngine(content, setupFor(content, 'r1_n1'));
      engine.start();
      runUntilInput(engine);
      answerCorrectly(engine);
      final result = engine.abandon();
      expect(result.abandoned, isTrue);
      expect(result.records, hasLength(1));
    });
  });

  group('buffs and timers', () {
    BattleEngine critical(Map<BuffType, int> inventory) {
      final engine = buildEngine(
          content,
          _setup(content,
              inventory: inventory, hp: [999], config: _config(content, archetypes: {'goblin': const EnemyBehaviour(criticalChance: 1)})));
      engine.start();
      for (var i = 0; i < 3; i++) {
        runUntilInput(engine);
        answerCorrectly(engine);
      }
      runUntilInput(engine);
      expect(engine.snapshot.moveKind, MoveKind.critical);
      return engine;
    }

    test('hint dims one wrong option, once per challenge', () {
      final engine = critical({BuffType.hint: 2});
      expect(engine.useBuff(BuffType.hint), isTrue);
      expect(engine.snapshot.dimmedOptionIds, hasLength(1));
      expect(engine.useBuff(BuffType.hint), isFalse);
    });

    test('time freeze stops the critical timer; extra time adds seconds', () {
      final engine = critical({BuffType.timeFreeze: 1, BuffType.extraTime: 1});
      final before = engine.timerRemaining;
      expect(engine.useBuff(BuffType.extraTime), isTrue);
      expect(engine.timerRemaining, before + 5);
      expect(engine.useBuff(BuffType.timeFreeze), isTrue);
      engine.tick(0.1);
      expect(engine.timerRemaining, before + 5);
    });

    test('pausing stops the clock (no lost criticals during a phone call)', () {
      final engine = critical({});
      final remaining = engine.timerRemaining;
      engine.pause();
      for (var i = 0; i < 100; i++) {
        engine.tick(0.1);
      }
      expect(engine.timerRemaining, remaining);
      engine.resume();
      engine.tick(0.1);
      expect(engine.timerRemaining, lessThan(remaining));
    });

    test('ward blocks a failed critical defence', () {
      final engine = critical({BuffType.shield: 1});
      engine.useBuff(BuffType.shield);
      answerWrongly(engine);
      expect(engine.snapshot.playerHp, 100);
      expect(engine.snapshot.lastOutcome!.blockedByWard, isTrue);
    });

    test('second chance forgives one wrong answer', () {
      final engine = critical({BuffType.secondChance: 1});
      engine.useBuff(BuffType.secondChance);
      answerWrongly(engine);
      expect(engine.phase, BattlePhase.awaitingInput);
      answerCorrectly(engine);
      expect(engine.snapshot.playerHp, 100);
    });

    test('repeated failure silently adds time and a free hint', () {
      final engine = buildEngine(content, _setup(content, assist: const AssistPolicy().forFailures(2)));
      engine.start();
      runUntilInput(engine);
      expect(engine.buffCount(BuffType.hint), 1);
    });
  });
}
