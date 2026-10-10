import 'dart:io';
import 'dart:math';

import 'package:ustadia_user_app/features/word_forge/data/content_parser.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/battle_engine.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/battle_models.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/combat_config.dart';
import 'package:ustadia_user_app/features/word_forge/domain/content/word_forge_content.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/answer_validator.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/challenge_factory.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/challenge_type.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/word_selector.dart';

WordForgeContent? _cached;

/// Parses the real bundled content straight from disk.
WordForgeContent loadShippedContent() => _cached ??= const ContentParser().parse(ContentDocuments(
      words: File('assets/word_forge/content/words.json').readAsStringSync(),
      runes: File('assets/word_forge/content/runes.json').readAsStringSync(),
      incantations: File('assets/word_forge/content/incantations.json').readAsStringSync(),
      enemies: File('assets/word_forge/content/enemies.json').readAsStringSync(),
      battles: File('assets/word_forge/content/battles.json').readAsStringSync(),
      regions: File('assets/word_forge/content/regions.json').readAsStringSync(),
      combat: File('assets/word_forge/content/combat.json').readAsStringSync(),
    ));

BattleEngine buildEngine(
  WordForgeContent content,
  BattleSetup setup, {
  int seed = 1,
  WordStatsLookup stats = const EmptyWordStatsLookup(),
}) =>
    BattleEngine(
      setup: setup,
      factory: ChallengeFactory(),
      generation: GenerationContext(content: content, stats: stats, random: Random(seed)),
    );

BattleSetup setupFor(
  WordForgeContent content,
  String battleId, {
  CombatConfig? config,
  MechanicAccess access = MechanicAccess.all,
}) {
  final battle = content.battles[battleId]!;
  return BattleSetup(
    battle: battle,
    enemies: [for (final slot in battle.enemies) content.enemies[slot.enemyId]!],
    degrees: battle.degrees,
    config: config ?? content.combat,
    access: access,
  );
}

/// Advances time until the engine waits for input or the battle ends.
/// [thinkSeconds] simulates reading time once input is awaited.
void runUntilInput(BattleEngine engine, {double maxSeconds = 120}) {
  var elapsed = 0.0;
  while (engine.phase != BattlePhase.awaitingInput && !engine.isOver && elapsed < maxSeconds) {
    engine.tick(0.05);
    elapsed += 0.05;
  }
}

void think(BattleEngine engine, double seconds) {
  for (var t = 0.0; t < seconds && engine.phase == BattlePhase.awaitingInput; t += 0.05) {
    engine.tick(0.05);
  }
}

/// Answers the current task correctly.
void answerCorrectly(BattleEngine engine) {
  const validator = AnswerValidator();
  final challenge = engine.snapshot.challenge!;
  switch (challenge.inputMode) {
    case ChallengeInputMode.choice:
      engine.submitChoice(validator.correctOptionId(challenge)!);
    case ChallengeInputMode.arrange:
      var guard = 0;
      while (engine.phase == BattlePhase.awaitingInput && engine.snapshot.challenge == challenge && guard++ < 40) {
        final next = validator.nextCorrectOptionId(challenge, engine.snapshot.placedOptionIds);
        if (next == null) break;
        engine.placeToken(next);
      }
    case ChallengeInputMode.match:
      for (final entry in challenge.pairs.entries) {
        if (engine.phase != BattlePhase.awaitingInput || engine.snapshot.challenge != challenge) break;
        if (engine.snapshot.matchedOptionIds.contains(entry.key)) continue;
        engine.selectMatch(entry.key);
        engine.selectMatch(entry.value);
      }
  }
}

/// Answers the current task wrongly (and exhausts retries).
void answerWrongly(BattleEngine engine) {
  const validator = AnswerValidator();
  final challenge = engine.snapshot.challenge!;
  switch (challenge.inputMode) {
    case ChallengeInputMode.choice:
      final correct = validator.correctOptionId(challenge);
      final wrong = challenge.options.firstWhere((option) =>
          option.id != correct &&
          !engine.snapshot.dimmedOptionIds.contains(option.id) &&
          !engine.snapshot.hiddenOptionIds.contains(option.id));
      engine.submitChoice(wrong.id);
    case ChallengeInputMode.arrange:
      var guard = 0;
      while (engine.phase == BattlePhase.awaitingInput && engine.snapshot.challenge == challenge && guard++ < 10) {
        engine.clearTokens();
        final ids = challenge.options.map((option) => option.id).toList().reversed.toList();
        if (validator.isCorrectArrangement(challenge, ids)) ids.insert(0, ids.removeLast());
        for (final id in ids) {
          if (engine.phase != BattlePhase.awaitingInput || engine.snapshot.challenge != challenge) break;
          engine.placeToken(id);
        }
      }
    case ChallengeInputMode.match:
      final lefts = challenge.pairs.keys.toList();
      var guard = 0;
      while (engine.phase == BattlePhase.awaitingInput && engine.snapshot.challenge == challenge && guard++ < 10) {
        final left = lefts[guard % lefts.length];
        final wrongRight = challenge.pairs.values.firstWhere((right) => right != challenge.pairs[left]);
        engine.selectMatch(left);
        engine.selectMatch(wrongRight);
      }
  }
}

/// Plays a whole battle. [correctAt] decides each answer by task index;
/// [useSpecial] casts whenever a spell is castable, picking the spell
/// returned by [chooseSpell]; a chooser returning null keeps the mana for
/// later. Without a chooser the first castable spell is cast.
BattleResult playBattle(
  BattleEngine engine,
  bool Function(int index) correctAt, {
  int maxTasks = 300,
  bool useSpecial = true,
  double thinkSeconds = 0,
  String? Function(BattleEngine engine)? chooseSpell,
}) {
  engine.start();
  var index = 0;
  while (!engine.isOver && index < maxTasks) {
    runUntilInput(engine);
    if (engine.isOver) break;
    if (useSpecial && engine.canActivateSpecial) {
      final id = chooseSpell?.call(engine);
      if ((chooseSpell == null || id != null) && engine.activateSpecial(id)) continue;
    }
    if (thinkSeconds > 0) think(engine, thinkSeconds);
    if (engine.phase != BattlePhase.awaitingInput) continue;
    if (correctAt(index)) {
      answerCorrectly(engine);
    } else {
      answerWrongly(engine);
    }
    index++;
  }
  runUntilInput(engine);
  return engine.result ?? engine.abandon();
}
