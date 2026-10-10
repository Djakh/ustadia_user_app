import '../content/word_forge_content.dart';
import '../save/word_forge_save.dart';

/// Source of words, battles, enemies, regions and combat balance. Bundled
/// assets today (`AssetWordForgeContentRepository`); a remote implementation
/// can replace it without touching the game.
abstract class WordForgeContentRepository {
  Future<WordForgeContent> load();
}

/// State of one save slot as shown on the Load screen.
class SaveSlotState {
  final int index;
  final WordForgeSave? save;

  /// The slot holds data that could not be read (and no usable backup).
  /// The raw data is preserved; the other slots are unaffected.
  final bool corrupted;

  const SaveSlotState({required this.index, this.save, this.corrupted = false});

  bool get isEmpty => save == null && !corrupted;
}

/// Three independent save slots per signed-in profile.
///
/// Local today ([LocalWordForgeSaveRepository] in `data/`). The interface is
/// slot-based so a future `RemoteWordForgeSaveRepository` (server copy) and a
/// `SyncedWordForgeSaveRepository` (local first, upload in background, newest
/// `lastPlayedAtMs` wins per `saveId`) can be added without touching gameplay.
abstract class WordForgeSaveRepository {
  static const int slotCount = 3;
  static const List<int> slots = [1, 2, 3];

  /// Never throws: a corrupt slot is reported, not fatal.
  Future<List<SaveSlotState>> listSlots(String profileId);

  Future<WordForgeSave?> loadSlot(String profileId, int slot);

  /// Persists [save] into its own slot and marks it as most recently played.
  Future<void> save(WordForgeSave save);

  Future<void> deleteSlot(String profileId, int slot);

  Future<int?> lastPlayedSlot(String profileId);
}
