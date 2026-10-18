import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:mydr/data/cloud/account_service.dart';
import 'package:mydr/data/cloud/backup_storage.dart';
import 'package:mydr/data/cloud/cloud_backend.dart';

/// Cloud storage in memory, with the owner rule of storage.rules (only
/// `users/{uid}/…` of the signed-in account) and switches to fail.
class FakeBackupStorage implements BackupStorage {
  FakeBackupStorage({this.currentUid});

  /// Whose folder may be read and written; null means signed out.
  String? Function()? currentUid;

  final Map<String, Uint8List> objects = {};
  final Map<String, Map<String, String>> metadataOf = {};

  /// Fails the upload with this number (1-based), once.
  int? failUploadNumber;
  int uploads = 0;
  BackupStorageError failWith = BackupStorageError.network;

  /// Fails every download of a path containing this.
  String? failDownloadsContaining;
  bool failListing = false;

  void _authorize(String path) {
    final uid = currentUid?.call();
    if (uid == null || !path.startsWith('users/$uid/')) {
      throw const BackupStorageException(BackupStorageError.unauthorized);
    }
  }

  void _upload(String path, Uint8List bytes, Map<String, String> metadata) {
    _authorize(path);
    uploads++;
    if (uploads == failUploadNumber) {
      failUploadNumber = null;
      throw BackupStorageException(failWith);
    }
    if (objects.containsKey(path)) {
      // storage.rules: objects are never overwritten.
      throw const BackupStorageException(BackupStorageError.unauthorized);
    }
    objects[path] = bytes;
    metadataOf[path] = Map.of(metadata);
  }

  @override
  Future<void> uploadFile(
    String path,
    File file, {
    Map<String, String> metadata = const {},
  }) async => _upload(path, await file.readAsBytes(), metadata);

  @override
  Future<void> uploadBytes(
    String path,
    Uint8List bytes, {
    Map<String, String> metadata = const {},
  }) async => _upload(path, Uint8List.fromList(bytes), metadata);

  Uint8List _download(String path) {
    _authorize(path);
    if (failDownloadsContaining case final part? when path.contains(part)) {
      throw BackupStorageException(failWith);
    }
    final bytes = objects[path];
    if (bytes == null) {
      throw const BackupStorageException(BackupStorageError.notFound);
    }
    return bytes;
  }

  @override
  Future<void> downloadFile(String path, File target) async =>
      target.writeAsBytes(_download(path));

  @override
  Future<Uint8List> downloadBytes(String path, {required int maxBytes}) async {
    final bytes = _download(path);
    if (bytes.length > maxBytes) {
      throw const BackupStorageException(BackupStorageError.unknown);
    }
    return bytes;
  }

  @override
  Future<List<String>> listFolders(String path) async {
    _authorize('$path/');
    if (failListing) throw BackupStorageException(failWith);
    final prefix = '$path/';
    return {
      for (final key in objects.keys)
        if (key.startsWith(prefix) &&
            key.substring(prefix.length).contains('/'))
          key.substring(prefix.length).split('/').first,
    }.toList();
  }

  @override
  Future<List<String>> listObjects(String path) async {
    _authorize('$path/');
    final prefix = '$path/';
    return [
      for (final key in objects.keys)
        if (key.startsWith(prefix) &&
            !key.substring(prefix.length).contains('/'))
          key.substring(prefix.length),
    ];
  }

  @override
  Future<Map<String, String>?> metadata(String path) async {
    _authorize(path);
    return objects.containsKey(path) ? metadataOf[path] ?? const {} : null;
  }

  @override
  Future<void> delete(String path) async {
    _authorize(path);
    objects.remove(path);
    metadataOf.remove(path);
  }

  /// Every byte uploaded, for checking nothing readable left the device.
  Uint8List get allBytes =>
      Uint8List.fromList([for (final bytes in objects.values) ...bytes]);
}

/// Accounts in memory: email → (uid, password).
class FakeAccountService implements AccountService {
  final Map<String, (String, String)> users = {};
  final StreamController<Account?> _changes = StreamController.broadcast();
  Account? _current;
  int _nextUid = 1;
  AccountError? failWith;

  @override
  Account? get current => _current;

  @override
  Stream<Account?> changes() => _changes.stream;

  void _set(Account? account) {
    _current = account;
    _changes.add(account);
  }

  @override
  Future<Account> register({
    required String email,
    required String password,
  }) async {
    if (failWith case final error?) throw AccountException(error);
    if (!email.contains('@')) {
      throw const AccountException(AccountError.invalidEmail);
    }
    if (users.containsKey(email)) {
      throw const AccountException(AccountError.emailInUse);
    }
    if (password.length < 6) {
      throw const AccountException(AccountError.weakPassword);
    }
    users[email] = ('uid-${_nextUid++}', password);
    return signIn(email: email, password: password);
  }

  @override
  Future<Account> signIn({
    required String email,
    required String password,
  }) async {
    if (failWith case final error?) throw AccountException(error);
    final user = users[email];
    if (user == null || user.$2 != password) {
      throw const AccountException(AccountError.wrongCredentials);
    }
    final account = Account(uid: user.$1, email: email);
    _set(account);
    return account;
  }

  @override
  Future<void> sendPasswordReset(String email) async {
    if (failWith case final error?) throw AccountException(error);
  }

  @override
  Future<void> signOut() async => _set(null);
}

class FakeCloudBackend implements CloudBackend {
  FakeCloudBackend({FakeAccountService? accounts, FakeBackupStorage? storage})
    : accounts = accounts ?? FakeAccountService(),
      storage = storage ?? FakeBackupStorage() {
    this.storage.currentUid ??= () => this.accounts.current?.uid;
  }

  final FakeAccountService accounts;
  final FakeBackupStorage storage;
  bool failConnect = false;
  int connects = 0;

  @override
  Future<CloudServices> connect() async {
    connects++;
    if (failConnect) throw const SocketException('offline');
    return CloudServices(accounts: accounts, storage: storage);
  }
}
