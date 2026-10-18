import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:mydr/data/cloud/account_service.dart';
import 'package:mydr/data/cloud/backup_storage.dart';
import 'package:mydr/data/cloud/cloud_backend.dart';

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
    }
    return CloudServices(
      accounts: FirebaseAccountService(auth),
      storage: FirebaseBackupStorage(storage),
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
