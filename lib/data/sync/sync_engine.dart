import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart' as hash;
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/backup/backup_cipher.dart';
import 'package:mydr/data/cloud/account_service.dart';
import 'package:mydr/data/cloud/household_cloud.dart';
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/media/media_file_validator.dart';
import 'package:mydr/data/media/visit_media_file_store.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/sync/household_crypto.dart';
import 'package:mydr/data/sync/household_service.dart';
import 'package:mydr/data/sync/local_records.dart';
import 'package:mydr/data/sync/sync_merge.dart';
import 'package:path/path.dart' as p;

/// Why a sync failed. Never carries data. After any failure the device's
/// data is exactly as before the step that failed: pulled changes are
/// applied in one transaction, and each uploaded batch is recorded only
/// once the server has it.
enum SyncFailure {
  /// Not in a household, or signed in with another account.
  notInHousehold,

  /// This account is no longer a member; the household was forgotten on
  /// this device (family data is kept).
  removed,
  network,
  permissionDenied,

  /// A change batch could not be decrypted or read.
  damaged,

  /// This device has no key for some of the household's data.
  keyUnavailable,

  /// A key did not come from a verified member.
  verificationFailed,
  localWriteFailed,
  unknown,
}

class SyncException implements Exception {
  const SyncException(this.failure);

  final SyncFailure failure;

  @override
  String toString() => 'SyncException(${failure.name})';
}

/// What one sync did, in counts only.
class SyncReport {
  const SyncReport({
    this.received = 0,
    this.sent = 0,
    this.newConflicts = 0,
    this.waiting = 0,
    this.ignored = 0,
  });

  /// Changes from other devices written on this device.
  final int received;

  /// Local changes uploaded.
  final int sent;

  /// Changes that need the user's decision (including deletions).
  final int newConflicts;

  /// Changes waiting for a record they belong to.
  final int waiting;

  /// Changes refused as invalid or not for a shared child.
  final int ignored;

  bool get changedLocalData => received > 0;

  @override
  String toString() => 'SyncReport(received: $received, sent: $sent)';
}

/// The user's choice for a conflict.
enum ConflictChoice {
  /// Keep this device's version (or keep a record deleted elsewhere).
  keepThisDevice,

  /// Take the other device's version (or delete it here too).
  useOther,
}

/// One change as exchanged between devices.
class SyncChange {
  SyncChange({
    required this.kind,
    required this.syncId,
    required this.memberId,
    required this.vector,
    required this.updatedAt,
    required this.updatedBy,
    this.payload,
  });

  final SyncKind kind;
  final String syncId;
  final String memberId;
  final VersionVector vector;
  final DateTime updatedAt;
  final String updatedBy;

  /// Null for a deletion (a tombstone).
  final Map<String, Object?>? payload;

  bool get deleted => payload == null;

  Map<String, Object?> toJson() => {
    'kind': kind.name,
    'syncId': syncId,
    'memberId': memberId,
    'vector': vector.counters,
    'updatedAt': updatedAt.microsecondsSinceEpoch,
    'updatedBy': updatedBy,
    'payload': payload,
  };

  /// Null for anything malformed.
  static SyncChange? fromJson(Object? json) {
    if (json is! Map<String, Object?>) return null;
    final kind = SyncKind.values
        .where((k) => k.name == json['kind'])
        .firstOrNull;
    final syncId = json['syncId'];
    final memberId = json['memberId'];
    final vector = json['vector'];
    final updatedAt = json['updatedAt'];
    final updatedBy = json['updatedBy'];
    final payload = json['payload'];
    if (kind == null ||
        syncId is! String ||
        syncId.isEmpty ||
        memberId is! String ||
        memberId.isEmpty ||
        vector is! Map<String, Object?> ||
        vector.isEmpty ||
        updatedAt is! int ||
        updatedBy is! String ||
        updatedBy.isEmpty ||
        (payload != null && payload is! Map<String, Object?>)) {
      return null;
    }
    final counters = <String, int>{};
    for (final MapEntry(:key, :value) in vector.entries) {
      if (key.isEmpty || value is! int || value < 1) return null;
      counters[key] = value;
    }
    if (kind == SyncKind.share && payload == null) return null;
    return SyncChange(
      kind: kind,
      syncId: syncId,
      memberId: memberId,
      vector: VersionVector(counters),
      updatedAt: DateTime.fromMicrosecondsSinceEpoch(updatedAt),
      updatedBy: updatedBy,
      payload: payload as Map<String, Object?>?,
    );
  }

  @override
  String toString() => 'SyncChange(${kind.name} $syncId)';
}

/// Two-way sync of the shared children with the household. Runs only when
/// the user asks ("sync now"); there is no background or automatic sync.
///
/// * **Change tracking.** Every change to a shared child's records is
///   noted (with the local database, by triggers in the same transaction).
///   Offline changes simply wait there for the next sync.
/// * **Versions.** Each record carries a version vector, the time and
///   device of its latest change, and a tombstone once deleted, so a
///   deleted record never comes back and concurrent edits are detected
///   without trusting any clock.
/// * **Pull, then push.** Other devices' change batches are downloaded,
///   decrypted and merged, and everything is written in one transaction.
///   Then local changes are encrypted and uploaded in batches.
/// * **Merging.** A newer version replaces an older one. Concurrent edits
///   of different fields are combined; of the same field, they become a
///   [SyncConflict] for the user. A deletion from another device is never
///   applied without the user's confirmation; it waits as a conflict too.
/// * **Encryption.** Batches and photos are encrypted on the device with
///   the household key ([BackupCipher.withSecret]); the server sees only
///   ciphertext and the metadata described in `HouseholdCloud`.
class SyncEngine {
  SyncEngine({
    required AppDependencies dependencies,
    HouseholdCloud? cloud,
    HouseholdService? households,
    DateTime Function() clock = DateTime.now,
    Random? random,
    this.maxChangesPerBatch = 50,
  }) : _deps = dependencies,
       _cloudOrNull = cloud,
       _householdsOrNull = households,
       _records = LocalRecords(dependencies),
       _clock = clock,
       _random = random ?? Random.secure();

  /// Changes per uploaded batch (also bounded by size).
  final int maxChangesPerBatch;

  static const int _maxBatchBytes = 512 * 1024;
  static const int formatVersion = 1;

  final AppDependencies _deps;
  final HouseholdCloud? _cloudOrNull;
  final HouseholdService? _householdsOrNull;

  /// The cloud side; only [sync] uses it. Sharing choices and conflict
  /// resolution work on this device alone.
  HouseholdCloud get _cloud =>
      _cloudOrNull ?? (throw const SyncException(SyncFailure.notInHousehold));

  HouseholdService get _households =>
      _householdsOrNull ??
      (throw const SyncException(SyncFailure.notInHousehold));
  final LocalRecords _records;
  final DateTime Function() _clock;
  final Random _random;

  // ---------------------------------------------------------------------
  // Sharing

  /// Shares a child with the household: the profile and all its records go
  /// up with the next sync. [userConfirmed] must be true: from then on,
  /// changes and deletions other members make to it reach this device.
  Future<void> share(String memberId, {required bool userConfirmed}) {
    if (!userConfirmed) {
      throw ArgumentError.value(
        userConfirmed,
        'userConfirmed',
        'Sharing a profile needs the user\'s confirmation',
      );
    }
    return _local(() async {
      final state = _deps.syncStateRepository;
      if (!(await state.settings()).isActive) {
        throw const SyncException(SyncFailure.notInHousehold);
      }
      await _deps.transactions.run(() async {
        await state.setShared(memberId, shared: true, at: _clock());
        await _records.markAllPending(memberId);
      });
    });
  }

  /// Stops sharing a child for the whole household (from the next sync).
  /// Every device keeps its own copy as a private profile; nothing is
  /// deleted here or elsewhere.
  Future<void> unshare(String memberId) => _local(() async {
    final state = _deps.syncStateRepository;
    await _deps.transactions.run(() async {
      await state.setShared(memberId, shared: false);
      await state.markPending(SyncKind.share, memberId, memberId);
      for (final c in await state.conflicts()) {
        if (c.memberId == memberId) {
          await state.deleteConflict(c.kind, c.syncId);
        }
      }
    });
  });

  // ---------------------------------------------------------------------
  // Sync

  /// Pulls, merges and pushes. Throws a [SyncException].
  Future<SyncReport> sync(Account account) => _guard(() async {
    final state = _deps.syncStateRepository;
    // First: is this account still a member? (If not, forgets the
    // household here, keeping all family data.)
    await _households.household(account);
    await _households.ensureKeys(account);
    await _households.rotateIfRequested(account);
    final household = await _households.household(account);
    await _households.members(account);
    final settings = await state.settings();
    final householdId = settings.householdId!;
    final keys = await _deps.syncKeyStore.readHouseholdKeys(householdId);
    if (!keys.containsKey(household.epoch)) {
      throw const SyncException(SyncFailure.keyUnavailable);
    }
    final pulled = await _pull(account, householdId, keys);
    final sent = await _push(account, householdId, household.epoch, keys);
    await state.saveSettings(
      (await state.settings()).copyWith(lastSyncAt: _clock),
    );
    return SyncReport(
      received: pulled.applied,
      sent: sent,
      newConflicts: pulled.conflicts,
      waiting: pulled.parked,
      ignored: pulled.ignored,
    );
  });

  static String _entryContext(
    String householdId,
    String deviceId,
    int seq,
    int epoch,
  ) => 'household/$householdId/log/$deviceId/$seq/epoch/$epoch';

  static String _mediaContext(String householdId, String object, int epoch) =>
      'household/$householdId/media/$object/epoch/$epoch';

  Future<_PullContext> _pull(
    Account account,
    String householdId,
    Map<int, List<int>> keys,
  ) async {
    final state = _deps.syncStateRepository;
    final cursors = await state.cursors();
    final changes = <SyncChange>[];
    final newCursors = <String, int>{};
    var ignored = 0;

    for (final device in await _cloud.devices(householdId)) {
      final after = cursors[device.deviceId] ?? 0;
      if (device.lastSeq <= after) continue;
      final entries =
          await _cloud.logEntries(householdId, device.deviceId, afterSeq: after)
            ..sort((a, b) => a.seq.compareTo(b.seq));
      for (final entry in entries) {
        if (entry.uid != device.uid || entry.deviceId != device.deviceId) {
          throw const SyncException(SyncFailure.damaged);
        }
        final key = keys[entry.epoch];
        if (key == null) throw const SyncException(SyncFailure.keyUnavailable);
        final plain = await BackupCipher.withSecret(key).decryptBytes(
          entry.data,
          context: _entryContext(
            householdId,
            device.deviceId,
            entry.seq,
            entry.epoch,
          ),
        );
        final Object? json;
        try {
          json = jsonDecode(utf8.decode(plain));
        } catch (_) {
          throw const SyncException(SyncFailure.damaged);
        }
        if (json is! Map<String, Object?> ||
            json['format'] != 'mydr-sync' ||
            json['householdId'] != householdId ||
            json['deviceId'] != device.deviceId ||
            json['seq'] != entry.seq ||
            json['uid'] != entry.uid ||
            json['changes'] is! List) {
          throw const SyncException(SyncFailure.damaged);
        }
        final version = json['formatVersion'];
        if (version is! int || version > formatVersion) {
          throw const SyncException(SyncFailure.damaged);
        }
        for (final item in json['changes'] as List) {
          final change = SyncChange.fromJson(item);
          // The writer must have counted its own change.
          if (change == null || change.vector[device.deviceId] < 1) {
            ignored++;
          } else {
            changes.add(change);
          }
        }
        newCursors[device.deviceId] = entry.seq;
      }
    }

    // Per record, only the versions no other version replaced.
    final latest = <(SyncKind, String), List<SyncChange>>{};
    for (final change in changes) {
      final list = latest.putIfAbsent((change.kind, change.syncId), () => []);
      if (list.any((c) => c.vector.includes(change.vector))) continue;
      list
        ..removeWhere((c) => change.vector.includes(c.vector))
        ..add(change);
    }
    final ordered = [for (final list in latest.values) ...list]
      ..sort((a, b) {
        if (a.deleted != b.deleted) return a.deleted ? 1 : -1;
        final byKind = a.deleted
            ? b.kind.index.compareTo(a.kind.index)
            : a.kind.index.compareTo(b.kind.index);
        return byKind != 0 ? byKind : a.syncId.compareTo(b.syncId);
      });

    final staged = await _stageMedia(householdId, keys, ordered);
    final context = _PullContext(staged: staged)..ignored = ignored;
    var completed = false;
    try {
      await _deps.transactions.run(
        () => state.applyingRemote(() async {
          context.shared.addAll(await state.sharedMemberIds());
          for (final p in await state.pendingChanges()) {
            context.pending.add((p.kind, p.syncId));
          }
          for (final change in ordered) {
            await _process(change, context);
          }
          await _retryParked(context);
          final settings = await state.settings();
          for (final MapEntry(key: device, value: seq) in newCursors.entries) {
            await state.saveCursor(device, seq);
          }
          final own = newCursors[settings.deviceId];
          if (own != null && own >= settings.nextSeq) {
            await state.saveSettings(settings.copyWith(nextSeq: own + 1));
          }
        }),
      );
      completed = true;
    } on SyncException {
      rethrow;
    } on LocalDataException {
      throw const SyncException(SyncFailure.localWriteFailed);
    } on StateError {
      throw const SyncException(SyncFailure.localWriteFailed);
    } finally {
      // Imported files that no record took (or all, if nothing was saved).
      for (final file in staged.values) {
        if (!completed || !context.usedFiles.contains(file.fileName)) {
          await deleteVisitMediaFiles(_deps.visitMediaFiles, [file.fileName]);
        }
      }
    }
    return context;
  }

  /// Downloads, decrypts, checks and imports the photos and videos that
  /// will be needed, before anything is written. Returns them by record.
  Future<Map<String, StoredMediaFile>> _stageMedia(
    String householdId,
    Map<int, List<int>> keys,
    List<SyncChange> changes,
  ) async {
    final wanted = <String, Map<String, Object?>>{};
    for (final change in changes) {
      final payload = change.payload;
      if (change.kind == SyncKind.media && payload != null) {
        wanted[change.syncId] = payload;
      }
    }
    for (final parked in await _deps.syncStateRepository.records(
      parked: true,
    )) {
      final base = parked.base;
      if (parked.kind == SyncKind.media && base != null) {
        wanted.putIfAbsent(parked.syncId, () => base);
      }
    }
    final staged = <String, StoredMediaFile>{};
    if (wanted.isEmpty) return staged;
    final work = await _freshWorkFolder();
    try {
      for (final MapEntry(key: syncId, value: payload) in wanted.entries) {
        if (await _deps.visitMediaRepository.getById(syncId) != null) continue;
        final blob = payload['blob'];
        final extension = payload['extension'];
        if (blob is! Map<String, Object?> || extension is! String) continue;
        final object = blob['object'];
        final epoch = blob['epoch'];
        final size = blob['size'];
        final digest = blob['sha256'];
        if (object is! String ||
            !RegExp(r'^[0-9a-f]{32}\.bin$').hasMatch(object) ||
            epoch is! int ||
            size is! int ||
            digest is! String ||
            !(MediaFileValidator.photoExtensions.contains(extension) ||
                MediaFileValidator.videoExtensions.contains(extension))) {
          continue;
        }
        final key = keys[epoch];
        if (key == null) continue;
        final encrypted = File(p.join(work.path, 'download.bin'));
        await _cloud.downloadMedia(householdId, object, encrypted);
        final plain = File(p.join(work.path, 'item.$extension'));
        try {
          final info = await BackupCipher.withSecret(key).decryptFile(
            encrypted,
            plain,
            context: _mediaContext(householdId, object, epoch),
          );
          if (info.plainSize != size || info.sha256 != digest) continue;
          staged[syncId] = await _deps.visitMediaFiles.import(plain.path);
        } on BackupDecryptionException {
          continue;
        } on MediaFileException {
          continue;
        } finally {
          if (await plain.exists()) await plain.delete();
          if (await encrypted.exists()) await encrypted.delete();
        }
      }
    } catch (_) {
      for (final file in staged.values) {
        await deleteVisitMediaFiles(_deps.visitMediaFiles, [file.fileName]);
      }
      rethrow;
    } finally {
      await _deleteFolder(work);
    }
    return staged;
  }

  Future<void> _process(SyncChange change, _PullContext context) async {
    final state = _deps.syncStateRepository;
    if (change.kind == SyncKind.share) return _processShare(change, context);

    final known = await state.record(change.kind, change.syncId);
    if (known != null && known.vector.includes(change.vector)) return;

    // Privacy: only a child the household shares, and never a profile this
    // device keeps private.
    final memberShared = context.shared.contains(change.memberId);
    if (!memberShared && !await _householdShares(change.memberId)) {
      context.ignored++;
      return;
    }
    final payload = change.payload;
    if (payload != null &&
        !LocalRecords.isValid(
          change.kind,
          change.syncId,
          change.memberId,
          payload,
        )) {
      context.ignored++;
      return;
    }
    if (change.kind != SyncKind.member &&
        !memberShared &&
        await _deps.familyRepository.getById(change.memberId) != null) {
      context.ignored++;
      return;
    }

    final row = await _records.read(change.kind, change.syncId);
    final localId =
        known?.localId ??
        await _records.localIdOf(change.kind, change.syncId) ??
        (payload?['id'] as String?) ??
        change.syncId;
    final pending = context.pending.contains((change.kind, change.syncId));
    final conflict = await state.conflict(change.kind, change.syncId);
    final newer =
        known == null ||
        change.vector.compareTo(known.vector) == VectorOrder.after;
    final clean =
        newer &&
        conflict == null &&
        (row == null
            ? (known == null || !pending)
            : (known != null && !pending));
    if (clean) {
      await _fastForward(change, row, localId, context);
    } else {
      await _merge(change, known, row, localId, pending, conflict, context);
    }
  }

  /// [change] replaces what this device has.
  Future<void> _fastForward(
    SyncChange change,
    Map<String, Object?>? row,
    String localId,
    _PullContext context,
  ) async {
    final state = _deps.syncStateRepository;
    final payload = change.payload;
    if (payload == null) {
      if (row == null) {
        await state.saveRecord(_stateOf(change, localId, deleted: true));
      } else {
        // A deletion by another member: only with this user's confirmation.
        await _saveConflict(change, ConflictReason.deleted, localId, row);
        context.conflicts++;
      }
      return;
    }
    final staged = change.kind == SyncKind.media
        ? context.staged[change.syncId]
        : null;
    final written = await _records.write(
      change.kind,
      payload,
      mediaFile: staged,
    );
    final parked = written == LocalWrite.parked;
    if (!parked && staged != null) context.usedFiles.add(staged.fileName);
    final storedId = parked
        ? localId
        : await _records.localIdOf(change.kind, change.syncId) ?? localId;
    await state.saveRecord(
      _stateOf(change, storedId, base: payload, parked: parked),
    );
    if (parked) {
      context.parked++;
    } else {
      context.applied++;
      await _afterWrite(change.kind, change.syncId, context);
    }
  }

  /// [change] and this device's version were made concurrently, or this
  /// device has changes not uploaded yet.
  Future<void> _merge(
    SyncChange change,
    SyncRecordState? known,
    Map<String, Object?>? row,
    String localId,
    bool pending,
    SyncConflict? conflict,
    _PullContext context,
  ) async {
    final state = _deps.syncStateRepository;
    final vector = (known?.vector ?? VersionVector.empty).merge(change.vector);

    // A newer version made by someone who saw the conflicting one settles
    // the conflict, unless this device has changes not sent yet.
    if (conflict != null &&
        !pending &&
        change.vector.includes(
          conflict.remoteVector.merge(known?.vector ?? VersionVector.empty),
        )) {
      await state.deleteConflict(change.kind, change.syncId);
      return _fastForward(change, row, localId, context);
    }

    final remote = change.payload;
    final base = known?.base;
    if (row == null && remote == null) {
      await state.saveRecord(
        _stateOf(change, localId, deleted: true).copyWith(vector: vector),
      );
      await state.deleteConflict(change.kind, change.syncId);
      return;
    }
    if (row != null && remote == null) {
      await _saveConflict(change, ConflictReason.deleted, localId, row);
      context.conflicts++;
      return;
    }
    if (row == null) {
      if (base != null && SyncMerge.same(change.kind, base, remote!)) {
        // Unchanged there: this device's deletion stands and goes out.
        await state.saveRecord(
          _stateOf(change, localId, deleted: true).copyWith(
            vector: vector,
            updatedAt: known?.updatedAt,
            updatedBy: known?.updatedBy,
          ),
        );
        await state.markPending(change.kind, change.syncId, localId);
        await state.deleteConflict(change.kind, change.syncId);
        return;
      }
      await _saveConflict(change, ConflictReason.deletedHere, localId, null);
      context.conflicts++;
      return;
    }

    switch (SyncMerge.threeWay(
      change.kind,
      base: base,
      local: row,
      remote: remote!,
    )) {
      case MergeSame():
        await state.saveRecord(
          _stateOf(change, localId, base: remote).copyWith(vector: vector),
        );
        await state.deleteConflict(change.kind, change.syncId);
        if (!change.vector.includes(vector)) {
          // So the other devices learn this device's version too.
          await state.markPending(change.kind, change.syncId, localId);
        }
      case MergeCombined(:final payload):
        await _records.write(change.kind, payload);
        await state.saveRecord(
          _stateOf(change, localId, base: remote).copyWith(vector: vector),
        );
        await state.markPending(change.kind, change.syncId, localId);
        await state.deleteConflict(change.kind, change.syncId);
        context.applied++;
      case MergeConflict(:final fields):
        await _saveConflict(
          change,
          ConflictReason.edited,
          localId,
          row,
          fields: fields,
        );
        context.conflicts++;
    }
  }

  Future<void> _processShare(SyncChange change, _PullContext context) async {
    final state = _deps.syncStateRepository;
    final memberId = change.syncId;
    final known = await state.record(SyncKind.share, memberId);
    if (known != null && known.vector.includes(change.vector)) return;
    final remoteShared = change.payload?['shared'] == true;
    final pending = context.pending.contains((SyncKind.share, memberId));
    final concurrent =
        pending ||
        (known != null &&
            change.vector.compareTo(known.vector) == VectorOrder.concurrent);
    final localShared = pending
        ? context.shared.contains(memberId)
        : known?.base?['shared'] == true;
    // Concurrent choices: not sharing wins, the more private one.
    final shared = concurrent ? remoteShared && localShared : remoteShared;
    await state.saveRecord(
      SyncRecordState(
        kind: SyncKind.share,
        syncId: memberId,
        localId: memberId,
        memberId: memberId,
        vector: (known?.vector ?? VersionVector.empty).merge(change.vector),
        updatedAt: change.updatedAt,
        updatedBy: change.updatedBy,
        base: {'memberId': memberId, 'shared': shared},
      ),
    );
    if (shared) {
      final member = await _deps.familyRepository.getById(memberId);
      if (member != null && !context.shared.contains(memberId)) {
        try {
          await state.setShared(memberId, shared: true, at: _clock());
          context.shared.add(memberId);
        } on StateError {
          // Not a child here: stays private on this device.
        }
      }
    } else if (context.shared.remove(memberId)) {
      await state.setShared(memberId, shared: false);
      for (final c in await state.conflicts()) {
        if (c.memberId == memberId) {
          await state.deleteConflict(c.kind, c.syncId);
        }
      }
    }
    if (concurrent && shared != remoteShared) {
      await state.markPending(SyncKind.share, memberId, memberId);
    }
  }

  Future<void> _retryParked(_PullContext context) async {
    final state = _deps.syncStateRepository;
    for (var round = 0; round < 3; round++) {
      var progress = false;
      final parked = (await state.records(parked: true)).toList()
        ..sort((a, b) => a.kind.index.compareTo(b.kind.index));
      for (final record in parked) {
        final base = record.base;
        if (base == null || record.deleted) continue;
        if (!context.shared.contains(record.memberId) &&
            record.kind != SyncKind.member) {
          continue;
        }
        final staged = record.kind == SyncKind.media
            ? context.staged[record.syncId]
            : null;
        final written = await _records.write(
          record.kind,
          base,
          mediaFile: staged,
        );
        if (written == LocalWrite.parked) continue;
        progress = true;
        if (staged != null) context.usedFiles.add(staged.fileName);
        context.applied++;
        context.parked = max(0, context.parked - 1);
        await state.saveRecord(
          record.copyWith(
            parked: false,
            localId:
                await _records.localIdOf(record.kind, record.syncId) ??
                record.localId,
          ),
        );
        await _afterWrite(record.kind, record.syncId, context);
      }
      if (!progress) break;
    }
  }

  Future<void> _afterWrite(
    SyncKind kind,
    String syncId,
    _PullContext context,
  ) async {
    if (kind != SyncKind.member || context.shared.contains(syncId)) return;
    await _deps.syncStateRepository.setShared(
      syncId,
      shared: true,
      at: _clock(),
    );
    context.shared.add(syncId);
  }

  Future<bool> _householdShares(String memberId) async {
    final record = await _deps.syncStateRepository.record(
      SyncKind.share,
      memberId,
    );
    return record?.base?['shared'] == true;
  }

  Future<void> _saveConflict(
    SyncChange change,
    ConflictReason reason,
    String localId,
    Map<String, Object?>? local, {
    List<String> fields = const [],
  }) => _deps.syncStateRepository.saveConflict(
    SyncConflict(
      kind: change.kind,
      syncId: change.syncId,
      localId: localId,
      memberId: change.memberId,
      reason: reason,
      local: local,
      remote: change.payload,
      remoteVector: change.vector,
      remoteUpdatedAt: change.updatedAt,
      remoteUpdatedBy: change.updatedBy,
      fields: fields,
      detectedAt: _clock(),
    ),
  );

  static SyncRecordState _stateOf(
    SyncChange change,
    String localId, {
    bool deleted = false,
    Map<String, Object?>? base,
    bool parked = false,
  }) => SyncRecordState(
    kind: change.kind,
    syncId: change.syncId,
    localId: localId,
    memberId: change.memberId,
    vector: change.vector,
    updatedAt: change.updatedAt,
    updatedBy: change.updatedBy,
    deleted: deleted,
    base: base,
    parked: parked,
  );

  Future<int> _push(
    Account account,
    String householdId,
    int epoch,
    Map<int, List<int>> keys,
  ) async {
    final state = _deps.syncStateRepository;
    final settings = await state.settings();
    final device = settings.deviceId;
    final key = keys[epoch]!;
    final held = {for (final c in await state.conflicts()) (c.kind, c.syncId)};
    final shared = await state.sharedMemberIds();
    final outgoing = <_Outgoing>[];

    for (final pending in await state.pendingChanges()) {
      if (held.contains((pending.kind, pending.syncId))) continue;
      final known = await state.record(pending.kind, pending.syncId);
      if (known != null && known.parked) continue;

      Map<String, Object?>? payload;
      String memberId;
      if (pending.kind == SyncKind.share) {
        final isShared = shared.contains(pending.syncId);
        payload = {'memberId': pending.syncId, 'shared': isShared};
        memberId = pending.syncId;
        if ((known == null && !isShared) || jsonEquals(known?.base, payload)) {
          await state.clearPending(pending);
          continue;
        }
      } else {
        final row = await _records.read(pending.kind, pending.syncId);
        if (row == null) {
          if (known == null || known.deleted) {
            await state.clearPending(pending);
            continue;
          }
          memberId = known.memberId;
        } else {
          memberId = LocalRecords.memberOf(pending.kind, row);
          if (!shared.contains(memberId)) {
            // Moved to a profile that is not shared: gone from the
            // household. Otherwise (no longer shared) nothing goes out.
            if (known == null || known.deleted || known.memberId == memberId) {
              await state.clearPending(pending);
              continue;
            }
            memberId = known.memberId;
          } else {
            payload = row;
            if (pending.kind == SyncKind.media) {
              final blob = (known != null && !known.deleted)
                  ? known.base!['blob']
                  : null;
              payload = {
                ...row,
                'blob':
                    blob ??
                    await _uploadMedia(householdId, pending.syncId, epoch, key),
              };
              if (payload['blob'] == null) {
                // The file is gone from this device; nothing to share.
                await state.clearPending(pending);
                continue;
              }
            }
          }
        }
      }
      outgoing.add(
        _Outgoing(
          pending: pending,
          change: SyncChange(
            kind: pending.kind,
            syncId: pending.syncId,
            memberId: memberId,
            vector: (known?.vector ?? VersionVector.empty).increment(device),
            updatedAt: _clock(),
            updatedBy: device,
            payload: payload,
          ),
          localId: known?.localId ?? pending.localId,
        ),
      );
    }
    outgoing.sort((a, b) {
      final x = a.change;
      final y = b.change;
      if (x.deleted != y.deleted) return x.deleted ? 1 : -1;
      return x.deleted
          ? y.kind.index.compareTo(x.kind.index)
          : x.kind.index.compareTo(y.kind.index);
    });

    var sent = 0;
    var batch = <_Outgoing>[];
    var batchBytes = 0;
    Future<void> flush() async {
      if (batch.isEmpty) return;
      await _upload(account, householdId, epoch, key, batch);
      sent += batch.length;
      batch = [];
      batchBytes = 0;
    }

    for (final item in outgoing) {
      final size = utf8.encode(jsonEncode(item.change.toJson())).length;
      if (batch.length >= maxChangesPerBatch ||
          (batch.isNotEmpty && batchBytes + size > _maxBatchBytes)) {
        await flush();
      }
      batch.add(item);
      batchBytes += size;
    }
    await flush();
    return sent;
  }

  Future<void> _upload(
    Account account,
    String householdId,
    int epoch,
    List<int> key,
    List<_Outgoing> batch,
  ) async {
    final state = _deps.syncStateRepository;
    final settings = await state.settings();
    final seq = settings.nextSeq;
    final plain = utf8.encode(
      jsonEncode({
        'format': 'mydr-sync',
        'formatVersion': formatVersion,
        'householdId': householdId,
        'deviceId': settings.deviceId,
        'seq': seq,
        'uid': account.uid,
        'changes': [for (final item in batch) item.change.toJson()],
      }),
    );
    final data = await BackupCipher.withSecret(key, random: _random)
        .encryptBytes(
          plain,
          context: _entryContext(householdId, settings.deviceId, seq, epoch),
        );
    await _cloud.appendLog(
      householdId,
      RemoteLogEntry(
        deviceId: settings.deviceId,
        seq: seq,
        uid: account.uid,
        epoch: epoch,
        data: data,
      ),
    );
    // The server has the batch: record it as known, in one transaction.
    await _deps.transactions.run(() async {
      for (final item in batch) {
        final change = item.change;
        await state.saveRecord(
          SyncRecordState(
            kind: change.kind,
            syncId: change.syncId,
            localId: item.localId,
            memberId: change.memberId,
            vector: change.vector,
            updatedAt: change.updatedAt,
            updatedBy: change.updatedBy,
            deleted: change.deleted,
            base: change.payload,
          ),
        );
        await state.clearPending(item.pending);
      }
      await state.saveCursor(settings.deviceId, seq);
      await state.saveSettings(
        (await state.settings()).copyWith(nextSeq: seq + 1),
      );
    });
  }

  /// Encrypts and uploads a photo or video once; returns its description
  /// for the record, or null if its file is missing.
  Future<Map<String, Object?>?> _uploadMedia(
    String householdId,
    String mediaId,
    int epoch,
    List<int> key,
  ) async {
    final media = await _deps.visitMediaRepository.getById(mediaId);
    if (media == null) return null;
    final object = '${HouseholdCrypto.newId(_random)}.bin';
    final cipher = BackupCipher.withSecret(key, random: _random);
    final context = _mediaContext(householdId, object, epoch);
    final work = await _freshWorkFolder();
    try {
      final encrypted = File(p.join(work.path, 'upload.bin'));
      final EncryptedFileInfo info;
      final local = await _deps.visitMediaFiles.localFile(media.fileName);
      if (local != null && await local.exists()) {
        info = await cipher.encryptFile(local, encrypted, context: context);
      } else {
        final bytes = await _deps.visitMediaFiles.readBytes(media.fileName);
        if (bytes == null) return null;
        await encrypted.writeAsBytes(
          await cipher.encryptBytes(bytes, context: context),
        );
        info = EncryptedFileInfo(
          plainSize: bytes.length,
          sha256: hash.sha256.convert(bytes).toString(),
        );
      }
      await _cloud.uploadMedia(householdId, object, encrypted);
      return {
        'object': object,
        'epoch': epoch,
        'size': info.plainSize,
        'sha256': info.sha256,
      };
    } finally {
      await _deleteFolder(work);
    }
  }

  // ---------------------------------------------------------------------
  // Conflicts

  /// Settles [conflict] as the user chose.
  ///
  /// For a deletion made elsewhere ([ConflictReason.deleted]) with
  /// [ConflictChoice.useOther], the record must already have been deleted
  /// here through the app's normal, confirmed deletion (which also removes
  /// what belongs to it); this only records that. Throws a [StateError]
  /// otherwise.
  Future<void> resolve(SyncConflict conflict, ConflictChoice choice) =>
      _local(() async {
        final state = _deps.syncStateRepository;
        await _deps.transactions.run(() async {
          final known = await state.record(conflict.kind, conflict.syncId);
          final settings = await state.settings();
          final vector = (known?.vector ?? VersionVector.empty).merge(
            conflict.remoteVector,
          );
          final current =
              known ??
              SyncRecordState(
                kind: conflict.kind,
                syncId: conflict.syncId,
                localId: conflict.localId,
                memberId: conflict.memberId,
                vector: vector,
                updatedAt: _clock(),
                updatedBy: settings.deviceId,
              );
          final row = await _records.read(conflict.kind, conflict.syncId);
          var resolved = current.copyWith(vector: vector, parked: false);
          var push = true;

          switch ((conflict.reason, choice)) {
            case (ConflictReason.edited, ConflictChoice.keepThisDevice):
            case (ConflictReason.deleted, ConflictChoice.keepThisDevice):
              if (row == null) throw StateError('Record is gone');
              resolved = resolved.copyWith(
                deleted: false,
                base: () => conflict.remote ?? row,
              );
            case (ConflictReason.deletedHere, ConflictChoice.keepThisDevice):
              resolved = resolved.copyWith(deleted: true, base: () => null);
            case (ConflictReason.deleted, ConflictChoice.useOther):
              if (row != null) throw StateError('Record still exists');
              resolved = resolved.copyWith(deleted: true, base: () => null);
            case (ConflictReason.edited, ConflictChoice.useOther):
            case (ConflictReason.deletedHere, ConflictChoice.useOther):
              final remote = conflict.remote!;
              final written = await state.applyingRemote(
                () => _records.write(conflict.kind, remote),
              );
              resolved = resolved.copyWith(
                deleted: false,
                base: () => remote,
                parked: written == LocalWrite.parked,
                localId:
                    await _records.localIdOf(conflict.kind, conflict.syncId) ??
                    current.localId,
              );
              push = !conflict.remoteVector.includes(vector);
          }
          await state.saveRecord(resolved);
          if (push) {
            await state.markPending(
              conflict.kind,
              conflict.syncId,
              resolved.localId,
            );
          }
          await state.deleteConflict(conflict.kind, conflict.syncId);
        });
      });

  // ---------------------------------------------------------------------

  Future<Directory> _freshWorkFolder() async {
    final root = await _deps.syncWorkDirectory();
    if (await root.exists()) await root.delete(recursive: true);
    return root.create(recursive: true);
  }

  static Future<void> _deleteFolder(Directory folder) async {
    try {
      if (await folder.exists()) await folder.delete(recursive: true);
    } catch (_) {
      // Removed before the next operation.
    }
  }

  static Future<T> _local<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on SyncException {
      rethrow;
    } on StateError {
      rethrow;
    } on ArgumentError {
      rethrow;
    } catch (_) {
      throw const SyncException(SyncFailure.localWriteFailed);
    }
  }

  /// Turns any failure into a [SyncException].
  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on SyncException {
      rethrow;
    } on HouseholdException catch (e) {
      throw SyncException(switch (e.failure) {
        HouseholdFailure.network => SyncFailure.network,
        HouseholdFailure.permissionDenied => SyncFailure.permissionDenied,
        HouseholdFailure.removed => SyncFailure.removed,
        HouseholdFailure.notInHousehold => SyncFailure.notInHousehold,
        HouseholdFailure.keyUnavailable => SyncFailure.keyUnavailable,
        HouseholdFailure.verificationFailed => SyncFailure.verificationFailed,
        _ => SyncFailure.unknown,
      });
    } on HouseholdCloudException catch (e) {
      throw SyncException(switch (e.error) {
        HouseholdCloudError.network => SyncFailure.network,
        HouseholdCloudError.permissionDenied => SyncFailure.permissionDenied,
        _ => SyncFailure.unknown,
      });
    } on BackupDecryptionException {
      throw const SyncException(SyncFailure.damaged);
    } on LocalDataException {
      throw const SyncException(SyncFailure.localWriteFailed);
    } on FileSystemException {
      throw const SyncException(SyncFailure.localWriteFailed);
    } catch (_) {
      throw const SyncException(SyncFailure.unknown);
    }
  }
}

class _PullContext {
  _PullContext({required this.staged});

  final Map<String, StoredMediaFile> staged;
  final Set<String> usedFiles = {};
  final Set<String> shared = {};
  final Set<(SyncKind, String)> pending = {};
  int applied = 0;
  int conflicts = 0;
  int parked = 0;
  int ignored = 0;
}

class _Outgoing {
  const _Outgoing({
    required this.pending,
    required this.change,
    required this.localId,
  });

  final PendingChange pending;
  final SyncChange change;
  final String localId;
}
