import 'package:shared_preferences/shared_preferences.dart';

import '../domain/repositories/word_forge_repositories.dart';
import '../domain/save/save_codec.dart';
import '../domain/save/word_forge_save.dart';

/// Stores each slot as versioned JSON in SharedPreferences:
/// `word_forge.<profile>.slot<N>` plus a `.backup` of the previous good copy.
/// Unreadable data is copied to `.corrupt` and never silently deleted; a
/// broken slot never affects the other two.
///
/// Saves written by the first Word Forge version (single save per player)
/// are moved into slot 1 the first time slots are listed.
class LocalWordForgeSaveRepository implements WordForgeSaveRepository {
  final SharedPreferences preferences;
  final SaveCodec codec;

  const LocalWordForgeSaveRepository({required this.preferences, this.codec = const SaveCodec()});

  static String _safe(String profileId) =>
      profileId.trim().isEmpty ? 'guest' : profileId.replaceAll(RegExp(r'[^A-Za-z0-9_\-]'), '_');

  static String slotKey(String profileId, int slot) => 'word_forge.${_safe(profileId)}.slot$slot';
  static String backupKey(String profileId, int slot) => '${slotKey(profileId, slot)}.backup';
  static String corruptKey(String profileId, int slot) => '${slotKey(profileId, slot)}.corrupt';
  static String lastSlotKey(String profileId) => 'word_forge.${_safe(profileId)}.last_slot';
  static String legacyKey(String profileId) => 'word_forge.save.${_safe(profileId)}';

  Future<void> _migrateLegacy(String profileId) async {
    final legacy = preferences.getString(legacyKey(profileId));
    if (legacy == null) return;
    final hasSlots = WordForgeSaveRepository.slots.any((slot) => preferences.containsKey(slotKey(profileId, slot)));
    if (!hasSlots) {
      final save = codec.decode(legacy);
      if (save != null) {
        await preferences.setString(slotKey(profileId, 1), codec.encode(save.copyWith(slotIndex: 1)));
        await preferences.setInt(lastSlotKey(profileId), 1);
      }
    }
    await preferences.remove(legacyKey(profileId));
  }

  ({WordForgeSave? save, bool corrupted}) _read(String profileId, int slot) {
    final raw = preferences.getString(slotKey(profileId, slot));
    if (raw == null || raw.isEmpty) return (save: null, corrupted: false);
    final primary = codec.decode(raw);
    if (primary != null) return (save: primary.copyWith(slotIndex: slot), corrupted: false);
    final backup = codec.decode(preferences.getString(backupKey(profileId, slot)));
    return (save: backup?.copyWith(slotIndex: slot), corrupted: backup == null);
  }

  @override
  Future<List<SaveSlotState>> listSlots(String profileId) async {
    await _migrateLegacy(profileId);
    final result = <SaveSlotState>[];
    for (final slot in WordForgeSaveRepository.slots) {
      final read = _read(profileId, slot);
      if (read.save == null && read.corrupted) {
        final raw = preferences.getString(slotKey(profileId, slot));
        if (raw != null) await preferences.setString(corruptKey(profileId, slot), raw);
      }
      result.add(SaveSlotState(index: slot, save: read.save, corrupted: read.corrupted));
    }
    return result;
  }

  @override
  Future<WordForgeSave?> loadSlot(String profileId, int slot) async {
    await _migrateLegacy(profileId);
    return _read(profileId, slot).save;
  }

  @override
  Future<void> save(WordForgeSave save) async {
    final key = slotKey(save.playerId, save.slotIndex);
    final previous = preferences.getString(key);
    if (previous != null && codec.decode(previous) != null) {
      await preferences.setString(backupKey(save.playerId, save.slotIndex), previous);
    }
    await preferences.setString(key, codec.encode(save));
    await preferences.setInt(lastSlotKey(save.playerId), save.slotIndex);
  }

  @override
  Future<void> deleteSlot(String profileId, int slot) async {
    await preferences.remove(slotKey(profileId, slot));
    await preferences.remove(backupKey(profileId, slot));
    if (preferences.getInt(lastSlotKey(profileId)) == slot) await preferences.remove(lastSlotKey(profileId));
  }

  @override
  Future<int?> lastPlayedSlot(String profileId) async => preferences.getInt(lastSlotKey(profileId));
}
