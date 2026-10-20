import 'dart:convert';

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

/// The secrets of household sharing, kept on this device only and never
/// sent anywhere in readable form:
///
/// * each account's identity key (the 32-byte seed of an X25519 key pair);
/// * each household's keys, by epoch (a new epoch starts whenever a member
///   is removed);
/// * the secret of each invitation this device created, until it is used.
abstract interface class SyncKeyStore {
  Future<List<int>?> readIdentitySeed(String uid);

  Future<void> writeIdentitySeed(String uid, List<int> seed);

  /// Every known key of [householdId], by epoch.
  Future<Map<int, List<int>>> readHouseholdKeys(String householdId);

  Future<void> writeHouseholdKeys(String householdId, Map<int, List<int>> keys);

  Future<void> deleteHouseholdKeys(String householdId);

  Future<List<int>?> readInviteSecret(String inviteId);

  Future<void> writeInviteSecret(String inviteId, List<int> secret);

  Future<void> deleteInviteSecret(String inviteId);
}

/// In the operating system's secure storage, like the database key and the
/// recovery key.
class SecureSyncKeyStore implements SyncKeyStore {
  const SecureSyncKeyStore({
    FlutterSecureStorage storage = const FlutterSecureStorage(
      aOptions: AndroidOptions(),
      iOptions: IOSOptions(
        accessibility: KeychainAccessibility.first_unlock_this_device,
      ),
    ),
  }) : _storage = storage;

  final FlutterSecureStorage _storage;

  static String _identity(String uid) =>
      'mydr.sync_identity.v1.${Uri.encodeComponent(uid)}';

  static String _household(String id) =>
      'mydr.sync_household_keys.v1.${Uri.encodeComponent(id)}';

  static String _invite(String id) =>
      'mydr.sync_invite.v1.${Uri.encodeComponent(id)}';

  Future<List<int>?> _readBytes(String name) async {
    final text = await _storage.read(key: name);
    if (text == null) return null;
    try {
      return base64Decode(text);
    } on FormatException {
      return null;
    }
  }

  @override
  Future<List<int>?> readIdentitySeed(String uid) => _readBytes(_identity(uid));

  @override
  Future<void> writeIdentitySeed(String uid, List<int> seed) =>
      _storage.write(key: _identity(uid), value: base64Encode(seed));

  @override
  Future<Map<int, List<int>>> readHouseholdKeys(String householdId) async {
    final text = await _storage.read(key: _household(householdId));
    if (text == null) return const {};
    try {
      final json = jsonDecode(text) as Map<String, Object?>;
      return {
        for (final MapEntry(:key, :value) in json.entries)
          int.parse(key): base64Decode(value as String),
      };
    } catch (_) {
      return const {};
    }
  }

  @override
  Future<void> writeHouseholdKeys(
    String householdId,
    Map<int, List<int>> keys,
  ) => _storage.write(
    key: _household(householdId),
    value: jsonEncode({
      for (final MapEntry(:key, :value) in keys.entries)
        '$key': base64Encode(value),
    }),
  );

  @override
  Future<void> deleteHouseholdKeys(String householdId) =>
      _storage.delete(key: _household(householdId));

  @override
  Future<List<int>?> readInviteSecret(String inviteId) =>
      _readBytes(_invite(inviteId));

  @override
  Future<void> writeInviteSecret(String inviteId, List<int> secret) =>
      _storage.write(key: _invite(inviteId), value: base64Encode(secret));

  @override
  Future<void> deleteInviteSecret(String inviteId) =>
      _storage.delete(key: _invite(inviteId));
}

/// Kept in memory only: for tests and demo mode.
class InMemorySyncKeyStore implements SyncKeyStore {
  final Map<String, List<int>> identities = {};
  final Map<String, Map<int, List<int>>> households = {};
  final Map<String, List<int>> invites = {};

  @override
  Future<List<int>?> readIdentitySeed(String uid) async => identities[uid];

  @override
  Future<void> writeIdentitySeed(String uid, List<int> seed) async =>
      identities[uid] = List.of(seed);

  @override
  Future<Map<int, List<int>>> readHouseholdKeys(String householdId) async =>
      Map.of(households[householdId] ?? const {});

  @override
  Future<void> writeHouseholdKeys(
    String householdId,
    Map<int, List<int>> keys,
  ) async => households[householdId] = Map.of(keys);

  @override
  Future<void> deleteHouseholdKeys(String householdId) async =>
      households.remove(householdId);

  @override
  Future<List<int>?> readInviteSecret(String inviteId) async =>
      invites[inviteId];

  @override
  Future<void> writeInviteSecret(String inviteId, List<int> secret) async =>
      invites[inviteId] = List.of(secret);

  @override
  Future<void> deleteInviteSecret(String inviteId) async =>
      invites.remove(inviteId);
}
