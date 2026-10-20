import 'package:mydr/data/models/sync_state.dart';

/// This device's bookkeeping for household sync: its settings, the shared
/// children, what it knows about each shared record, local changes not yet
/// uploaded, unresolved conflicts, read positions in other devices' logs and
/// the verified household members.
///
/// None of it is medical data itself, but record contents (merge bases and
/// conflicting versions) are, so it lives in the encrypted database like
/// everything else. No key is ever stored here.
///
/// With the local database, changes to shared records are noted in
/// [pendingChanges] automatically, in the same transaction as the change;
/// see `schema.drift`. The in-memory implementation only knows what
/// [markPending] tells it.
abstract interface class SyncStateRepository {
  /// The settings, created with a new random device id the first time.
  Future<SyncSettings> settings();

  Future<void> saveSettings(SyncSettings settings);

  Future<Set<String>> sharedMemberIds();

  /// Shares [memberId] (a child profile; anything else throws a
  /// [StateError]) from [at], which sharing requires, or stops sharing it.
  /// Stopping keeps every record.
  Future<void> setShared(
    String memberId, {
    required bool shared,
    DateTime? at,
  });

  Future<List<PendingChange>> pendingChanges();

  /// Notes a change to upload, e.g. every record of a newly shared child.
  Future<void> markPending(SyncKind kind, String syncId, String localId);

  /// Removes [change] once uploaded, unless the record changed again since
  /// it was read (its count went up).
  Future<void> clearPending(PendingChange change);

  Future<SyncRecordState?> record(SyncKind kind, String syncId);

  Future<SyncRecordState?> recordByLocalId(SyncKind kind, String localId);

  /// All known records, optionally only of one family member or only the
  /// parked ones.
  Future<List<SyncRecordState>> records({String? memberId, bool? parked});

  /// Adds or replaces the state of one record.
  Future<void> saveRecord(SyncRecordState record);

  Future<List<SyncConflict>> conflicts();

  Future<SyncConflict?> conflict(SyncKind kind, String syncId);

  /// Adds or replaces the conflict of one record.
  Future<void> saveConflict(SyncConflict conflict);

  Future<void> deleteConflict(SyncKind kind, String syncId);

  /// The last batch read from each device's log, by device id.
  Future<Map<String, int>> cursors();

  Future<void> saveCursor(String deviceId, int lastSeq);

  Future<List<KnownMember>> knownMembers();

  Future<void> saveKnownMember(KnownMember member);

  Future<void> deleteKnownMember(String uid);

  /// Runs [action], which applies changes made on other devices, so that
  /// none of its writes are noted as local changes. Callers wrap it in a
  /// transaction.
  Future<T> applyingRemote<T>(Future<T> Function() action);

  /// Forgets the household's history on this device (records, pending
  /// changes, conflicts, read positions and shared children) but keeps the
  /// membership, so the next sync starts over from the household's log.
  /// Used after a restore from backup. Never touches family data.
  Future<void> resetHistory();

  /// Forgets everything about the household: [resetHistory], the verified
  /// members, and the household link in the settings (the device id is
  /// kept), leaving the settings in [state]. Used after leaving or being
  /// removed. Never touches family data.
  Future<void> clearHousehold({SyncState state = SyncState.off});
}
