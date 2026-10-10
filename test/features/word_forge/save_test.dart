import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustadia_user_app/features/word_forge/data/local_word_forge_save_repository.dart';
import 'package:ustadia_user_app/features/word_forge/domain/language/challenge_type.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/buffs.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/upgrades.dart';
import 'package:ustadia_user_app/features/word_forge/domain/progression/word_mastery.dart';
import 'package:ustadia_user_app/features/word_forge/domain/save/save_codec.dart';
import 'package:ustadia_user_app/features/word_forge/domain/save/word_forge_save.dart';

WordForgeSave _sample({int slot = 1, String player = 'player-42', String character = 'female_apprentice', int xp = 345}) =>
    WordForgeSave.fresh(player, slotIndex: slot, characterId: character, saveId: 'abc$slot', nowMs: 1000).copyWith(
      xp: xp,
      upgrades: const UpgradeLevels({UpgradeType.focus: 2}),
      buffs: const {BuffType.hint: 3, BuffType.shield: 1},
      currentRegionId: 'whispering_forest',
      lastNodeId: 'r1_boss',
      nodes: const {
        'r1_n1': NodeProgress(completed: true, bestStars: 3, bestScore: 900, attempts: 2, wins: 1),
        'r1_m1': NodeProgress(mysteryOutcome: 1),
      },
      unlockedNodeIds: const {'r1_n2', 'r2_n1'},
      words: {
        'hot': const WordStats().record(isCorrect: true, type: ChallengeType.antonym, battleIndex: 1, responseMs: 1500),
      },
      battleCount: 4,
      battleWins: 3,
      battlesSinceWard: 1,
      tutorialFlags: const {'attack', 'defence'},
      recentContentKeys: const ['rune_001'],
      settings: const WordForgeSettings(muted: true),
      spells: const ['guardian_ward'],
    );

void main() {
  const codec = SaveCodec();

  group('SaveCodec', () {
    test('round-trips every persisted field including slot metadata and character', () {
      final save = _sample(slot: 2);
      final decoded = codec.decode(codec.encode(save))!;
      expect(decoded, save);
      expect(decoded.slotIndex, 2);
      expect(decoded.characterId, 'female_apprentice');
      expect(decoded.saveId, 'abc2');
      expect(decoded.createdAtMs, 1000);
      expect(decoded.tutorialFlags, {'attack', 'defence'});
      expect(decoded.words['hot']!.averageResponseSeconds, 1.5);
      expect(decoded.spells, ['guardian_ward']);
    });

    test('migrates v2 saves (before spells) to the current version with no spells', () {
      final v2 = jsonEncode({'version': 2, 'playerId': 'p', 'slot': 2, 'xp': 90, 'character': 'female_apprentice'});
      final decoded = codec.decode(v2)!;
      expect(decoded.version, WordForgeSave.currentVersion);
      expect(decoded.spells, isEmpty);
      expect(decoded.slotIndex, 2);
      expect(decoded.characterId, 'female_apprentice');
    });

    test('migrates v3 saves (free spells) to v4: spells now cost a skill point, cleared nodes stay', () {
      final v3 = jsonEncode({
        'version': 3,
        'playerId': 'p',
        'xp': 500,
        'spells': ['guardian_ward'],
        'nodes': {'r1_boss': {'c': true, 'w': 1}},
      });
      final decoded = codec.decode(v3)!;
      expect(decoded.version, 4);
      expect(decoded.spells, isEmpty);
      expect(decoded.isCompleted('r1_boss'), isTrue);
      expect(decoded.xp, 500);
    });

    test('returns null for missing or corrupt data', () {
      expect(codec.decode(null), isNull);
      expect(codec.decode(''), isNull);
      expect(codec.decode('{"version": 2, "xp": '), isNull);
      expect(codec.decode('[1, 2, 3]'), isNull);
    });

    test('migrates first-version saves (v1) to slots, tutorials and wins', () {
      final v1 = jsonEncode({
        'version': 1,
        'playerId': 'p',
        'xp': 50,
        'introduced': ['antonym', 'synonym', 'missingRune'],
        'nodes': {
          'r1_n1': {'c': true, 'w': 1},
          'r1_n2': {'c': true, 'w': 2},
          'r1_n3': {'c': false, 'w': 0},
        },
      });
      final decoded = codec.decode(v1)!;
      expect(decoded.version, WordForgeSave.currentVersion);
      expect(decoded.slotIndex, 1);
      expect(decoded.characterId, isNull, reason: 'asked once on next load');
      expect(decoded.tutorialFlags, {'defence', 'attack'});
      expect(decoded.battleWins, 2);
      expect(decoded.xp, 50);
    });

    test('reads saves from a newer version best-effort', () {
      final json = jsonDecode(codec.encode(_sample())) as Map<String, dynamic>;
      final future = jsonEncode({...json, 'version': 99, 'newFeature': {'x': 1}});
      expect(codec.decode(future)!.xp, 345);
    });

    test('a single corrupt entry does not lose the whole save', () {
      final json = jsonDecode(codec.encode(_sample())) as Map<String, dynamic>;
      (json['nodes'] as Map)['broken'] = 'not a map';
      final decoded = codec.decode(jsonEncode(json))!;
      expect(decoded.isCompleted('r1_n1'), isTrue);
      expect(decoded.nodes.containsKey('broken'), isFalse);
    });
  });

  group('LocalWordForgeSaveRepository (three slots)', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    Future<LocalWordForgeSaveRepository> repository() async =>
        LocalWordForgeSaveRepository(preferences: await SharedPreferences.getInstance());

    test('starts with three empty slots', () async {
      final slots = await (await repository()).listSlots('p');
      expect(slots.map((slot) => slot.index), [1, 2, 3]);
      expect(slots.every((slot) => slot.isEmpty), isTrue);
    });

    test('create, load and keep slots isolated', () async {
      final repo = await repository();
      await repo.save(_sample(slot: 1, xp: 100, character: 'male_apprentice'));
      await repo.save(_sample(slot: 3, xp: 900));
      final slots = await repo.listSlots('player-42');
      expect(slots[0].save!.xp, 100);
      expect(slots[0].save!.characterId, 'male_apprentice');
      expect(slots[1].isEmpty, isTrue);
      expect(slots[2].save!.xp, 900);
      expect(slots[2].save!.characterId, 'female_apprentice');
      expect((await repo.loadSlot('player-42', 3))!.xp, 900);
    });

    test('slots are separate per profile', () async {
      final repo = await repository();
      await repo.save(_sample(slot: 1, player: 'alice'));
      expect((await repo.listSlots('bob')).every((slot) => slot.isEmpty), isTrue);
    });

    test('remembers the most recently played slot for Continue', () async {
      final repo = await repository();
      await repo.save(_sample(slot: 1));
      await repo.save(_sample(slot: 2));
      expect(await repo.lastPlayedSlot('player-42'), 2);
      await repo.save(_sample(slot: 1, xp: 1));
      expect(await repo.lastPlayedSlot('player-42'), 1);
    });

    test('overwriting a slot replaces only that slot', () async {
      final repo = await repository();
      await repo.save(_sample(slot: 1, xp: 500));
      await repo.save(_sample(slot: 2, xp: 700));
      await repo.save(WordForgeSave.fresh('player-42', slotIndex: 1, characterId: 'male_apprentice'));
      final slots = await repo.listSlots('player-42');
      expect(slots[0].save!.xp, 0);
      expect(slots[1].save!.xp, 700);
    });

    test('a corrupted slot falls back to its backup, or is isolated without touching others', () async {
      final preferences = await SharedPreferences.getInstance();
      final repo = LocalWordForgeSaveRepository(preferences: preferences);
      await repo.save(_sample(slot: 1, xp: 10));
      await repo.save(_sample(slot: 1, xp: 20));
      await repo.save(_sample(slot: 2, xp: 30));
      await preferences.setString(LocalWordForgeSaveRepository.slotKey('player-42', 1), '{broken');
      var slots = await repo.listSlots('player-42');
      expect(slots[0].save!.xp, 10, reason: 'recovered from backup');

      await preferences.setString(LocalWordForgeSaveRepository.slotKey('player-42', 3), 'garbage');
      slots = await repo.listSlots('player-42');
      expect(slots[2].corrupted, isTrue);
      expect(slots[2].save, isNull);
      expect(slots[1].save!.xp, 30);
      expect(preferences.getString(LocalWordForgeSaveRepository.corruptKey('player-42', 3)), 'garbage');
    });

    test('moves a first-version single save into slot 1', () async {
      SharedPreferences.setMockInitialValues({
        LocalWordForgeSaveRepository.legacyKey('p'): jsonEncode({'version': 1, 'playerId': 'p', 'xp': 77}),
      });
      final repo = await repository();
      final slots = await repo.listSlots('p');
      expect(slots[0].save!.xp, 77);
      expect(await repo.lastPlayedSlot('p'), 1);
      expect((await SharedPreferences.getInstance()).getString(LocalWordForgeSaveRepository.legacyKey('p')), isNull);
    });

    test('deleting a slot clears it', () async {
      final repo = await repository();
      await repo.save(_sample(slot: 2));
      await repo.deleteSlot('player-42', 2);
      expect((await repo.listSlots('player-42'))[1].isEmpty, isTrue);
    });
  });
}
