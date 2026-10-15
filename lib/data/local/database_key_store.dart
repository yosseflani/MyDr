import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Where the database encryption key is kept.
abstract interface class DatabaseKeyStore {
  /// The stored key, or null if there is none.
  Future<String?> read();

  Future<void> write(String key);
}

/// Keeps the key in the operating system's secure storage: the Android
/// Keystore, or the iOS Keychain limited to this device (never synced or
/// restored to another device).
class SecureDatabaseKeyStore implements DatabaseKeyStore {
  const SecureDatabaseKeyStore({
    this.keyName = defaultKeyName,
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  }) : _storage = storage;

  static const String defaultKeyName = 'mydr.database_key.v1';

  final String keyName;
  final FlutterSecureStorage _storage;

  @override
  Future<String?> read() => _storage.read(key: keyName);

  @override
  Future<void> write(String key) => _storage.write(key: keyName, value: key);
}

/// Database encryption keys: 32 random bytes from a cryptographically
/// secure generator, as 64 lower case hex digits.
abstract final class DatabaseKeys {
  static const int byteLength = 32;
  static final RegExp _pattern = RegExp(r'^[0-9a-f]{64}$');

  static String generate([Random? random]) {
    final source = random ?? Random.secure();
    return [
      for (var i = 0; i < byteLength; i++)
        source.nextInt(256).toRadixString(16).padLeft(2, '0'),
    ].join();
  }

  static bool isValid(String key) => _pattern.hasMatch(key);
}
