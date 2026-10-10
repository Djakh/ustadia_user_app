import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ustadia_user_app/features/word_forge/word_forge.dart';
import 'package:ustadia_user_app/features/word_forge/domain/save/word_forge_save.dart';

/// In-memory server with the backend's rules: revision per slot, 409 with the
/// server copy, `null` copy when the slot does not exist.
class FakeCloud implements WordForgeCloud {
  final Map<int, CloudSave> slots = {};
  bool offline = false;
  bool dropNextPutResponse = false;
  final List<int> putBases = [];
  final List<(int, int)> deletes = [];

  void _check() {
    if (offline) throw const WordForgeCloudUnavailable('offline');
  }

  @override
  Future<CloudSlotList> listSlots() async {
    _check();
    final sorted = slots.values.toList()..sort((a, b) => a.slot.compareTo(b.slot));
    return CloudSlotList(slots: [
      for (final save in sorted)
        CloudSlotSummary(
          slot: save.slot,
          revision: save.revision,
          schemaVersion: save.schemaVersion,
          lastPlayedAt: save.data['lastPlayedAt'] as int?,
        ),
    ]);
  }

  @override
  Future<CloudSave?> getSlot(int slot) async {
    _check();
    return slots[slot];
  }

  @override
  Future<CloudWriteResult> putSlot(int slot, CloudWrite write) async {
    _check();
    putBases.add(write.baseRevision);
    final current = slots[slot];
    final matches = current == null ? write.baseRevision == 0 : write.baseRevision == current.revision;
    if (!matches) return CloudWriteConflict(current);
    final saved = CloudSave(
      slot: slot,
      revision: (current?.revision ?? 0) + 1,
      schemaVersion: write.schemaVersion,
      contentHash: write.contentHash,
      data: Map<String, dynamic>.from(jsonDecode(jsonEncode(write.data)) as Map),
    );
    slots[slot] = saved;
    if (dropNextPutResponse) {
      dropNextPutResponse = false;
      throw const WordForgeCloudUnavailable('timeout after the write landed');
    }
    return CloudWriteSaved(saved.revision);
  }

  @override
  Future<CloudDeleteResult> deleteSlot(int slot, int revision) async {
    _check();
    deletes.add((slot, revision));
    final current = slots[slot];
    if (current == null) return CloudDeleteResult.notFound;
    if (current.revision != revision) return CloudDeleteResult.conflict;
    slots.remove(slot);
    return CloudDeleteResult.deleted;
  }

  /// Another device wrote this slot directly on the server.
  void writeFromOtherDevice(WordForgeSave save) {
    final current = slots[save.slotIndex];
    slots[save.slotIndex] = CloudSave(
      slot: save.slotIndex,
      revision: (current?.revision ?? 0) + 1,
      schemaVersion: save.version,
      contentHash: 'other-device-${save.lastPlayedAtMs}',
      data: save.toJson(),
    );
  }
}

/// A cloud that must never be called.
class ForbiddenCloud implements WordForgeCloud {
  @override
  Future<CloudSlotList> listSlots() => throw StateError('cloud used');
  @override
  Future<CloudSave?> getSlot(int slot) => throw StateError('cloud used');
  @override
  Future<CloudWriteResult> putSlot(int slot, CloudWrite write) => throw StateError('cloud used');
  @override
  Future<CloudDeleteResult> deleteSlot(int slot, int revision) => throw StateError('cloud used');
}

const _profile = 'student-1';

WordForgeSave _save({int slot = 1, int xp = 0, int playedAt = 1000, String saveId = 'game-a'}) =>
    WordForgeSave.fresh(_profile, slotIndex: slot, characterId: 'female_apprentice', saveId: saveId, nowMs: 1)
        .copyWith(xp: xp, lastPlayedAtMs: playedAt);

Future<SyncedWordForgeSaveRepository> _device(WordForgeCloud cloud, {bool canSync = true}) async {
  // Each call = a separate phone (its own storage).
  SharedPreferences.setMockInitialValues({});
  final preferences = await SharedPreferences.getInstance();
  return SyncedWordForgeSaveRepository(
    local: LocalWordForgeSaveRepository(preferences: preferences),
    cloud: cloud,
    preferences: preferences,
    canSync: (_) => canSync,
  );
}

void main() {
  group('Word Forge cloud sync', () {
    test('first sync uploads saves that exist only on the phone, once', () async {
      final cloud = FakeCloud()..offline = true;
      final phone = await _device(cloud);
      await phone.save(_save(xp: 120));
      await phone.save(_save(slot: 3, xp: 40, saveId: 'game-c'));
      await phone.flush();
      expect(cloud.slots, isEmpty, reason: 'offline: nothing uploaded, nothing lost');

      cloud.offline = false;
      final slots = await phone.listSlots(_profile);
      expect(slots.where((s) => s.save != null).map((s) => s.index), [1, 3]);
      expect(cloud.slots.keys, unorderedEquals([1, 3]));
      expect(cloud.putBases, [0, 0], reason: 'created with baseRevision 0');
      expect(cloud.slots[1]!.data['xp'], 120);

      await phone.listSlots(_profile);
      expect(cloud.putBases, hasLength(2), reason: 'nothing changed, nothing re-uploaded');
    });

    test('a reinstalled app or a new phone gets its progress back from the server', () async {
      final cloud = FakeCloud();
      final oldPhone = await _device(cloud);
      await oldPhone.save(_save(slot: 2, xp: 900, playedAt: 5000, saveId: 'game-b'));
      await oldPhone.save(_save(slot: 1, xp: 300, playedAt: 2000));
      await oldPhone.flush();

      final newPhone = await _device(cloud);
      final slots = await newPhone.listSlots(_profile);
      expect(slots.firstWhere((s) => s.index == 2).save!.xp, 900);
      expect(slots.firstWhere((s) => s.index == 1).save!.xp, 300);
      expect(await newPhone.lastPlayedSlot(_profile), 2, reason: 'Continue opens the slot played last');

      // Playing on afterwards uploads on top of the downloaded revision.
      await newPhone.save(_save(slot: 2, xp: 950, playedAt: 6000, saveId: 'game-b'));
      await newPhone.flush();
      expect(cloud.putBases.last, 1);
      expect(cloud.slots[2]!.revision, 2);
      expect(cloud.slots[2]!.data['xp'], 950);
    });

    test('every checkpoint uploads the newest copy with the last known revision', () async {
      final cloud = FakeCloud();
      final phone = await _device(cloud);
      await phone.save(_save(xp: 10, playedAt: 1000));
      await phone.flush();
      await phone.save(_save(xp: 20, playedAt: 2000));
      await phone.save(_save(xp: 30, playedAt: 3000));
      await phone.flush();
      expect(cloud.slots[1]!.data['xp'], 30);
      expect(cloud.putBases.first, 0);
      expect(cloud.putBases.skip(1).toSet(), isNot(contains(0)), reason: 'later writes carry the revision');
      expect(cloud.putBases.length, lessThanOrEqualTo(3));
    });

    test('a lost response is recognised by its hash: no duplicate write, revision adopted', () async {
      final cloud = FakeCloud();
      final phone = await _device(cloud);
      await phone.save(_save(xp: 10));
      await phone.flush();
      cloud.dropNextPutResponse = true;
      await phone.save(_save(xp: 20, playedAt: 2000));
      await phone.flush();
      expect(cloud.slots[1]!.revision, 2, reason: 'the write landed, the answer did not');
      final writes = cloud.putBases.length;

      await phone.listSlots(_profile);
      expect(cloud.putBases.length, writes, reason: 'own write recognised, nothing re-sent');
      await phone.save(_save(xp: 30, playedAt: 3000));
      await phone.flush();
      expect(cloud.putBases.last, 2, reason: 'the adopted revision is used next');
      expect(cloud.slots[1]!.revision, 3);
    });

    test('conflict: progress played more recently on another device wins', () async {
      final cloud = FakeCloud();
      final phone = await _device(cloud);
      await phone.save(_save(xp: 100, playedAt: 1000));
      await phone.flush();

      cloud.writeFromOtherDevice(_save(xp: 500, playedAt: 3000));
      cloud.offline = true;
      await phone.save(_save(xp: 150, playedAt: 2000)); // older than the other device's game
      await phone.flush();
      cloud.offline = false;

      final slots = await phone.listSlots(_profile);
      expect(slots.first.save!.xp, 500);
      expect(cloud.slots[1]!.data['xp'], 500, reason: 'server copy kept');
    });

    test('conflict: progress played more recently on this phone wins', () async {
      final cloud = FakeCloud();
      final phone = await _device(cloud);
      await phone.save(_save(xp: 100, playedAt: 1000));
      await phone.flush();

      cloud.writeFromOtherDevice(_save(xp: 500, playedAt: 3000));
      await phone.save(_save(xp: 700, playedAt: 4000));
      await phone.flush();

      expect(cloud.slots[1]!.data['xp'], 700);
      expect(cloud.slots[1]!.revision, 3, reason: 'written on top of the other device\'s revision');
      expect((await phone.loadSlot(_profile, 1))!.xp, 700);
    });

    test('a slot deleted on the server is uploaded again instead of losing local progress', () async {
      final cloud = FakeCloud();
      final phone = await _device(cloud);
      await phone.save(_save(xp: 100));
      await phone.flush();
      cloud.slots.clear();
      await phone.save(_save(xp: 110, playedAt: 2000));
      await phone.flush();
      expect(cloud.slots[1]!.data['xp'], 110);
      expect(cloud.slots[1]!.revision, 1);
    });

    test('offline: slots still list, saves still work, and sync resumes later', () async {
      final cloud = FakeCloud()..offline = true;
      final phone = await _device(cloud);
      await phone.save(_save(xp: 42));
      await phone.flush();
      final slots = await phone.listSlots(_profile);
      expect(slots.first.save!.xp, 42);

      cloud.offline = false;
      await phone.listSlots(_profile);
      expect(cloud.slots[1]!.data['xp'], 42);
    });

    test('deleting a slot deletes it on the server with its revision', () async {
      final cloud = FakeCloud();
      final phone = await _device(cloud);
      await phone.save(_save(xp: 10));
      await phone.flush();
      await phone.deleteSlot(_profile, 1);
      await phone.flush();
      expect(cloud.deletes, [(1, 1)]);
      expect(cloud.slots, isEmpty);
      expect(await phone.loadSlot(_profile, 1), isNull);
    });

    test('guests and offline-only profiles never touch the server', () async {
      final phone = await _device(ForbiddenCloud(), canSync: false);
      await phone.save(_save(xp: 5));
      await phone.flush();
      expect((await phone.listSlots(_profile)).first.save!.xp, 5);
      await phone.deleteSlot(_profile, 1);
    });

    test('summaries carry what the slot list needs', () async {
      final cloud = _SummaryCloud();
      final phone = await _device(cloud);
      await phone.save(_save(xp: 1840, playedAt: 1791400000000));
      await phone.flush();
      expect(cloud.lastWrite!.summary, containsPair('xp', 1840));
      expect(cloud.lastWrite!.summary, containsPair('lastPlayedAt', 1791400000000));
      expect(cloud.lastWrite!.summary, containsPair('characterId', 'female_apprentice'));
      expect(cloud.lastWrite!.summary.keys,
          containsAll(['level', 'regionId', 'progressPercent', 'stars', 'wordsDiscovered']));
      expect(cloud.lastWrite!.contentHash, hasLength(64), reason: 'SHA-256 hex');
      expect(cloud.lastWrite!.schemaVersion, WordForgeSave.currentVersion);
    });
  });
}

class _SummaryCloud extends FakeCloud {
  CloudWrite? lastWrite;

  @override
  Future<CloudWriteResult> putSlot(int slot, CloudWrite write) {
    lastWrite = write;
    return super.putSlot(slot, write);
  }
}
