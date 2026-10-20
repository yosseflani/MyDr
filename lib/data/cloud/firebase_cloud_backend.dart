import 'dart:async';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mydr/data/cloud/account_service.dart';
import 'package:mydr/data/cloud/backup_storage.dart';
import 'package:mydr/data/cloud/cloud_backend.dart';
import 'package:mydr/data/cloud/household_cloud.dart';

/// Which Firebase project cloud backup uses, from build-time defines:
///
///     flutter run --dart-define-from-file=config/firebase.json
///
/// See config/firebase.example.json. A build without them has no cloud
/// backup at all: nothing connects to the network.
class CloudConfig {
  const CloudConfig({
    required this.projectId,
    required this.apiKey,
    required this.appId,
    required this.messagingSenderId,
    required this.storageBucket,
    this.emulatorHost,
    this.authEmulatorPort = 9099,
    this.storageEmulatorPort = 9199,
    this.firestoreEmulatorPort = 8080,
  });

  final String projectId;
  final String apiKey;
  final String appId;
  final String messagingSenderId;
  final String storageBucket;

  /// The Firebase Local Emulator Suite's host (debug builds and "demo-"
  /// projects only), e.g. 10.0.2.2 from the Android emulator.
  final String? emulatorHost;
  final int authEmulatorPort;
  final int storageEmulatorPort;

  /// Household sharing's database (Cloud Firestore) in the emulator suite.
  final int firestoreEmulatorPort;

  bool get usesEmulator => emulatorHost != null;

  /// Null when the build was not configured for cloud backup.
  static CloudConfig? fromEnvironment() {
    const projectId = String.fromEnvironment('MYDR_FIREBASE_PROJECT_ID');
    if (projectId.isEmpty) return null;
    const emulatorHost = String.fromEnvironment('MYDR_FIREBASE_EMULATOR_HOST');
    const apiKey = String.fromEnvironment('MYDR_FIREBASE_API_KEY');
    const appId = String.fromEnvironment('MYDR_FIREBASE_APP_ID');
    const senderId = String.fromEnvironment('MYDR_FIREBASE_SENDER_ID');
    const bucket = String.fromEnvironment('MYDR_FIREBASE_STORAGE_BUCKET');
    // The emulator talks plain HTTP and accepts any token: never in a
    // release build, and only with a demo project, which has no real data.
    final useEmulator =
        emulatorHost.isNotEmpty &&
        !kReleaseMode &&
        projectId.startsWith('demo-');
    if (!useEmulator && (apiKey.isEmpty || appId.isEmpty || bucket.isEmpty)) {
      return null;
    }
    return CloudConfig(
      projectId: projectId,
      apiKey: apiKey.isEmpty ? 'demo-api-key' : apiKey,
      appId: appId.isEmpty ? '1:1:android:1' : appId,
      messagingSenderId: senderId.isEmpty ? '1' : senderId,
      storageBucket: bucket.isEmpty ? '$projectId.appspot.com' : bucket,
      emulatorHost: useEmulator ? emulatorHost : null,
      authEmulatorPort: const int.fromEnvironment(
        'MYDR_FIREBASE_AUTH_PORT',
        defaultValue: 9099,
      ),
      storageEmulatorPort: const int.fromEnvironment(
        'MYDR_FIREBASE_STORAGE_PORT',
        defaultValue: 9199,
      ),
      firestoreEmulatorPort: const int.fromEnvironment(
        'MYDR_FIREBASE_FIRESTORE_PORT',
        defaultValue: 8080,
      ),
    );
  }
}

/// Firebase Authentication (email and password) and Cloud Storage.
class FirebaseCloudBackend implements CloudBackend {
  FirebaseCloudBackend(this.config);

  static const String appName = 'mydr-cloud';

  final CloudConfig config;
  Future<CloudServices>? _connection;

  @override
  Future<CloudServices> connect() =>
      _connection ??= _connect().catchError((Object error) {
        _connection = null;
        throw error;
      });

  Future<CloudServices> _connect() async {
    final app = await _app();
    final auth = FirebaseAuth.instanceFor(app: app);
    final storage = FirebaseStorage.instanceFor(
      app: app,
      bucket: 'gs://${config.storageBucket}',
    );
    final firestore = FirebaseFirestore.instanceFor(app: app);
    // No local cache: nothing about the household is kept on the device
    // outside the encrypted database, and no write is queued to go out on
    // its own later.
    firestore.settings = const Settings(persistenceEnabled: false);
    if (config.emulatorHost case final host?) {
      await auth.useAuthEmulator(
        host,
        config.authEmulatorPort,
        automaticHostMapping: false,
      );
      await storage.useStorageEmulator(
        host,
        config.storageEmulatorPort,
        automaticHostMapping: false,
      );
      firestore.useFirestoreEmulator(
        host,
        config.firestoreEmulatorPort,
        automaticHostMapping: false,
      );
    }
    // Offline until the user asks for something (see FirebaseHouseholdCloud).
    await firestore.disableNetwork();
    return CloudServices(
      accounts: FirebaseAccountService(auth),
      storage: FirebaseBackupStorage(storage),
      household: FirebaseHouseholdCloud(firestore, storage),
    );
  }

  Future<FirebaseApp> _app() async {
    for (final app in Firebase.apps) {
      if (app.name == appName) return app;
    }
    return Firebase.initializeApp(
      name: appName,
      options: FirebaseOptions(
        apiKey: config.apiKey,
        appId: config.appId,
        messagingSenderId: config.messagingSenderId,
        projectId: config.projectId,
        storageBucket: config.storageBucket,
      ),
    );
  }
}

class FirebaseAccountService implements AccountService {
  FirebaseAccountService(this._auth);

  final FirebaseAuth _auth;

  static Account? _account(User? user) =>
      user == null ? null : Account(uid: user.uid, email: user.email);

  @override
  Account? get current => _account(_auth.currentUser);

  @override
  Stream<Account?> changes() => _auth.authStateChanges().map(_account);

  @override
  Future<Account> signIn({required String email, required String password}) =>
      _guard(() async {
        final result = await _auth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
        return _account(result.user)!;
      });

  @override
  Future<Account> register({required String email, required String password}) =>
      _guard(() async {
        final result = await _auth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        return _account(result.user)!;
      });

  @override
  Future<void> sendPasswordReset(String email) =>
      _guard(() => _auth.sendPasswordResetEmail(email: email));

  @override
  Future<void> signOut() => _guard(_auth.signOut);

  static Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on FirebaseAuthException catch (e) {
      throw AccountException(switch (e.code) {
        'invalid-email' => AccountError.invalidEmail,
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' ||
        'user-disabled' ||
        'INVALID_LOGIN_CREDENTIALS' => AccountError.wrongCredentials,
        'email-already-in-use' => AccountError.emailInUse,
        'weak-password' => AccountError.weakPassword,
        'network-request-failed' => AccountError.network,
        'too-many-requests' => AccountError.tooManyAttempts,
        _ => AccountError.unknown,
      });
    } on AccountException {
      rethrow;
    } catch (_) {
      throw const AccountException(AccountError.unknown);
    }
  }
}

class FirebaseBackupStorage implements BackupStorage {
  FirebaseBackupStorage(this._storage);

  final FirebaseStorage _storage;

  static const String _contentType = 'application/octet-stream';

  @override
  Future<void> uploadFile(
    String path,
    File file, {
    Map<String, String> metadata = const {},
  }) => _guard(
    () => _storage
        .ref(path)
        .putFile(
          file,
          SettableMetadata(contentType: _contentType, customMetadata: metadata),
        ),
  );

  @override
  Future<void> uploadBytes(
    String path,
    Uint8List bytes, {
    Map<String, String> metadata = const {},
  }) => _guard(
    () => _storage
        .ref(path)
        .putData(
          bytes,
          SettableMetadata(contentType: _contentType, customMetadata: metadata),
        ),
  );

  @override
  Future<void> downloadFile(String path, File target) =>
      _guard(() => _storage.ref(path).writeToFile(target));

  @override
  Future<Uint8List> downloadBytes(String path, {required int maxBytes}) =>
      _guard(() async {
        final data = await _storage.ref(path).getData(maxBytes);
        if (data == null) {
          throw const BackupStorageException(BackupStorageError.notFound);
        }
        return data;
      });

  @override
  Future<List<String>> listFolders(String path) => _guard(() async {
    final result = await _storage.ref(path).listAll();
    return [for (final prefix in result.prefixes) prefix.name];
  });

  @override
  Future<List<String>> listObjects(String path) => _guard(() async {
    final result = await _storage.ref(path).listAll();
    return [for (final item in result.items) item.name];
  });

  @override
  Future<Map<String, String>?> metadata(String path) async {
    try {
      final metadata = await _guard(() => _storage.ref(path).getMetadata());
      return metadata.customMetadata ?? const {};
    } on BackupStorageException catch (e) {
      if (e.error == BackupStorageError.notFound) return null;
      rethrow;
    }
  }

  @override
  Future<void> delete(String path) async {
    try {
      await _guard(() => _storage.ref(path).delete());
    } on BackupStorageException catch (e) {
      if (e.error != BackupStorageError.notFound) rethrow;
    }
  }

  static Future<T> _guard<T>(FutureOr<T> Function() action) async {
    try {
      return await action();
    } on FirebaseException catch (e) {
      throw BackupStorageException(switch (e.code) {
        'object-not-found' => BackupStorageError.notFound,
        'unauthorized' || 'unauthenticated' => BackupStorageError.unauthorized,
        'quota-exceeded' => BackupStorageError.quotaExceeded,
        'retry-limit-exceeded' ||
        'network-request-failed' ||
        'canceled' => BackupStorageError.network,
        _ => BackupStorageError.unknown,
      });
    } on BackupStorageException {
      rethrow;
    } on SocketException {
      throw const BackupStorageException(BackupStorageError.network);
    } catch (_) {
      throw const BackupStorageException(BackupStorageError.unknown);
    }
  }
}

/// [HouseholdCloud] on Cloud Firestore (membership, keys, invitations and
/// change logs) and Cloud Storage (encrypted photos and videos).
///
/// Firestore's network access is switched on only while one of these
/// methods runs, each at the user's request, and off again afterwards. So
/// a write that could not be sent (e.g. offline) never goes out by itself
/// later: it waits for the next action the user starts.
class FirebaseHouseholdCloud implements HouseholdCloud {
  FirebaseHouseholdCloud(this._db, this._storage);

  final FirebaseFirestore _db;
  final FirebaseStorage _storage;
  int _active = 0;

  static const Duration _timeout = Duration(seconds: 45);
  static const GetOptions _server = GetOptions(source: Source.server);
  static const String _contentType = 'application/octet-stream';

  DocumentReference<Map<String, dynamic>> _household(String id) =>
      _db.collection('households').doc(id);

  DocumentReference<Map<String, dynamic>> _member(String hid, String uid) =>
      _household(hid).collection('members').doc(uid);

  CollectionReference<Map<String, dynamic>> _keys(String hid, String uid) =>
      _member(hid, uid).collection('keys');

  DocumentReference<Map<String, dynamic>> _invite(String id) =>
      _db.collection('invites').doc(id);

  DocumentReference<Map<String, dynamic>> _device(String hid, String id) =>
      _household(hid).collection('devices').doc(id);

  Reference _media(String hid, String object) =>
      _storage.ref('households/$hid/media/$object');

  @override
  Future<void> createHousehold({
    required String householdId,
    required RemoteMember creator,
    required RemoteWrappedKey key,
  }) => _online(() async {
    final batch = _db.batch()
      ..set(_household(householdId), {
        'createdBy': creator.uid,
        'epoch': 1,
        'needsRotation': false,
      })
      ..set(_member(householdId, creator.uid), _memberData(creator))
      ..set(_keys(householdId, creator.uid).doc('${key.epoch}'), _keyData(key));
    await batch.commit();
  });

  @override
  Future<RemoteHousehold?> household(String householdId) => _online(() async {
    final doc = await _household(householdId).get(_server);
    final data = doc.data();
    if (data == null) return null;
    return RemoteHousehold(
      id: householdId,
      createdBy: data['createdBy'] as String,
      epoch: data['epoch'] as int,
      needsRotation: data['needsRotation'] == true,
    );
  });

  @override
  Future<List<RemoteMember>> members(String householdId) => _online(() async {
    final result = await _household(
      householdId,
    ).collection('members').get(_server);
    return [for (final doc in result.docs) _readMember(doc.data())];
  });

  @override
  Future<List<RemoteWrappedKey>> wrappedKeys(String householdId, String uid) =>
      _online(() async {
        final result = await _keys(householdId, uid).get(_server);
        return [
          for (final doc in result.docs)
            RemoteWrappedKey(
              epoch: doc.data()['epoch'] as int,
              wrappedBy: doc.data()['wrappedBy'] as String,
              wrapped: (doc.data()['wrapped'] as Blob).bytes,
            ),
        ];
      });

  @override
  Future<void> createInvite(RemoteInvite invite) =>
      _online(() => _invite(invite.id).set(_inviteData(invite)));

  @override
  Future<RemoteInvite?> invite(String inviteId) => _online(() async {
    final doc = await _invite(inviteId).get(_server);
    final data = doc.data();
    return data == null ? null : _readInvite(inviteId, data);
  });

  @override
  Future<List<RemoteInvite>> invites(String householdId) => _online(() async {
    final result = await _db
        .collection('invites')
        .where('householdId', isEqualTo: householdId)
        .get(_server);
    return [for (final doc in result.docs) _readInvite(doc.id, doc.data())];
  });

  @override
  Future<void> respondToInvite(RemoteInvite invite) => _online(
    () => _invite(invite.id).update({
      'status': invite.status.name,
      'inviteeUid': invite.inviteeUid,
      if (invite.inviteePublicKey case final key?)
        'inviteePublicKey': Blob(key),
      if (invite.inviteeMac case final mac?) 'inviteeMac': Blob(mac),
      'inviteeLabel': ?invite.inviteeLabel,
    }),
  );

  @override
  Future<void> deleteInvite(String inviteId) =>
      _online(() => _invite(inviteId).delete());

  @override
  Future<void> addMember({
    required String householdId,
    required RemoteMember member,
    required List<RemoteWrappedKey> keys,
    required String inviteId,
  }) => _online(() async {
    final batch = _db.batch()
      ..set(_member(householdId, member.uid), _memberData(member))
      ..update(_invite(inviteId), {'status': InviteStatus.completed.name});
    for (final key in keys) {
      batch.set(
        _keys(householdId, member.uid).doc('${key.epoch}'),
        _keyData(key),
      );
    }
    await batch.commit();
  });

  @override
  Future<void> updateMembers(String householdId, List<RemoteMember> members) =>
      _online(() async {
        final batch = _db.batch();
        for (final m in members) {
          batch.set(_member(householdId, m.uid), _memberData(m));
        }
        await batch.commit();
      });

  @override
  Future<void> rotate({
    required String householdId,
    required int epoch,
    required List<String> removeUids,
    required List<RemoteMember> members,
    required Map<String, RemoteWrappedKey> keys,
  }) => _online(() async {
    final batch = _db.batch();
    for (final uid in removeUids) {
      for (final doc in (await _keys(householdId, uid).get(_server)).docs) {
        batch.delete(doc.reference);
      }
      batch.delete(_member(householdId, uid));
    }
    for (final m in members) {
      batch.set(_member(householdId, m.uid), _memberData(m));
    }
    for (final MapEntry(key: uid, value: key) in keys.entries) {
      batch.set(_keys(householdId, uid).doc('${key.epoch}'), _keyData(key));
    }
    batch.update(_household(householdId), {
      'epoch': epoch,
      'needsRotation': false,
    });
    await batch.commit();
  });

  @override
  Future<void> leave({required String householdId, required String uid}) =>
      _online(() async {
        final batch = _db.batch();
        for (final doc in (await _keys(householdId, uid).get(_server)).docs) {
          batch.delete(doc.reference);
        }
        batch
          ..update(_household(householdId), {'needsRotation': true})
          ..delete(_member(householdId, uid));
        await batch.commit();
      });

  @override
  Future<List<RemoteDevice>> devices(String householdId) => _online(() async {
    final result = await _household(
      householdId,
    ).collection('devices').get(_server);
    return [
      for (final doc in result.docs)
        RemoteDevice(
          deviceId: doc.id,
          uid: doc.data()['uid'] as String,
          lastSeq: doc.data()['lastSeq'] as int,
        ),
    ];
  });

  @override
  Future<List<RemoteLogEntry>> logEntries(
    String householdId,
    String deviceId, {
    required int afterSeq,
  }) => _online(() async {
    final result = await _device(householdId, deviceId)
        .collection('log')
        .where('seq', isGreaterThan: afterSeq)
        .orderBy('seq')
        .get(_server);
    return [
      for (final doc in result.docs)
        RemoteLogEntry(
          deviceId: deviceId,
          seq: doc.data()['seq'] as int,
          uid: doc.data()['uid'] as String,
          epoch: doc.data()['epoch'] as int,
          data: (doc.data()['data'] as Blob).bytes,
        ),
    ];
  });

  @override
  Future<void> appendLog(String householdId, RemoteLogEntry entry) =>
      _online(() async {
        final device = _device(householdId, entry.deviceId);
        final batch = _db.batch()
          ..set(device, {'uid': entry.uid, 'lastSeq': entry.seq})
          ..set(device.collection('log').doc('${entry.seq}'), {
            'uid': entry.uid,
            'seq': entry.seq,
            'epoch': entry.epoch,
            'data': Blob(entry.data),
          });
        await batch.commit();
      });

  @override
  Future<void> uploadMedia(String householdId, String object, File file) =>
      _online(
        () => _media(
          householdId,
          object,
        ).putFile(file, SettableMetadata(contentType: _contentType)),
      );

  @override
  Future<void> downloadMedia(String householdId, String object, File target) =>
      _online(() => _media(householdId, object).writeToFile(target));

  static Map<String, Object?> _memberData(RemoteMember m) => {
    'uid': m.uid,
    'publicKey': Blob(m.publicKey),
    'role': m.role,
    'addedBy': m.addedBy,
    'attestation': Blob(m.attestation),
    'attestedEpoch': m.attestedEpoch,
    'label': m.label,
  };

  static RemoteMember _readMember(Map<String, dynamic> d) => RemoteMember(
    uid: d['uid'] as String,
    publicKey: (d['publicKey'] as Blob).bytes,
    role: d['role'] as String,
    addedBy: d['addedBy'] as String,
    attestation: (d['attestation'] as Blob).bytes,
    attestedEpoch: d['attestedEpoch'] as int,
    label: d['label'] as String?,
  );

  static Map<String, Object?> _keyData(RemoteWrappedKey k) => {
    'epoch': k.epoch,
    'wrappedBy': k.wrappedBy,
    'wrapped': Blob(k.wrapped),
  };

  static Map<String, Object?> _inviteData(RemoteInvite i) => {
    'householdId': i.householdId,
    'inviterUid': i.inviterUid,
    'inviterPublicKey': Blob(i.inviterPublicKey),
    'inviterMac': Blob(i.inviterMac),
    'inviterLabel': i.inviterLabel,
    'createdAt': Timestamp.fromDate(i.createdAt),
    'expiresAt': Timestamp.fromDate(i.expiresAt),
    'status': i.status.name,
  };

  static RemoteInvite _readInvite(String id, Map<String, dynamic> d) {
    final inviteeKey = d['inviteePublicKey'];
    final inviteeMac = d['inviteeMac'];
    return RemoteInvite(
      id: id,
      householdId: d['householdId'] as String,
      inviterUid: d['inviterUid'] as String,
      inviterPublicKey: (d['inviterPublicKey'] as Blob).bytes,
      inviterMac: (d['inviterMac'] as Blob).bytes,
      inviterLabel: d['inviterLabel'] as String?,
      createdAt: (d['createdAt'] as Timestamp).toDate(),
      expiresAt: (d['expiresAt'] as Timestamp).toDate(),
      status: InviteStatus.values.byName(d['status'] as String),
      inviteeUid: d['inviteeUid'] as String?,
      inviteePublicKey: inviteeKey is Blob ? inviteeKey.bytes : null,
      inviteeMac: inviteeMac is Blob ? inviteeMac.bytes : null,
      inviteeLabel: d['inviteeLabel'] as String?,
    );
  }

  /// Runs [action] with the network on, then switches it off again once no
  /// other action is running. Maps every failure to a
  /// [HouseholdCloudException], which carries no data.
  Future<T> _online<T>(Future<T> Function() action) async {
    if (_active++ == 0) await _db.enableNetwork();
    try {
      return await action().timeout(_timeout);
    } on FirebaseException catch (e) {
      throw HouseholdCloudException(switch (e.code) {
        'permission-denied' ||
        'unauthenticated' ||
        'unauthorized' => HouseholdCloudError.permissionDenied,
        'not-found' || 'object-not-found' => HouseholdCloudError.notFound,
        'already-exists' => HouseholdCloudError.alreadyExists,
        'unavailable' ||
        'deadline-exceeded' ||
        'network-request-failed' ||
        'retry-limit-exceeded' => HouseholdCloudError.network,
        _ => HouseholdCloudError.unknown,
      });
    } on TimeoutException {
      throw const HouseholdCloudException(HouseholdCloudError.network);
    } on SocketException {
      throw const HouseholdCloudException(HouseholdCloudError.network);
    } on HouseholdCloudException {
      rethrow;
    } catch (_) {
      throw const HouseholdCloudException(HouseholdCloudError.unknown);
    } finally {
      if (--_active == 0) {
        try {
          await _db.disableNetwork();
        } catch (_) {
          // Switched off at the end of the next action at the latest.
        }
      }
    }
  }
}
