// Balance simulation: plays every shipped battle many times without UI with
// three player profiles and prints a compact report.
//
//   WF_BALANCE_REPORT=1 flutter test test/features/word_forge/balance_report_test.dart
//
// Without the flag only the regression assertions run (fast).
import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/combat_config.dart';
import 'package:ustadia_user_app/features/word_forge/domain/content/region_definition.dart';
import 'package:ustadia_user_app/features/word_forge/domain/content/word_forge_content.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/battle_assist.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/battle_engine.dart';
import 'package:ustadia_user_app/features/word_forge/domain/battle/battle_models.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/player_level.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/upgrades.dart';
import 'package:ustadia_user_app/features/word_forge/domain/sandbox/sandbox_progression.dart';
import 'package:ustadia_user_app/features/word_forge/domain/save/word_forge_save.dart';

import 'helpers.dart';

/// A simulated learner: answer accuracy and reading/answer time.
class Profile {
  final String name;
  final double accuracy;
  final double thinkSeconds;

  /// Consecutive losses before this attempt (drives silent assistance).
  final int failures;

  const Profile(this.name, this.accuracy, this.thinkSeconds, {this.failures = 0});
}

const profiles = [
  Profile('strong', 0.93, 2.2),
  Profile('average', 0.76, 3.6),
  Profile('struggling', 0.55, 5.4),
  // Same learner on a third attempt: one option fewer lifts guessing odds.
  Profile('strug-retry', 0.62, 5.4, failures: 3),
];

/// Exploit probe: taps a random answer almost instantly (25% accuracy).
const masher = Profile('masher', 0.25, 0.4);

/// Exploit probe: never answers, lets every timer run out (no counters).
const waiter = Profile('waiter', 0.0, 60);

class Sample {
  final bool victory;
  final double seconds;
  final int playerTurns;
  final int specials;
  final int criticals;
  final int timeouts;
  final double hpLeft;
  final int damageTaken;
  final int stars;
  final List<String> spells;
  final List<String> fizzled;
  final int manaSpent;
  final int manaGained;
  final int manaLeft;

  /// Attack turns on which each spell was castable, and times it was picked.
  final Map<String, int> opportunities;
  final Map<String, int> picks;

  Sample({
    required this.victory,
    required this.seconds,
    required this.playerTurns,
    required this.specials,
    required this.criticals,
    required this.timeouts,
    required this.hpLeft,
    required this.damageTaken,
    required this.stars,
    this.spells = const [],
    this.fizzled = const [],
    this.manaSpent = 0,
    this.manaGained = 0,
    this.manaLeft = 0,
    this.opportunities = const {},
    this.picks = const {},
  });
}

/// How a simulated player decides which spell to cast (null = keep mana).
typedef SpellPolicy = String? Function(BattleEngine engine);

/// A sensible player: ward when hurt or threatened, bind a telegraphed big
/// move, poison anything durable, otherwise burst.
String? smartPolicy(BattleEngine engine) {
  final s = engine.snapshot;
  bool can(String id) => engine.canCast(id);
  final target = s.target;
  final threat = s.enemies.any((e) => e.alive && e.intent != null && e.intent != MoveKind.normal);
  if (can('guardian_ward') && s.wardCharges == 0 && (s.playerHpFraction < 0.6 || threat)) return 'guardian_ward';
  if (can('rune_bind') && threat) return 'rune_bind';
  if (can('thorn_blight') && target != null && !target.poisoned && target.hp > 45) return 'thorn_blight';
  if (can('apprentice_incantation')) return 'apprentice_incantation';
  if (can('rune_bind') && target != null && target.hp > 30) return 'rune_bind';
  if (can('thorn_blight') && target != null && !target.poisoned && target.hp > 30) return 'thorn_blight';
  return null;
}

String? _preferring(String id, BattleEngine engine) => engine.canCast(id) ? id : smartPolicy(engine);

final Map<String, SpellPolicy> builds = {
  'smart': smartPolicy,
  'damage-first': (engine) => _preferring('apprentice_incantation', engine),
  'defence-first': (engine) =>
      engine.canCast('guardian_ward') && engine.snapshot.wardCharges == 0 ? 'guardian_ward' : smartPolicy(engine),
  'control-first': (engine) => _preferring('rune_bind', engine),
  'poison-first': (engine) => _preferring('thorn_blight', engine),
  'spam-burst': (engine) => engine.canCast('apprentice_incantation') ? 'apprentice_incantation' : null,
  'hoard-mana': (engine) => engine.mana >= engine.manaMax ? smartPolicy(engine) : null,
  'never-cast': (_) => null,
};

/// Backwards-compatible name used by the regression assertions.
String? pickSpell(BattleEngine engine) => smartPolicy(engine);

/// Spells a player realistically owns when reaching [battleId] (taught by
/// earlier main-path nodes).
List<String> spellsAt(WordForgeContent content, String battleId) {
  final spells = [content.combat.playerSpecial];
  for (final region in content.regions) {
    for (final node in region.nodes) {
      if (node.battleId == battleId) return spells;
      if (node.teaches != null) spells.add(node.teaches!);
    }
  }
  return spells;
}

Sample simulate(
  WordForgeContent content,
  String battleId,
  Profile profile,
  int seed, {
  int wins = 10,
  SpellPolicy? policy,
  List<String>? spells,
  UpgradeLevels upgrades = const UpgradeLevels(),
  bool startWithWard = false,
}) {
  final random = Random(seed * 7919 + profile.name.hashCode);
  final base = setupFor(content, battleId, access: content.combat.gates.forWins(wins));
  final setup = BattleSetup(
    battle: base.battle,
    enemies: base.enemies,
    enemyHp: base.enemyHp,
    degrees: base.degrees,
    config: base.config,
    access: base.access,
    assist: const AssistPolicy().forFailures(profile.failures),
    upgrades: upgrades,
    startWithWard: startWithWard,
    spells: spells ?? spellsAt(content, battleId),
  );
  final engine = buildEngine(content, setup, seed: seed);
  final opportunities = <String, int>{};
  final picks = <String, int>{};
  final chooser = policy ?? smartPolicy;
  final result = playBattle(
    engine,
    (_) => random.nextDouble() < profile.accuracy,
    thinkSeconds: profile.thinkSeconds,
    maxTasks: 400,
    chooseSpell: (engine) {
      for (final spell in engine.snapshot.spells) {
        if (spell.castable) opportunities[spell.id] = (opportunities[spell.id] ?? 0) + 1;
      }
      final chosen = chooser(engine);
      if (chosen != null) picks[chosen] = (picks[chosen] ?? 0) + 1;
      return chosen;
    },
  );
  final playerTurns = result.records.where((r) => r.turn == BattleTurn.player && r.kind == MoveKind.normal).length;
  return Sample(
    victory: result.victory,
    seconds: result.durationSeconds,
    playerTurns: playerTurns,
    specials: result.specialsUsed,
    criticals: result.criticalsLanded,
    timeouts: result.records.where((r) => r.timedOut).length,
    hpLeft: result.playerHpFraction,
    damageTaken: result.damageTaken,
    stars: const SandboxProgression().starRating.starsFor(result, turnBudget: const SandboxProgression().turnBudgetFor(content, setup)),
    spells: result.spellsUsed,
    fizzled: result.spellsFizzled,
    manaSpent: result.manaSpent,
    manaGained: result.manaGained,
    manaLeft: engine.mana,
    opportunities: opportunities,
    picks: picks,
  );
}

String _f(double v, [int d = 1]) => v.toStringAsFixed(d);

void main() {
  final content = loadShippedContent();
  final report = Platform.environment['WF_BALANCE_REPORT'] == '1';
  final runs = report ? 24 : 6;

  group('balance simulation', () {
    test('report', () {
      final buffer = StringBuffer();
      final byType = <String, Map<String, List<Sample>>>{};
      for (final region in content.regions) {
        for (final node in region.nodes) {
          final battleId = node.battleId;
          if (battleId == null || !content.battles.containsKey(battleId)) continue;
          final rows = <String>[];
          for (final profile in profiles) {
            final samples = [for (var i = 0; i < runs; i++) simulate(content, battleId, profile, i + 1)];
            byType.putIfAbsent(node.type.name, () => {}).putIfAbsent(profile.name, () => []).addAll(samples);
            final winRate = samples.where((s) => s.victory).length / samples.length;
            double avg(double Function(Sample) f) => samples.map(f).reduce((a, b) => a + b) / samples.length;
            rows.add('${profile.name.padRight(10)} win ${_f(winRate * 100, 0).padLeft(3)}%  '
                't ${_f(avg((s) => s.seconds), 0).padLeft(3)}s  turns ${_f(avg((s) => s.playerTurns.toDouble())).padLeft(4)}  '
                'spec ${_f(avg((s) => s.specials.toDouble()))}  fizz ${_f(avg((s) => s.fizzled.length.toDouble()))}  '
                'mana ${_f(avg((s) => s.manaSpent.toDouble()), 0).padLeft(3)}/${_f(avg((s) => s.manaLeft.toDouble()), 0).padLeft(2)}  '
                'crit ${_f(avg((s) => s.criticals.toDouble()))}  '
                'tout ${_f(avg((s) => s.timeouts.toDouble()))}  hp ${_f(avg((s) => s.hpLeft) * 100, 0).padLeft(3)}%  '
                'stars ${_f(avg((s) => s.stars.toDouble()))}');
          }
          if (report) {
            final enemies = content.battles[battleId]!.enemies.map((e) => e.enemyId).join('+');
            buffer.writeln('${node.id.padRight(9)} ${node.type.name.padRight(9)} $enemies');
            for (final row in rows) {
              buffer.writeln('   $row');
            }
          }
        }
      }
      if (report) {
        final spellUse = <String, int>{};
        final spellFizzle = <String, int>{};
        final opportunities = <String, int>{};
        final picks = <String, int>{};
        for (final byProfile in byType.values) {
          for (final samples in byProfile.values) {
            for (final sample in samples) {
              for (final id in sample.spells) {
                spellUse[id] = (spellUse[id] ?? 0) + 1;
              }
              for (final id in sample.fizzled) {
                spellFizzle[id] = (spellFizzle[id] ?? 0) + 1;
              }
              for (final entry in sample.opportunities.entries) {
                opportunities[entry.key] = (opportunities[entry.key] ?? 0) + entry.value;
              }
              for (final entry in sample.picks.entries) {
                picks[entry.key] = (picks[entry.key] ?? 0) + entry.value;
              }
            }
          }
        }
        buffer.writeln('\nSPELL USE (all profiles, all battles; picked / castable opportunities)');
        for (final id in content.combat.allSpecials) {
          final opp = opportunities[id] ?? 0;
          final pick = picks[id] ?? 0;
          final casts = spellUse[id] ?? 0;
          final fizz = spellFizzle[id] ?? 0;
          buffer.writeln('${id.padRight(24)} casts ${casts.toString().padLeft(5)}  fizzled ${_f(casts == 0 ? 0 : fizz / casts * 100, 0).padLeft(3)}%  '
              'picked when castable ${_f(opp == 0 ? 0 : pick / opp * 100, 0).padLeft(3)}%  (opportunities $opp)');
        }
        buffer.writeln('\nBY NODE TYPE');
        for (final entry in byType.entries) {
          for (final p in entry.value.entries) {
            final s = p.value;
            final win = s.where((x) => x.victory).length / s.length;
            final t = s.map((x) => x.seconds).reduce((a, b) => a + b) / s.length;
            final spec = s.map((x) => x.specials).reduce((a, b) => a + b) / s.length;
            final crit = s.map((x) => x.criticals).reduce((a, b) => a + b) / s.length;
            final hp = s.map((x) => x.hpLeft).reduce((a, b) => a + b) / s.length;
            final three = s.where((x) => x.stars == 3).length / s.length;
            final two = s.where((x) => x.stars == 2).length / s.length;
            final one = s.where((x) => x.stars == 1).length / s.length;
            final mana = s.map((x) => x.manaSpent).reduce((a, b) => a + b) / s.length;
            final fizz = s.map((x) => x.fizzled.length).reduce((a, b) => a + b) / s.length;
            buffer.writeln('${entry.key.padRight(9)} ${p.key.padRight(10)} win ${_f(win * 100, 0)}%  t ${_f(t, 0)}s  '
                'spec ${_f(spec)}  fizz ${_f(fizz)}  mana ${_f(mana, 0)}  crit ${_f(crit)}  hp ${_f(hp * 100, 0)}%  '
                'stars 1/2/3 ${_f(one * 100, 0)}/${_f(two * 100, 0)}/${_f(three * 100, 0)}%');
          }
        }
        // Builds: the same average player with every spell known and a fixed policy.
        buffer.writeln('\nBUILDS (average player, all spells known)');
        for (final id in ['r1_boss', 'r2_mb', 'r2_boss', 'r3_e2', 'r3_boss']) {
          for (final build in builds.entries) {
            final samples = [
              for (var i = 0; i < runs; i++)
                simulate(content, id, profiles[1], i + 1, wins: 30, policy: build.value, spells: content.combat.allSpecials),
            ];
            final win = samples.where((s) => s.victory).length / samples.length;
            final hp = samples.map((s) => s.hpLeft).reduce((a, b) => a + b) / samples.length;
            final t = samples.map((s) => s.seconds).reduce((a, b) => a + b) / samples.length;
            final spec = samples.map((s) => s.specials).reduce((a, b) => a + b) / samples.length;
            final turns = samples.map((s) => s.playerTurns).reduce((a, b) => a + b) / samples.length;
            buffer.writeln('${id.padRight(9)} ${build.key.padRight(14)} win ${_f(win * 100, 0).padLeft(3)}%  hp ${_f(hp * 100, 0).padLeft(3)}%  '
                't ${_f(t, 0).padLeft(3)}s  turns ${_f(turns)}  spec ${_f(spec)}');
          }
        }
        // Exploit probe: can random fast tapping brute-force fights?
        buffer.writeln('\nMASHER (25% accuracy, 0.4 s per answer) / WAITER (lets every timer expire)');
        for (final id in ['r1_n1', 'r1_n3', 'r1_mb', 'r1_boss', 'r2_n4', 'r3_n6', 'r3_boss']) {
          for (final probe in [masher, waiter]) {
            final samples = [for (var i = 0; i < runs; i++) simulate(content, id, probe, i + 1)];
            final win = samples.where((s) => s.victory).length / samples.length;
            final t = samples.map((s) => s.seconds).reduce((a, b) => a + b) / samples.length;
            final spec = samples.map((s) => s.specials).reduce((a, b) => a + b) / samples.length;
            buffer.writeln('${id.padRight(9)} ${probe.name.padRight(7)} win ${_f(win * 100, 0).padLeft(3)}%  t ${_f(t, 0).padLeft(3)}s  spec ${_f(spec)}');
          }
        }
        // Builds: the same average player with every upgrade maxed.
        buffer.writeln('\nUPGRADES (average player, no upgrades vs all maxed)');
        for (final id in ['r1_boss', 'r2_mb', 'r3_e2', 'r3_boss']) {
          for (final maxed in [false, true]) {
            final samples = [
              for (var i = 0; i < runs; i++)
                simulate(
                  content,
                  id,
                  profiles[1],
                  i + 1,
                  wins: 30,
                  spells: content.combat.allSpecials,
                  startWithWard: maxed,
                  upgrades: maxed
                      ? const UpgradeLevels({UpgradeType.focus: 3, UpgradeType.insight: 2, UpgradeType.protection: 3, UpgradeType.momentum: 3})
                      : const UpgradeLevels(),
                ),
            ];
            final win = samples.where((s) => s.victory).length / samples.length;
            final hp = samples.map((s) => s.hpLeft).reduce((a, b) => a + b) / samples.length;
            final t = samples.map((s) => s.seconds).reduce((a, b) => a + b) / samples.length;
            buffer.writeln('${id.padRight(9)} ${maxed ? 'maxed  ' : 'none   '} win ${_f(win * 100, 0)}%  hp ${_f(hp * 100, 0)}%  t ${_f(t, 0)}s');
          }
        }
        // Progression curve: an average player clears the main path once.
        buffer.writeln('\nPROGRESSION (average player, first clears in map order)');
        var save = WordForgeSave.fresh('sim');
        const progression = SandboxProgression();
        for (final region in content.regions) {
          for (final node in region.nodes) {
            if (node.battleId == null) {
              if (node.type == MapNodeType.bonus || node.type == MapNodeType.recovery) {
                save = progression.claimNode(content: content, save: save, node: node).save;
              }
              continue;
            }
            final setup = progression.buildSetup(content: content, save: save, node: node);
            if (setup == null) continue;
            final random = Random(node.id.hashCode);
            final engine = buildEngine(content, setup, seed: 3);
            final result = playBattle(engine, (_) => random.nextDouble() < 0.76, thinkSeconds: 3.6, maxTasks: 400, chooseSpell: pickSpell);
            final applied = progression.applyBattle(content: content, save: save, node: node, result: result);
            save = applied.save;
            // Spends points the way a curious player would: a newly witnessed
            // spell first, otherwise the next passive in a fixed order.
            var learned = '';
            for (final id in content.combat.learnableSpecials) {
              final next = progression.learnSpell(content, save, id);
              if (next != null) {
                save = next;
                learned = ' learned $id';
              }
            }
            for (final type in [UpgradeType.focus, UpgradeType.momentum, UpgradeType.insight, UpgradeType.protection]) {
              final next = progression.purchaseUpgrade(save, type);
              if (next != null) {
                save = next;
                learned += ' +${type.name}';
              }
            }
            final level = PlayerLevel.fromXp(save.xp);
            buffer.writeln('${node.id.padRight(9)} ${result.victory ? 'W' : 'L'} ${applied.summary.stars}★ '
                '+${applied.summary.xpGained.toString().padLeft(3)}xp  lvl ${level.level.toString().padLeft(2)}  '
                't ${_f(result.durationSeconds, 0)}s  hp ${_f(result.playerHpFraction * 100, 0)}%  '
                'spells ${setup.spells.length}  wins ${save.battleWins}$learned');
          }
        }
        // ignore: avoid_print
        print(buffer);
      }
    }, timeout: const Timeout(Duration(minutes: 10)));
  });
}
