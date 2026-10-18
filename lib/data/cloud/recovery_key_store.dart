import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:mydr/data/backup/recovery_key.dart';

/// Keeps each account's recovery key on this device, so backing up does
/// not need it typed every time. Never sent anywhere.
abstract interface class RecoveryKeyStore {
  Future<RecoveryKey?> read(String uid);

  Future<void> write(String uid, RecoveryKey key);

  Future<void> delete(String uid);
}

/// In the operating system's secure storage, like the database key: the
/// Android Keystore, or the iOS Keychain limited to this device.
class SecureRecoveryKeyStore implements RecoveryKeyStore {
  const SecureRecoveryKeyStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  static String _name(String uid) =>
      'mydr.backup_recovery_key.v1.${Uri.encodeComponent(uid)}';

  @override
  Future<RecoveryKey?> read(String uid) async {
    final text = await _storage.read(key: _name(uid));
    if (text == null) return null;
    try {
      return RecoveryKey.parse(text);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(String uid, RecoveryKey key) =>
      _storage.write(key: _name(uid), value: key.format());

  @override
  Future<void> delete(String uid) => _storage.delete(key: _name(uid));
}

/// Kept in memory only: for tests and demo mode.
class InMemoryRecoveryKeyStore implements RecoveryKeyStore {
  final Map<String, RecoveryKey> keys = {};

  @override
  Future<RecoveryKey?> read(String uid) async => keys[uid];

  @override
  Future<void> write(String uid, RecoveryKey key) async => keys[uid] = key;

  @override
  Future<void> delete(String uid) async => keys.remove(uid);
}
