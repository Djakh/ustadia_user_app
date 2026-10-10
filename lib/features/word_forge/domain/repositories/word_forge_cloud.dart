/// Server copy of the save slots (`/students/word-forge/saves`, see
/// `docs/word_forge.md` → Cloud saves). The student comes from the access
/// token; every slot carries a server `revision` used to detect writes from
/// two devices.
///
/// Every method throws [WordForgeCloudUnavailable] when the server cannot be
/// used right now (offline, timeout, 5xx, rate limit, endpoint not deployed).
/// The game then keeps playing from its local copy and syncs later.
abstract class WordForgeCloud {
  Future<CloudSlotList> listSlots();

  /// Null when the slot holds no save.
  Future<CloudSave?> getSlot(int slot);

  Future<CloudWriteResult> putSlot(int slot, CloudWrite write);

  Future<CloudDeleteResult> deleteSlot(int slot, int revision);
}

class WordForgeCloudUnavailable implements Exception {
  final String reason;

  const WordForgeCloudUnavailable(this.reason);

  @override
  String toString() => 'WordForgeCloudUnavailable($reason)';
}

/// One slot in the list (summary only, no save data).
class CloudSlotSummary {
  final int slot;
  final int revision;
  final int schemaVersion;
  final int? lastPlayedAt;

  const CloudSlotSummary({required this.slot, required this.revision, required this.schemaVersion, this.lastPlayedAt});
}

class CloudSlotList {
  final List<CloudSlotSummary> slots;
  final int? lastPlayedSlot;

  const CloudSlotList({this.slots = const [], this.lastPlayedSlot});
}

/// A full slot as stored on the server.
class CloudSave {
  final int slot;
  final int revision;
  final int schemaVersion;
  final String contentHash;
  final Map<String, dynamic> data;

  const CloudSave({
    required this.slot,
    required this.revision,
    required this.schemaVersion,
    required this.contentHash,
    required this.data,
  });
}

/// Body of a slot write.
class CloudWrite {
  /// 0 = create (the slot is believed empty); otherwise the revision the
  /// app last received for this slot.
  final int baseRevision;
  final int schemaVersion;

  /// SHA-256 hex of [data] as sent; lets the app recognise its own write
  /// after a lost response.
  final String contentHash;
  final int clientUpdatedAt;
  final Map<String, dynamic> summary;
  final Map<String, dynamic> data;

  const CloudWrite({
    required this.baseRevision,
    required this.schemaVersion,
    required this.contentHash,
    required this.clientUpdatedAt,
    required this.summary,
    required this.data,
  });
}

sealed class CloudWriteResult {
  const CloudWriteResult();
}

class CloudWriteSaved extends CloudWriteResult {
  final int revision;

  const CloudWriteSaved(this.revision);
}

/// 409: someone else wrote first. [server] is the server's current copy, or
/// null when the slot was deleted (or never existed) on the server.
class CloudWriteConflict extends CloudWriteResult {
  final CloudSave? server;

  const CloudWriteConflict(this.server);
}

enum CloudDeleteResult { deleted, notFound, conflict }
