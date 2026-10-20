import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/cloud/account_service.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/sync/household_crypto.dart';
import 'package:mydr/data/sync/household_service.dart';
import 'package:mydr/data/sync/sync_engine.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/backup/backup_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/visit_preparation/visit_media_controller.dart';

/// Where household sharing stands on this device.
enum SharingStatus {
  /// This build has no cloud configuration, or nothing is saved (demo):
  /// sharing is not offered at all.
  unavailable,

  /// Connecting to the cloud (only once the sharing screen is opened).
  connecting,
  connectFailed,

  /// Sharing needs the account of "Backup and account".
  signedOut,

  /// Not in a household.
  none,

  /// Accepted an invitation; waiting to be added.
  joining,
  active,

  /// This account was removed from the household (or the household was
  /// forgotten after leaving). Family data stays on the device.
  removed,
}

/// What the controller is busy with; one thing at a time.
enum SharingActivity { none, loading, working, syncing }

/// Why a sharing action failed. Never carries data.
enum SharingFailure {
  network,
  permissionDenied,
  invalidCode,
  expired,
  alreadyUsed,
  verificationFailed,
  notAdmin,
  lastAdmin,
  keyUnavailable,
  alreadyInHousehold,
  notInHousehold,
  removed,
  damaged,
  localWriteFailed,
  notSignedIn,

  /// The record could not be deleted here (see the deletion's own message).
  deleteFailed,
  unknown,
}

/// State and actions for household sharing and sync.
///
/// Uses the account and cloud connection of [BackupController], so sharing
/// connects only when its screen is opened, like backup. Sync runs only
/// when the user asks for it ([syncNow]); nothing syncs in the background.
/// After a sync that changed data, every screen reloads and reminders are
/// rescheduled from the synced data (through
/// [FamilyController.reloadAfterDataReplaced]).
///
/// Raw errors are never exposed: only [SharingFailure] values.
class SyncController extends ChangeNotifier {
  SyncController({
    required AppDependencies dependencies,
    required BackupController backupController,
    required FamilyController familyController,
    required AppointmentController appointmentController,
    required MedicationController medicationController,
    required DoctorQuestionController doctorQuestionController,
    required SymptomController symptomController,
    required VisitMediaController visitMediaController,
    DateTime Function() clock = DateTime.now,
    Random? random,
  }) : _deps = dependencies,
       _backup = backupController,
       _family = familyController,
       _appointments = appointmentController,
       _medications = medicationController,
       _questions = doctorQuestionController,
       _symptoms = symptomController,
       _media = visitMediaController,
       _clock = clock,
       _random = random {
    _backup.addListener(_onBackupChanged);
  }

  final AppDependencies _deps;
  final BackupController _backup;
  final FamilyController _family;
  final AppointmentController _appointments;
  final MedicationController _medications;
  final DoctorQuestionController _questions;
  final SymptomController _symptoms;
  final VisitMediaController _media;
  final DateTime Function() _clock;
  final Random? _random;

  HouseholdService? _households;
  SyncEngine? _engine;
  Object? _servicesFor;
  bool _isDisposed = false;

  SyncSettings? _settings;
  Set<String> _sharedIds = const {};
  List<SyncConflict> _conflicts = const [];
  int _pendingCount = 0;
  List<HouseholdMemberView>? _members;
  List<InviteView>? _invites;
  String? _myFingerprint;
  SharingActivity _activity = SharingActivity.none;
  SharingFailure? _lastFailure;
  SyncReport? _lastReport;
  String? _waitingFor;

  /// Whether this build offers sharing at all: a cloud configuration and a
  /// saved (not demo) database.
  bool get isAvailable => _deps.cloudBackend != null && _deps.persistsData;

  SharingStatus get status {
    if (!isAvailable) return SharingStatus.unavailable;
    final settings = _settings;
    switch (_backup.status) {
      case CloudStatus.notConfigured:
        return SharingStatus.unavailable;
      case CloudStatus.idle:
      case CloudStatus.connecting:
        return SharingStatus.connecting;
      case CloudStatus.failed:
        return SharingStatus.connectFailed;
      case CloudStatus.connected:
        break;
    }
    final account = _backup.account;
    if (account == null) return SharingStatus.signedOut;
    if (settings == null) return SharingStatus.connecting;
    if (settings.accountUid != null && settings.accountUid != account.uid) {
      // Joined with another account: treated as not signed in for sharing.
      return SharingStatus.signedOut;
    }
    return switch (settings.state) {
      SyncState.off => SharingStatus.none,
      SyncState.joining => SharingStatus.joining,
      SyncState.active => SharingStatus.active,
      SyncState.removed => SharingStatus.removed,
    };
  }

  SyncSettings? get settings => _settings;

  DateTime get now => _clock();
  bool get isAdmin => _settings?.role == HouseholdRole.admin;

  /// Children shared with the household.
  Set<String> get sharedMemberIds => _sharedIds;

  List<SyncConflict> get conflicts => _conflicts;

  /// Local changes waiting for the next sync.
  int get pendingCount => _pendingCount;

  List<HouseholdMemberView>? get members => _members;
  List<InviteView>? get invites => _invites;

  /// This account's key fingerprint, to compare in person.
  String? get myFingerprint => _myFingerprint;

  /// The inviter's name while [SharingStatus.joining].
  String? get waitingFor => _waitingFor;

  SharingActivity get activity => _activity;
  bool get isBusy => _activity != SharingActivity.none;
  SharingFailure? get lastFailure => _lastFailure;
  SyncReport? get lastReport => _lastReport;
  DateTime? get lastSyncAt => _settings?.lastSyncAt;

  /// Reads this device's sharing state; never uses the network.
  Future<void> loadLocal() async {
    if (!isAvailable) return;
    final state = _deps.syncStateRepository;
    try {
      _settings = await state.settings();
      _sharedIds = await state.sharedMemberIds();
      _conflicts = await state.conflicts();
      _pendingCount = (await state.pendingChanges()).length;
      final known = await state.knownMembers();
      _waitingFor = known.firstOrNull?.label;
    } catch (_) {
      // Shown as not loaded; nothing changed.
    }
    _notify();
  }

  /// Opens sharing: connects (through backup's connection) and loads the
  /// household from the cloud.
  Future<void> start() async {
    if (!isAvailable) return;
    await loadLocal();
    await _backup.start();
    await refresh();
  }

  /// Reloads members and invitations from the cloud (sharing screen only).
  Future<void> refresh() async {
    if (isBusy) return;
    final account = _backup.account;
    final households = _services();
    if (account == null || households == null) {
      await loadLocal();
      return;
    }
    _setActivity(SharingActivity.loading);
    await _loadRemote(account, households);
    _setActivity(SharingActivity.none);
  }

  Future<void> _loadRemote(Account account, HouseholdService households) async {
    await loadLocal();
    try {
      _myFingerprint = HouseholdCrypto.fingerprint(
        (await households.identity(account.uid)).publicKey,
      );
    } catch (_) {
      _myFingerprint = null;
    }
    if (status != SharingStatus.active) {
      _members = null;
      _invites = null;
      return;
    }
    try {
      _members = await households.members(account);
      _invites = isAdmin ? await households.invites(account) : null;
    } on HouseholdException catch (e) {
      _lastFailure = _fromHousehold(e.failure);
    }
    await loadLocal();
  }

  Future<SharingFailure?> createHousehold() =>
      _householdAction((h, account) => h.create(account));

  /// A new invitation code, to show once; null with [lastFailure] set.
  Future<InviteCode?> createInvite() async {
    InviteCode? code;
    await _householdAction((h, account) async {
      code = await h.invite(account);
    });
    return code;
  }

  /// Checks an invitation code; returns the invitation to accept or reject.
  Future<(InvitePreview?, SharingFailure?)> lookupInvite(String code) async {
    InvitePreview? preview;
    final failure = await _householdAction((h, account) async {
      preview = await h.lookup(account, code);
    }, reload: false);
    return (preview, failure);
  }

  Future<SharingFailure?> respondToInvite(
    InvitePreview preview, {
    required bool accept,
  }) => _householdAction(
    (h, account) => h.respond(account, preview, accept: accept),
  );

  /// While joining: checks whether the inviter added this account.
  Future<SharingFailure?> checkJoined() =>
      _householdAction((h, account) => h.checkJoined(account));

  Future<SharingFailure?> cancelJoining() =>
      _householdAction((h, _) => h.cancelJoining());

  Future<SharingFailure?> completeInvite(String inviteId, HouseholdRole role) =>
      _householdAction(
        (h, account) => h.completeInvite(account, inviteId, role: role),
      );

  Future<SharingFailure?> cancelInvite(String inviteId) =>
      _householdAction((h, _) => h.cancelInvite(inviteId));

  /// Removes a member; their access ends and the key is replaced. Must only
  /// be called after the user confirmed it.
  Future<SharingFailure?> revokeMember(
    String uid, {
    required bool userConfirmed,
  }) {
    _requireConfirmation(userConfirmed);
    return _householdAction((h, account) => h.revoke(account, uid));
  }

  Future<SharingFailure?> setRole(String uid, HouseholdRole role) =>
      _householdAction((h, account) => h.setRole(account, uid, role));

  /// Leaves the household. Family data stays on this device. Must only be
  /// called after the user confirmed it.
  Future<SharingFailure?> leave({required bool userConfirmed}) {
    _requireConfirmation(userConfirmed);
    return _householdAction((h, account) => h.leave(account));
  }

  /// After seeing that this account was removed.
  Future<void> acknowledgeRemoval() async {
    final state = _deps.syncStateRepository;
    try {
      await state.clearHousehold();
    } catch (_) {}
    await loadLocal();
  }

  /// Shares a child with the household. Must only be called after the user
  /// confirmed that changes and deletions by other members will reach it.
  Future<SharingFailure?> share(
    String memberId, {
    required bool userConfirmed,
  }) {
    _requireConfirmation(userConfirmed);
    return _syncAction((engine) => engine.share(memberId, userConfirmed: true));
  }

  /// Stops sharing a child; every device keeps its copy.
  Future<SharingFailure?> unshare(String memberId) =>
      _syncAction((engine) => engine.unshare(memberId));

  /// Sync now: downloads and merges the other devices' changes, then uploads
  /// this device's. Returns null on success.
  Future<SharingFailure?> syncNow() async {
    final account = _backup.account;
    final engine = _engineFor();
    if (account == null || engine == null || isBusy) {
      return _lastFailure = SharingFailure.notSignedIn;
    }
    _setActivity(SharingActivity.syncing);
    _lastFailure = null;
    SyncReport? report;
    try {
      report = await engine.sync(account);
      _lastReport = report;
    } on SyncException catch (e) {
      _lastFailure = _fromSync(e.failure);
    } catch (_) {
      _lastFailure = SharingFailure.unknown;
    }
    // Every screen reloads and reminders are planned again from the synced
    // data; harmless when nothing changed.
    if (report?.changedLocalData ?? false) {
      await _family.reloadAfterDataReplaced();
    }
    final households = _services();
    if (households != null) await _loadRemote(account, households);
    _setActivity(SharingActivity.none);
    return _lastFailure;
  }

  /// Settles a conflict. Deleting a record because another member deleted
  /// it ([ConflictReason.deleted] with [ConflictChoice.useOther]) goes
  /// through the app's normal deletion, which also removes what belongs to
  /// it; it must only be called after the user confirmed it.
  Future<SharingFailure?> resolve(
    SyncConflict conflict,
    ConflictChoice choice, {
    bool userConfirmed = false,
  }) async {
    final engine = _engineFor(requireAccount: false);
    if (engine == null || isBusy) return SharingFailure.unknown;
    final deleting =
        conflict.reason == ConflictReason.deleted &&
        choice == ConflictChoice.useOther;
    if (deleting) _requireConfirmation(userConfirmed);
    _setActivity(SharingActivity.working);
    _lastFailure = null;
    try {
      if (deleting && !await _deleteLocally(conflict)) {
        _lastFailure = SharingFailure.deleteFailed;
      } else {
        await engine.resolve(conflict, choice);
        if (!deleting) await _family.reloadAfterDataReplaced();
      }
    } on SyncException catch (e) {
      _lastFailure = _fromSync(e.failure);
    } catch (_) {
      _lastFailure = SharingFailure.unknown;
    }
    await loadLocal();
    _setActivity(SharingActivity.none);
    return _lastFailure;
  }

  /// Applies every deletion made by other members, after the user confirmed
  /// it: records first, then what they belonged to. Stops at the first
  /// failure.
  Future<SharingFailure?> applyAllDeletions({
    required bool userConfirmed,
  }) async {
    _requireConfirmation(userConfirmed);
    final deletions = [
      for (final c in _conflicts)
        if (c.reason == ConflictReason.deleted) c,
    ]..sort((a, b) => b.kind.index.compareTo(a.kind.index));
    for (final conflict in deletions) {
      final failure = await resolve(
        conflict,
        ConflictChoice.useOther,
        userConfirmed: true,
      );
      if (failure != null) return failure;
    }
    return null;
  }

  /// Deletes the record of [conflict] with the matching controller, exactly
  /// as if the user deleted it here.
  Future<bool> _deleteLocally(SyncConflict conflict) async {
    final id = conflict.localId;
    switch (conflict.kind) {
      case SyncKind.share:
        return true;
      case SyncKind.member:
        return (await _family.delete(id, userConfirmed: true)).isSuccess;
      case SyncKind.appointment:
        return (await _appointments.delete(id, userConfirmed: true)).isSuccess;
      case SyncKind.medication:
        return _medications.delete(id, userConfirmed: true);
      case SyncKind.question:
        return _questions.delete(id, userConfirmed: true);
      case SyncKind.symptom:
        return _symptoms.delete(id, userConfirmed: true);
      case SyncKind.media:
        return _media.delete(id, userConfirmed: true);
      case SyncKind.dose:
        final local = conflict.local;
        final medicationId = local?['medicationId'];
        final scheduledAt = local?['scheduledAt'];
        if (medicationId is! String || scheduledAt is! String) return false;
        return _medications.clearDose(
          medicationId,
          StorageCodecs.decodeLocalDateTime(scheduledAt),
        );
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _backup.removeListener(_onBackupChanged);
    super.dispose();
  }

  void _onBackupChanged() {
    final services = _backup.services;
    if (!identical(services, _servicesFor)) {
      _servicesFor = services;
      _households = null;
      _engine = null;
    }
    _notify();
  }

  HouseholdService? _services() {
    final services = _backup.services;
    final cloud = services?.household;
    if (cloud == null) return null;
    if (!identical(services, _servicesFor) || _households == null) {
      _servicesFor = services;
      _households = HouseholdService(
        cloud: cloud,
        keys: _deps.syncKeyStore,
        state: _deps.syncStateRepository,
        clock: _clock,
        random: _random,
      );
      _engine = SyncEngine(
        dependencies: _deps,
        cloud: cloud,
        households: _households!,
        clock: _clock,
        random: _random,
      );
    }
    return _households;
  }

  /// The engine with the cloud when connected; for local actions (sharing
  /// choices, conflicts) one without it otherwise.
  SyncEngine? _engineFor({bool requireAccount = true}) {
    if (requireAccount && _backup.account == null) return null;
    _services();
    return _engine ??
        (requireAccount
            ? null
            : _localEngine ??= SyncEngine(
                dependencies: _deps,
                clock: _clock,
                random: _random,
              ));
  }

  SyncEngine? _localEngine;

  Future<SharingFailure?> _householdAction(
    Future<void> Function(HouseholdService households, Account account)
    action, {
    bool reload = true,
  }) async {
    final account = _backup.account;
    final households = _services();
    if (account == null || households == null) {
      return _lastFailure = SharingFailure.notSignedIn;
    }
    if (isBusy) return SharingFailure.unknown;
    _setActivity(SharingActivity.working);
    _lastFailure = null;
    try {
      await action(households, account);
    } on HouseholdException catch (e) {
      _lastFailure = _fromHousehold(e.failure);
    } catch (_) {
      _lastFailure = SharingFailure.unknown;
    }
    final failure = _lastFailure;
    if (reload) {
      await _loadRemote(account, households);
      _lastFailure = failure;
    }
    _setActivity(SharingActivity.none);
    return failure;
  }

  Future<SharingFailure?> _syncAction(
    Future<void> Function(SyncEngine engine) action,
  ) async {
    final engine = _engineFor(requireAccount: false);
    if (engine == null || isBusy) return SharingFailure.unknown;
    _setActivity(SharingActivity.working);
    _lastFailure = null;
    try {
      await action(engine);
    } on SyncException catch (e) {
      _lastFailure = _fromSync(e.failure);
    } on StateError {
      _lastFailure = SharingFailure.localWriteFailed;
    } catch (_) {
      _lastFailure = SharingFailure.unknown;
    }
    await loadLocal();
    _setActivity(SharingActivity.none);
    return _lastFailure;
  }

  static void _requireConfirmation(bool userConfirmed) {
    if (!userConfirmed) {
      throw ArgumentError.value(
        userConfirmed,
        'userConfirmed',
        'This sharing action needs the user\'s explicit confirmation',
      );
    }
  }

  static SharingFailure _fromHousehold(HouseholdFailure f) => switch (f) {
    HouseholdFailure.network => SharingFailure.network,
    HouseholdFailure.permissionDenied => SharingFailure.permissionDenied,
    HouseholdFailure.invalidCode => SharingFailure.invalidCode,
    HouseholdFailure.expired => SharingFailure.expired,
    HouseholdFailure.alreadyUsed => SharingFailure.alreadyUsed,
    HouseholdFailure.verificationFailed => SharingFailure.verificationFailed,
    HouseholdFailure.notAdmin => SharingFailure.notAdmin,
    HouseholdFailure.lastAdmin => SharingFailure.lastAdmin,
    HouseholdFailure.keyUnavailable => SharingFailure.keyUnavailable,
    HouseholdFailure.alreadyInHousehold => SharingFailure.alreadyInHousehold,
    HouseholdFailure.notInHousehold => SharingFailure.notInHousehold,
    HouseholdFailure.removed => SharingFailure.removed,
    HouseholdFailure.unknown => SharingFailure.unknown,
  };

  static SharingFailure _fromSync(SyncFailure f) => switch (f) {
    SyncFailure.notInHousehold => SharingFailure.notInHousehold,
    SyncFailure.removed => SharingFailure.removed,
    SyncFailure.network => SharingFailure.network,
    SyncFailure.permissionDenied => SharingFailure.permissionDenied,
    SyncFailure.damaged => SharingFailure.damaged,
    SyncFailure.keyUnavailable => SharingFailure.keyUnavailable,
    SyncFailure.verificationFailed => SharingFailure.verificationFailed,
    SyncFailure.localWriteFailed => SharingFailure.localWriteFailed,
    SyncFailure.unknown => SharingFailure.unknown,
  };

  void _setActivity(SharingActivity activity) {
    _activity = activity;
    _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }
}
