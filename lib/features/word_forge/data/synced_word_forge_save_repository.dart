import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/content/word_forge_content.dart';
import '../domain/progression/player_level.dart';
import '../domain/repositories/word_forge_cloud.dart';
import '../domain/repositories/word_forge_repositories.dart';
import '../domain/save/save_codec.dart';
import '../domain/save/word_forge_save.dart';
import 'local_word_forge_save_repository.dart';

/// Offline-first save slots with a server copy per student.
///
/// * Local storage stays the working copy: play never waits for the network.
/// * Listing slots (opening Word Forge) first reconciles all three slots with
///   the server, for at most [listTimeout]; a reinstall or a new phone gets its
///   progress back here.
/// * Every save is written locally, then uploaded in the background with the
///   slot's last known server `revision` (one upload at a time; a burst of
///   saves becomes one upload of the newest copy).
/// * A conflict (409) is resolved as the API describes: the server copy has
///   the same content hash → it was our own write, keep its revision; else
///   the copy played most recently (`lastPlayedAtMs`) wins.
///
/// Per slot it remembers, in [SharedPreferences], the server revision and the
/// hash of the local copy at the last sync. A local copy whose hash differs
/// has changes the server has not seen yet.
class SyncedWordForgeSaveRepository implements WordForgeSaveRepository {
  final LocalWordForgeSaveRepository local;
  final WordForgeCloud cloud;
  final SharedPreferences preferences;

  /// False for guests and offline-only profiles: those never touch the server.
  final bool Function(String profileId) canSync;

  /// Game content, used only to fill `progressPercent` in slot summaries.
  final Future<WordForgeContent> Function()? content;
  final SaveCodec codec;
  final Duration listTimeout;

  SyncedWordForgeSaveRepository({
    required this.local,
    required this.cloud,
    required this.preferences,
    required this.canSync,
    this.content,
    this.codec = const SaveCodec(),
    this.listTimeout = const Duration(seconds: 8),
  });

  Future<void> _queue = Future.value();
  final Set<String> _queuedUploads = {};

  // --- WordForgeSaveRepository ----------------------------------------------

  @override
  Future<List<SaveSlotState>> listSlots(String profileId) async {
    if (canSync(profileId)) {
      try {
        await _serial(() => _reconcile(profileId)).timeout(listTimeout);
      } on TimeoutException {
        debugPrint('[WordForge sync] reconcile still running after ${listTimeout.inSeconds}s; showing local slots');
      } on WordForgeCloudUnavailable catch (error) {
        debugPrint('[WordForge sync] offline: $error');
      } on Object catch (error, stack) {
        debugPrint('[WordForge sync] reconcile failed: $error\n$stack');
      }
    }
    return local.listSlots(profileId);
  }

  @override
  Future<WordForgeSave?> loadSlot(String profileId, int slot) => local.loadSlot(profileId, slot);

  @override
  Future<int?> lastPlayedSlot(String profileId) => local.lastPlayedSlot(profileId);

  @override
  Future<void> save(WordForgeSave save) async {
    await local.save(save);
    if (!canSync(save.playerId)) return;
    final key = '${save.playerId}#${save.slotIndex}';
    if (!_queuedUploads.add(key)) return; // an upload of this slot is already waiting
    unawaited(_serial(() async {
      _queuedUploads.remove(key);
      await _push(save.playerId, save.slotIndex);
    }).catchError((Object error) {
      debugPrint('[WordForge sync] upload of slot ${save.slotIndex} postponed: $error');
    }));
  }

  @override
  Future<void> deleteSlot(String profileId, int slot) async {
    await local.deleteSlot(profileId, slot);
    final meta = _meta(profileId, slot);
    await _clearMeta(profileId, slot);
    if (!canSync(profileId) || meta == null || meta.revision <= 0) return;
    unawaited(_serial(() async {
      // A conflict means another device has newer progress in this slot;
      // it stays on the server and comes back at the next sync.
      await cloud.deleteSlot(slot, meta.revision);
    }).catchError((Object error) {
      debugPrint('[WordForge sync] remote delete of slot $slot skipped: $error');
    }));
  }

  /// Waits for every queued upload (tests, and before leaving the module).
  Future<void> flush() => _serial(() async {});

  // --- sync ------------------------------------------------------------------

  Future<T> _serial<T>(Future<T> Function() task) {
    final result = _queue.then((_) => task());
    _queue = result.then((_) {}, onError: (_) {});
    return result;
  }

  Future<void> _reconcile(String profileId) async {
    final remote = {for (final entry in (await cloud.listSlots()).slots) entry.slot: entry};
    var downloaded = false;
    for (final slot in WordForgeSaveRepository.slots) {
      final save = await local.loadSlot(profileId, slot);
      final meta = _meta(profileId, slot);
      final server = remote[slot];
      if (server == null) {
        // Never uploaded (first release with sync), or removed on the server:
        // keep the progress by uploading it.
        if (save != null) {
          await _upload(profileId, save, baseRevision: 0);
        } else if (meta != null) {
          await _clearMeta(profileId, slot);
        }
        continue;
      }
      if (save == null) {
        downloaded |= await _download(profileId, slot);
        continue;
      }
      final changedHere = meta?.hash != _hash(save.toJson());
      if (meta != null && meta.revision == server.revision) {
        if (changedHere) await _upload(profileId, save, baseRevision: server.revision);
        continue;
      }
      if (meta != null && !changedHere) {
        downloaded |= await _download(profileId, slot);
        continue;
      }
      // Never synced on this phone, or changed both here and on the server.
      final full = await cloud.getSlot(slot);
      if (full == null) {
        await _upload(profileId, save, baseRevision: 0);
      } else {
        downloaded |= await _resolve(profileId, save, full);
      }
    }
    if (downloaded) await _pointContinueAtNewest(profileId);
  }

  Future<void> _push(String profileId, int slot) async {
    final save = await local.loadSlot(profileId, slot);
    if (save == null) return;
    final meta = _meta(profileId, slot);
    if (meta?.hash == _hash(save.toJson())) return;
    await _upload(profileId, save, baseRevision: meta?.revision ?? 0);
  }

  Future<void> _upload(String profileId, WordForgeSave save, {required int baseRevision, bool retried = false}) async {
    final data = save.toJson();
    final hash = _hash(data);
    final result = await cloud.putSlot(
      save.slotIndex,
      CloudWrite(
        baseRevision: baseRevision,
        schemaVersion: save.version,
        contentHash: hash,
        clientUpdatedAt: save.lastPlayedAtMs,
        summary: await _summary(save),
        data: data,
      ),
    );
    switch (result) {
      case CloudWriteSaved(:final revision):
        await _setMeta(profileId, save.slotIndex, _SyncMeta(revision, hash));
      case CloudWriteConflict(:final server):
        if (server == null) {
          if (!retried) await _upload(profileId, save, baseRevision: 0, retried: true);
          return;
        }
        if (!retried) await _resolve(profileId, save, server);
    }
  }

  /// Settles a slot that differs from the server's copy. Returns true when
  /// the server copy replaced the local one.
  Future<bool> _resolve(String profileId, WordForgeSave save, CloudSave server) async {
    final hash = _hash(save.toJson());
    if (server.contentHash == hash) {
      // Our own earlier write whose response was lost.
      await _setMeta(profileId, save.slotIndex, _SyncMeta(server.revision, hash));
      return false;
    }
    final remote = _decode(profileId, save.slotIndex, server);
    if (remote == null || save.lastPlayedAtMs >= remote.lastPlayedAtMs) {
      await _upload(profileId, save, baseRevision: server.revision, retried: true);
      return false;
    }
    await local.save(remote);
    await _setMeta(profileId, save.slotIndex, _SyncMeta(server.revision, _hash(remote.toJson())));
    return true;
  }

  Future<bool> _download(String profileId, int slot) async {
    final server = await cloud.getSlot(slot);
    if (server == null) return false;
    final remote = _decode(profileId, slot, server);
    if (remote == null) {
      debugPrint('[WordForge sync] slot $slot on the server could not be read; kept as is');
      return false;
    }
    await local.save(remote);
    await _setMeta(profileId, slot, _SyncMeta(server.revision, _hash(remote.toJson())));
    return true;
  }

  /// Server data as a local save of [profileId], migrated by the codec.
  WordForgeSave? _decode(String profileId, int slot, CloudSave server) {
    final json = {...server.data, 'playerId': profileId, 'slot': slot};
    return codec.decode(jsonEncode(json));
  }

  /// "Continue" opens the slot played most recently on any device.
  Future<void> _pointContinueAtNewest(String profileId) async {
    WordForgeSave? newest;
    for (final slot in WordForgeSaveRepository.slots) {
      final save = await local.loadSlot(profileId, slot);
      if (save != null && (newest == null || save.lastPlayedAtMs > newest.lastPlayedAtMs)) newest = save;
    }
    if (newest != null) {
      await preferences.setInt(LocalWordForgeSaveRepository.lastSlotKey(profileId), newest.slotIndex);
    }
  }

  Future<Map<String, dynamic>> _summary(WordForgeSave save) async {
    var progress = 0;
    final loader = content;
    if (loader != null) {
      try {
        final game = await loader();
        final total = game.regions.fold<int>(0, (sum, region) => sum + region.nodes.length);
        final done = game.regions
            .fold<int>(0, (sum, region) => sum + region.nodes.where((node) => save.isCompleted(node.id)).length);
        if (total > 0) progress = (done * 100 / total).round().clamp(0, 100);
      } on Object {
        // The summary is informational; a missing percentage is fine.
      }
    }
    return {
      'characterId': save.characterId,
      'level': PlayerLevel.fromXp(save.xp).level,
      'xp': save.xp,
      'regionId': save.currentRegionId,
      'progressPercent': progress,
      'stars': save.totalStars,
      'wordsDiscovered': save.discoveredWordCount,
      'lastPlayedAt': save.lastPlayedAtMs,
    };
  }

  static String _hash(Map<String, dynamic> data) => sha256.convert(utf8.encode(jsonEncode(data))).toString();

  // --- per-slot sync state ---------------------------------------------------

  static String metaKey(String profileId, int slot) => '${LocalWordForgeSaveRepository.slotKey(profileId, slot)}.sync';

  _SyncMeta? _meta(String profileId, int slot) {
    final raw = preferences.getString(metaKey(profileId, slot));
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw);
      if (json is Map && json['rev'] is num && json['hash'] is String) {
        return _SyncMeta((json['rev'] as num).toInt(), json['hash'] as String);
      }
    } on FormatException {
      // Unreadable state = never synced; the next sync repairs it.
    }
    return null;
  }

  Future<void> _setMeta(String profileId, int slot, _SyncMeta meta) =>
      preferences.setString(metaKey(profileId, slot), jsonEncode({'rev': meta.revision, 'hash': meta.hash}));

  Future<void> _clearMeta(String profileId, int slot) => preferences.remove(metaKey(profileId, slot));
}

class _SyncMeta {
  final int revision;
  final String hash;

  const _SyncMeta(this.revision, this.hash);
}
