import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/backup/backup_data_store.dart';
import 'package:mydr/data/backup/backup_service.dart';
import 'package:mydr/data/backup/backup_snapshot.dart';
import 'package:mydr/data/backup/recovery_key.dart';
import 'package:mydr/data/cloud/account_service.dart';
import 'package:mydr/data/cloud/cloud_backend.dart';
import 'package:mydr/data/cloud/recovery_key_store.dart';
import 'package:mydr/features/family/family_controller.dart';

/// Whether the cloud can be used.
enum CloudStatus {
  /// This build has no cloud backup.
  notConfigured,

  /// Not connected yet: nothing connects until backup is opened.
  idle,
  connecting,
  connected,

  /// Connecting failed (e.g. offline); [BackupController.start] retries.
  failed,
}

/// What the controller is busy with; one thing at a time.
enum BackupActivity {
  none,
  signingIn,
  signingOut,
  loadingBackups,
  savingKey,
  backingUp,
  preparingRestore,
  restoring,
}

/// Outcome of entering an existing recovery key.
enum RecoveryKeyEntryResult {
  saved,

  /// Mistyped, or not a recovery key.
  invalid,

  /// A valid key, but not the one this account's backups were made with.
  doesNotMatch,

  /// Could not be checked or saved (see [BackupController.lastFailure]).
  failed,
}

/// State and actions for the account, cloud backup and restore.
///
/// Raw errors are never exposed: only [AccountError] and [BackupFailure]
/// values, which carry no data.
class BackupController extends ChangeNotifier {
  BackupController({
    required AppDependencies dependencies,
    required FamilyController familyController,
    DateTime Function() clock = DateTime.now,
  }) : _backend = dependencies.cloudBackend,
       _keys = dependencies.recoveryKeyStore,
       _dependencies = dependencies,
       _familyController = familyController,
       _clock = clock,
       _status = dependencies.cloudBackend == null
           ? CloudStatus.notConfigured
           : CloudStatus.idle;

  final CloudBackend? _backend;
  final RecoveryKeyStore _keys;
  final AppDependencies _dependencies;
  final FamilyController _familyController;
  final DateTime Function() _clock;

  CloudServices? _services;
  BackupService? _backupService;
  StreamSubscription<Account?>? _accountChanges;
  Future<void>? _accountSync;
  bool _isDisposed = false;

  CloudStatus _status;
  Account? _account;
  bool _hasRecoveryKey = false;
  List<RemoteBackup>? _backups;
  BackupFailure? _backupsFailure;
  BackupActivity _activity = BackupActivity.none;
  double? _progress;
  BackupFailure? _lastFailure;
  DateTime? _lastBackupAt;

  CloudStatus get status => _status;
  Account? get account => _account;

  /// Whether this device holds the signed-in account's recovery key.
  bool get hasRecoveryKey => _hasRecoveryKey;

  /// Complete cloud backups, newest first; null until loaded.
  List<RemoteBackup>? get backups => _backups;
  BackupFailure? get backupsFailure => _backupsFailure;
  BackupActivity get activity => _activity;
  bool get isBusy => _activity != BackupActivity.none;

  /// 0–1 while backing up or preparing a restore.
  double? get progress => _progress;

  /// Why the last backup, key check or restore failed.
  BackupFailure? get lastFailure => _lastFailure;

  /// The last backup made on this device while the app ran.
  DateTime? get lastBackupAt => _lastBackupAt;

  /// Backup and restore need saved data: never in demo mode.
  bool get canBackUp => _dependencies.persistsData;

  /// Connects (the first time) and loads the account's state.
  Future<void> start() async {
    final backend = _backend;
    if (backend == null ||
        _status == CloudStatus.connecting ||
        _status == CloudStatus.connected) {
      return;
    }
    _status = CloudStatus.connecting;
    _notify();
    try {
      final services = await backend.connect();
      _services = services;
      _backupService = BackupService(
        storage: services.storage,
        data: RepositoryBackupDataStore(_dependencies),
        mediaFiles: _dependencies.visitMediaFiles,
        workDirectory: _dependencies.backupWorkDirectory,
        clock: _clock,
      );
      _status = CloudStatus.connected;
      _accountChanges = services.accounts.changes().listen(_onAccount);
      await _onAccount(services.accounts.current);
    } catch (_) {
      _status = CloudStatus.failed;
      _notify();
    }
  }

  Future<AccountError?> signIn(String email, String password) => _accountAction(
    (accounts) => accounts.signIn(email: email.trim(), password: password),
  );

  Future<AccountError?> register(String email, String password) =>
      _accountAction(
        (accounts) =>
            accounts.register(email: email.trim(), password: password),
      );

  Future<AccountError?> sendPasswordReset(String email) =>
      _accountAction((accounts) => accounts.sendPasswordReset(email.trim()));

  /// Signs out and removes this account's recovery key from the device;
  /// the backups stay in the cloud, readable with the recovery key.
  Future<void> signOut() async {
    final services = _services;
    final account = _account;
    if (services == null || isBusy) return;
    _setActivity(BackupActivity.signingOut);
    try {
      if (account != null) await _keys.delete(account.uid);
      await services.accounts.signOut();
      await _onAccount(null);
    } catch (_) {
      // Still signed in; the screen shows that.
    }
    _setActivity(BackupActivity.none);
  }

  /// A new recovery key, not saved until [saveNewRecoveryKey].
  RecoveryKey createRecoveryKey() => RecoveryKey.generate();

  /// Saves a key the user confirmed they wrote down.
  Future<bool> saveNewRecoveryKey(RecoveryKey key) async {
    final account = _account;
    if (account == null) return false;
    _setActivity(BackupActivity.savingKey);
    try {
      await _keys.write(account.uid, key);
      _hasRecoveryKey = true;
      return true;
    } catch (_) {
      return false;
    } finally {
      _setActivity(BackupActivity.none);
    }
  }

  /// Saves an existing key typed by the user, after checking it opens the
  /// account's latest backup (when there is one).
  Future<RecoveryKeyEntryResult> enterRecoveryKey(String text) async {
    final account = _account;
    final service = _backupService;
    if (account == null || service == null || isBusy) {
      return RecoveryKeyEntryResult.failed;
    }
    final RecoveryKey key;
    try {
      key = RecoveryKey.parse(text);
    } on FormatException {
      return RecoveryKeyEntryResult.invalid;
    }
    _setActivity(BackupActivity.savingKey);
    _lastFailure = null;
    try {
      final latest =
          (_backups ?? await service.listBackups(account.uid)).firstOrNull;
      if (latest != null &&
          !await service.keyMatches(
            uid: account.uid,
            backup: latest,
            key: key,
          )) {
        return RecoveryKeyEntryResult.doesNotMatch;
      }
      await _keys.write(account.uid, key);
      _hasRecoveryKey = true;
      return RecoveryKeyEntryResult.saved;
    } on BackupException catch (e) {
      _lastFailure = e.failure;
      return RecoveryKeyEntryResult.failed;
    } catch (_) {
      _lastFailure = BackupFailure.unknown;
      return RecoveryKeyEntryResult.failed;
    } finally {
      _setActivity(BackupActivity.none);
    }
  }

  /// The saved recovery key, to show the user again.
  Future<RecoveryKey?> revealRecoveryKey() async {
    final account = _account;
    if (account == null) return null;
    try {
      return await _keys.read(account.uid);
    } catch (_) {
      return null;
    }
  }

  Future<void> refreshBackups() async {
    final account = _account;
    final service = _backupService;
    if (account == null || service == null) return;
    final previous = _activity;
    if (previous == BackupActivity.none) {
      _setActivity(BackupActivity.loadingBackups);
    }
    try {
      _backups = await service.listBackups(account.uid);
      _backupsFailure = null;
    } on BackupException catch (e) {
      _backupsFailure = e.failure;
    }
    if (previous == BackupActivity.none) {
      _setActivity(BackupActivity.none);
    } else {
      _notify();
    }
  }

  /// Backs up everything now. Returns null on success.
  Future<BackupFailure?> backUpNow() async {
    final account = _account;
    final service = _backupService;
    if (account == null || service == null || isBusy || !canBackUp) {
      return BackupFailure.unknown;
    }
    _setActivity(BackupActivity.backingUp);
    _lastFailure = null;
    try {
      final key = await _keys.read(account.uid);
      if (key == null) {
        _hasRecoveryKey = false;
        throw const BackupException(BackupFailure.wrongKey);
      }
      await service.createBackup(
        uid: account.uid,
        key: key,
        onProgress: _setProgress,
      );
      _lastBackupAt = _clock();
    } on BackupException catch (e) {
      _lastFailure = e.failure;
    } catch (_) {
      _lastFailure = BackupFailure.unknown;
    }
    _progress = null;
    await refreshBackups();
    _setActivity(BackupActivity.none);
    return _lastFailure;
  }

  /// Downloads and checks [backup] with the saved key, or [key] if given.
  /// Nothing on the device changes. Returns the restore to confirm, or
  /// null with [lastFailure] set.
  Future<PreparedRestore?> prepareRestore(
    RemoteBackup backup, {
    RecoveryKey? key,
  }) async {
    final account = _account;
    final service = _backupService;
    if (account == null || service == null || isBusy || !canBackUp) {
      return null;
    }
    _setActivity(BackupActivity.preparingRestore);
    _lastFailure = null;
    try {
      final useKey = key ?? await _keys.read(account.uid);
      if (useKey == null) throw const BackupException(BackupFailure.wrongKey);
      return await service.prepareRestore(
        uid: account.uid,
        backup: backup,
        key: useKey,
        onProgress: _setProgress,
      );
    } on BackupException catch (e) {
      _lastFailure = e.failure;
      return null;
    } catch (_) {
      _lastFailure = BackupFailure.unknown;
      return null;
    } finally {
      _progress = null;
      _setActivity(BackupActivity.none);
    }
  }

  /// What is on the device now, to show before it is replaced.
  Future<BackupCounts?> localCounts() async {
    try {
      return (await RepositoryBackupDataStore(_dependencies).export()).counts;
    } catch (_) {
      return null;
    }
  }

  /// Replaces the device's data with [restore], after the user confirmed
  /// it; then every screen reloads and reminders are rescheduled. [key],
  /// when the user typed it, is saved for future backups. Returns null on
  /// success; on failure the device keeps its data.
  Future<BackupFailure?> applyRestore(
    PreparedRestore restore, {
    required bool userConfirmed,
    RecoveryKey? key,
  }) async {
    if (!userConfirmed) {
      throw ArgumentError.value(
        userConfirmed,
        'userConfirmed',
        'Restoring replaces the data on the device; it needs confirmation',
      );
    }
    final account = _account;
    final service = _backupService;
    if (account == null || service == null || isBusy) {
      return BackupFailure.unknown;
    }
    _setActivity(BackupActivity.restoring);
    _lastFailure = null;
    try {
      await service.applyRestore(restore, userConfirmed: true);
      if (key != null) {
        try {
          await _keys.write(account.uid, key);
          _hasRecoveryKey = true;
        } catch (_) {
          // The restore succeeded; the key can be entered again later.
        }
      }
    } on BackupException catch (e) {
      _lastFailure = e.failure;
    } catch (_) {
      _lastFailure = BackupFailure.localWriteFailed;
    }
    // Reload even after a failure: nothing changed then, and reloading is
    // harmless.
    await _familyController.reloadAfterDataReplaced();
    _setActivity(BackupActivity.none);
    return _lastFailure;
  }

  /// The user cancelled a prepared restore.
  Future<void> cancelRestore(PreparedRestore restore) async {
    await _backupService?.discard(restore);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _accountChanges?.cancel();
    super.dispose();
  }

  Future<AccountError?> _accountAction(
    Future<Object?> Function(AccountService accounts) action,
  ) async {
    final services = _services;
    if (services == null || isBusy) return AccountError.unknown;
    _setActivity(BackupActivity.signingIn);
    try {
      await action(services.accounts);
      await _onAccount(services.accounts.current);
      return null;
    } on AccountException catch (e) {
      return e.error;
    } catch (_) {
      return AccountError.unknown;
    } finally {
      _setActivity(BackupActivity.none);
    }
  }

  /// Account updates (from the service's stream and from actions) run one
  /// after another, so an action returns only once the state is settled.
  Future<void> _onAccount(Account? account) {
    late final Future<void> update;
    update = (_accountSync ?? Future<void>.value())
        .then((_) => _applyAccount(account))
        .catchError((_) {})
        .whenComplete(() {
          // Idle again: the next update starts a fresh chain.
          if (identical(_accountSync, update)) _accountSync = null;
        });
    return _accountSync = update;
  }

  Future<void> _applyAccount(Account? account) async {
    if (_isDisposed) return;
    final changed = account?.uid != _account?.uid;
    _account = account;
    if (changed) {
      _backups = null;
      _backupsFailure = null;
      _lastFailure = null;
      _lastBackupAt = null;
    }
    if (account == null) {
      _hasRecoveryKey = false;
      _notify();
      return;
    }
    try {
      _hasRecoveryKey = await _keys.read(account.uid) != null;
    } catch (_) {
      _hasRecoveryKey = false;
    }
    _notify();
    if (changed) await refreshBackups();
  }

  void _setActivity(BackupActivity activity) {
    _activity = activity;
    _notify();
  }

  void _setProgress(double value) {
    _progress = value.clamp(0, 1);
    _notify();
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }
}
