import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/backup/backup_cipher.dart';
import 'package:mydr/data/backup/backup_data_store.dart';
import 'package:mydr/data/backup/backup_service.dart';
import 'package:mydr/data/backup/backup_snapshot.dart';
import 'package:mydr/data/backup/recovery_key.dart';
import 'package:mydr/data/cloud/backup_storage.dart';
import 'package:mydr/data/local/local_database.dart' hide VisitMedia;
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/media/visit_media_file_store.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/models/visit_media.dart';

import '../../helpers/fake_cloud.dart';
import '../../helpers/fake_media.dart';
import '../../helpers/memory_key_store.dart';

/// One phone: its own encrypted database, media folder and scratch folder.
class _Device {
  _Device._(this.root, this.database, this.files, this.deps);

  final Directory root;
  final LocalDatabase database;
  final PrivateVisitMediaFileStore files;
  final AppDependencies deps;

  static Future<_Device> create(Directory parent, String name) async {
    final root = Directory('${parent.path}/$name')..createSync();
    final database = await LocalDatabaseOpener(
      keyStore: MemoryDatabaseKeyStore(),
      locateFile: () async => File('${root.path}/mydr.sqlite'),
    ).open();
    final files = PrivateVisitMediaFileStore(
      locateDirectory: () async => Directory('${root.path}/media'),
    );
    return _Device._(
      root,
      database,
      files,
      AppDependencies.local(database, visitMediaFiles: files),
    );
  }

  BackupService service(BackupStorage storage, {Random? random}) =>
      BackupService(
        storage: storage,
        data: RepositoryBackupDataStore(deps),
        mediaFiles: files,
        workDirectory: () async => Directory('${root.path}/work'),
        random: random,
      );

  Future<BackupSnapshot> snapshot() => RepositoryBackupDataStore(deps).export();

  List<String> mediaFileNames() {
    final dir = Directory('${root.path}/media');
    if (!dir.existsSync()) return const [];
    return [
      for (final f in dir.listSync().whereType<File>()) f.uri.pathSegments.last,
    ]..sort();
  }

  bool workIsEmpty() {
    final dir = Directory('${root.path}/work');
    return !dir.existsSync() ||
        dir.listSync(recursive: true).whereType<File>().isEmpty;
  }
}

void main() {
  const uid = 'uid-a';
  final key = RecoveryKey.generate(Random(1));
  final photo = fakeJpeg(5000);
  final video = fakeMp4(BackupCipher.chunkSize + 77);

  late Directory temp;
  late FakeBackupStorage storage;
  late _Device phoneA;
  late _Device phoneB;

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('mydr_backup');
    storage = FakeBackupStorage(currentUid: () => uid);
    phoneA = await _Device.create(temp, 'a');
    phoneB = await _Device.create(temp, 'b');
  });

  tearDown(() async {
    await phoneA.database.close();
    await phoneB.database.close();
    temp.deleteSync(recursive: true);
  });

  /// Fictional records of every kind, with a photo and a video.
  Future<void> seed(_Device device, {String prefix = ''}) async {
    final d = device.deps;
    await d.familyRepository.add(
      FamilyMember(
        id: '${prefix}m1',
        name: 'דנה $prefix',
        relation: FamilyRelation.self,
        birthDate: DateTime(1988, 4, 12),
        allergies: const ['אבקה'],
      ),
    );
    await d.familyRepository.add(
      FamilyMember(
        id: '${prefix}m2',
        name: 'נועה',
        relation: FamilyRelation.child,
      ),
    );
    await d.appointmentRepository.add(
      Appointment(
        id: '${prefix}a1',
        memberId: '${prefix}m2',
        doctorName: 'רופאה',
        dateTime: DateTime(2026, 11, 2, 9, 30),
        location: 'מרפאה',
      ),
    );
    await d.doctorQuestionRepository.add(
      DoctorQuestion(
        id: '${prefix}q1',
        memberId: '${prefix}m2',
        appointmentId: '${prefix}a1',
        text: 'שאלה',
        createdAt: DateTime(2026, 10, 1, 8, 0, 0, 0, 123),
        isResolved: true,
        doctorAnswer: 'תשובה',
      ),
    );
    await d.symptomRepository.add(
      SymptomEntry(
        id: '${prefix}s1',
        memberId: '${prefix}m2',
        name: 'שיעול',
        startedAt: DateTime(2026, 10, 10, 21),
        severity: 3,
        status: SymptomStatus.resolved,
        duration: const Duration(hours: 5),
      ),
    );
    await d.medicationRepository.add(
      Medication(
        id: '${prefix}med1',
        memberId: '${prefix}m1',
        name: 'תרופה',
        dose: '1 tablet',
        instructions: 'בבוקר',
        reminderTimes: [DoseTime(8, 0), DoseTime(20, 0)],
        startDate: DateTime(2026, 10, 1),
        endDate: DateTime(2026, 12, 31),
      ),
    );
    await d.doseRecordRepository.save(
      DoseRecord(
        id: '${prefix}r1',
        memberId: '${prefix}m1',
        medicationId: '${prefix}med1',
        scheduledAt: DateTime(2026, 10, 2, 8),
        status: DoseStatus.taken,
        recordedAt: DateTime(2026, 10, 2, 8, 4, 0, 0, 5),
      ),
    );
    for (final (index, (bytes, kind)) in [
      (photo, VisitMediaKind.photo),
      (video, VisitMediaKind.video),
    ].indexed) {
      final source = File(
        '${temp.path}/$prefix-src$index.${kind == VisitMediaKind.photo ? 'jpg' : 'mp4'}',
      )..writeAsBytesSync(bytes);
      final stored = await device.files.import(source.path);
      await d.visitMediaRepository.add(
        VisitMedia(
          id: '${prefix}v$index',
          memberId: '${prefix}m2',
          appointmentId: '${prefix}a1',
          kind: kind,
          fileName: stored.fileName,
          byteSize: stored.byteSize,
          createdAt: DateTime(2026, 10, 3, 10, index),
          description: 'תיאור $index',
        ),
      );
    }
  }

  /// The records ignoring media file names, which change on restore.
  String comparable(BackupSnapshot s) => jsonEncode({
    'snapshot': utf8.decode(
      s.withMediaFileNames({
        for (final m in s.visitMedia) m.fileName: 'x',
      }).encode(),
    ),
  });

  Future<RemoteBackup> backUp(_Device device) =>
      device.service(storage).createBackup(uid: uid, key: key);

  test(
    'a backup restores exactly on another phone (records and files)',
    () async {
      await seed(phoneA);
      final progress = <double>[];
      final backup = await phoneA
          .service(storage)
          .createBackup(uid: uid, key: key, onProgress: progress.add);

      expect(progress.first, 0);
      expect(progress.last, 1);
      expect(await phoneA.service(storage).listBackups(uid), [backup]);
      expect(phoneA.workIsEmpty(), isTrue);

      final service = phoneB.service(storage);
      final prepared = await service.prepareRestore(
        uid: uid,
        backup: backup,
        key: key,
      );
      expect(prepared.counts.familyMembers, 2);
      expect(prepared.counts.visitMedia, 2);
      expect(prepared.missingFiles, 0);
      // Nothing changed before confirming.
      expect((await phoneB.snapshot()).counts.isEmpty, isTrue);

      await service.applyRestore(prepared, userConfirmed: true);

      final restored = await phoneB.snapshot();
      expect(comparable(restored), comparable(await phoneA.snapshot()));
      for (final media in restored.visitMedia) {
        final bytes = await phoneB.files.readBytes(media.fileName);
        expect(bytes, media.kind == VisitMediaKind.photo ? photo : video);
      }
      expect(phoneB.mediaFileNames(), hasLength(2));
      expect(phoneB.workIsEmpty(), isTrue);
    },
  );

  test('nothing readable reaches the cloud', () async {
    await seed(phoneA);
    await backUp(phoneA);

    final uploaded = latin1.decode(storage.allBytes, allowInvalid: true);
    for (final secret in ['דנה', 'אבקה', 'mydr-backup', 'familyMembers']) {
      final encoded = latin1.decode(utf8.encode(secret));
      expect(uploaded, isNot(contains(encoded)), reason: secret);
    }
    // Not even the media files' content.
    final photoSample = latin1.decode(photo.sublist(100, 140));
    expect(uploaded, isNot(contains(photoSample)));
    // Only objects of this account, under its folder.
    expect(
      storage.objects.keys.every((k) => k.startsWith('users/$uid/')),
      isTrue,
    );
    expect(storage.metadataOf.values.expand((m) => m.keys).toSet(), {
      'createdAt',
      'totalBytes',
      'formatVersion',
    });
  });

  test('the wrong recovery key restores nothing', () async {
    await seed(phoneA);
    await seed(phoneB, prefix: 'b-');
    final before = await phoneB.snapshot();
    final backup = await backUp(phoneA);

    await expectLater(
      phoneB
          .service(storage)
          .prepareRestore(
            uid: uid,
            backup: backup,
            key: RecoveryKey.generate(Random(99)),
          ),
      throwsA(
        isA<BackupException>().having(
          (e) => e.failure,
          'failure',
          BackupFailure.wrongKey,
        ),
      ),
    );
    expect(
      await phoneB
          .service(storage)
          .keyMatches(
            uid: uid,
            backup: backup,
            key: RecoveryKey.generate(Random(99)),
          ),
      isFalse,
    );
    expect(
      await phoneB
          .service(storage)
          .keyMatches(uid: uid, backup: backup, key: key),
      isTrue,
    );
    expect(comparable(await phoneB.snapshot()), comparable(before));
    expect(phoneB.workIsEmpty(), isTrue);
  });

  test('a changed or swapped object is refused and changes nothing', () async {
    await seed(phoneA);
    final backup = await backUp(phoneA);
    final folder = 'users/$uid/backups/${backup.id}';

    // Swap the two media objects.
    final first = storage.objects['$folder/media/0.bin']!;
    storage.objects['$folder/media/0.bin'] =
        storage.objects['$folder/media/1.bin']!;
    storage.objects['$folder/media/1.bin'] = first;
    await expectLater(
      phoneB
          .service(storage)
          .prepareRestore(uid: uid, backup: backup, key: key),
      throwsA(
        isA<BackupException>().having(
          (e) => e.failure,
          'failure',
          BackupFailure.damaged,
        ),
      ),
    );
    storage.objects['$folder/media/1.bin'] =
        storage.objects['$folder/media/0.bin']!;
    storage.objects['$folder/media/0.bin'] = first;

    // Flip one byte of the data.
    final data = storage.objects['$folder/data.bin']!;
    storage.objects['$folder/data.bin'] = Uint8List.fromList(data)
      ..[data.length - 3] ^= 1;
    await expectLater(
      phoneB
          .service(storage)
          .prepareRestore(uid: uid, backup: backup, key: key),
      throwsA(isA<BackupException>()),
    );
    expect((await phoneB.snapshot()).counts.isEmpty, isTrue);
    expect(phoneB.mediaFileNames(), isEmpty);
    expect(phoneB.workIsEmpty(), isTrue);
  });

  test('a network failure while uploading keeps the previous backup', () async {
    await seed(phoneA);
    final first = await backUp(phoneA);
    final objectsBefore = Map.of(storage.objects);

    // Fails on the second upload (the first media file).
    storage
      ..uploads = 0
      ..failUploadNumber = 2;
    await expectLater(
      backUp(phoneA),
      throwsA(
        isA<BackupException>().having(
          (e) => e.failure,
          'failure',
          BackupFailure.network,
        ),
      ),
    );

    expect(await phoneA.service(storage).listBackups(uid), [first]);
    // The partial upload was cleaned up; the old backup is untouched.
    expect(storage.objects.keys.toSet(), objectsBefore.keys.toSet());
    expect(phoneA.workIsEmpty(), isTrue);
    // And still restores.
    final prepared = await phoneB
        .service(storage)
        .prepareRestore(uid: uid, backup: first, key: key);
    await phoneB.service(storage).applyRestore(prepared, userConfirmed: true);
    expect((await phoneB.snapshot()).counts.familyMembers, 2);
  });

  test(
    'a network failure while restoring leaves the phone unchanged',
    () async {
      await seed(phoneA);
      await seed(phoneB, prefix: 'b-');
      final before = await phoneB.snapshot();
      final filesBefore = phoneB.mediaFileNames();
      final backup = await backUp(phoneA);

      storage.failDownloadsContaining = 'media/1.bin';
      await expectLater(
        phoneB
            .service(storage)
            .prepareRestore(uid: uid, backup: backup, key: key),
        throwsA(
          isA<BackupException>().having(
            (e) => e.failure,
            'failure',
            BackupFailure.network,
          ),
        ),
      );

      expect(comparable(await phoneB.snapshot()), comparable(before));
      expect(phoneB.mediaFileNames(), filesBefore);
      expect(phoneB.workIsEmpty(), isTrue);
    },
  );

  test('restoring requires confirmation, and cancelling discards it', () async {
    await seed(phoneA);
    final backup = await backUp(phoneA);
    final service = phoneB.service(storage);
    final prepared = await service.prepareRestore(
      uid: uid,
      backup: backup,
      key: key,
    );

    await expectLater(
      service.applyRestore(prepared, userConfirmed: false),
      throwsArgumentError,
    );
    await service.discard(prepared);
    expect((await phoneB.snapshot()).counts.isEmpty, isTrue);
    expect(phoneB.workIsEmpty(), isTrue);
  });

  test(
    'restoring over existing data replaces all of it, files included',
    () async {
      await seed(phoneA);
      await seed(phoneB, prefix: 'b-');
      final oldFiles = phoneB.mediaFileNames();
      final backup = await backUp(phoneA);
      final service = phoneB.service(storage);

      await service.applyRestore(
        await service.prepareRestore(uid: uid, backup: backup, key: key),
        userConfirmed: true,
      );

      final restored = await phoneB.snapshot();
      expect(comparable(restored), comparable(await phoneA.snapshot()));
      expect(restored.familyMembers.map((m) => m.id), isNot(contains('b-m1')));
      // The replaced data's files are gone; only the restored ones remain.
      final files = phoneB.mediaFileNames();
      expect(files, hasLength(2));
      expect(files.toSet().intersection(oldFiles.toSet()), isEmpty);
    },
  );

  test(
    'a failure while saving the restore keeps the phone as it was',
    () async {
      await seed(phoneA);
      await seed(phoneB, prefix: 'b-');
      final before = await phoneB.snapshot();
      final filesBefore = phoneB.mediaFileNames();
      final backup = await backUp(phoneA);
      final prepared = await phoneB
          .service(storage)
          .prepareRestore(uid: uid, backup: backup, key: key);

      // The last step of the transaction fails.
      final failing = BackupService(
        storage: storage,
        data: _FailingAfterReplace(
          RepositoryBackupDataStore(phoneB.deps),
          phoneB,
        ),
        mediaFiles: phoneB.files,
        workDirectory: () async => Directory('${phoneB.root.path}/work'),
      );
      await expectLater(
        failing.applyRestore(prepared, userConfirmed: true),
        throwsA(
          isA<BackupException>().having(
            (e) => e.failure,
            'failure',
            BackupFailure.localWriteFailed,
          ),
        ),
      );

      expect(comparable(await phoneB.snapshot()), comparable(before));
      // The restored files that were already imported were removed again.
      expect(phoneB.mediaFileNames(), filesBefore);
    },
  );

  test('keeps the newest two backups', () async {
    await seed(phoneA);
    var now = DateTime.utc(2026, 10, 1, 12);
    BackupService service() => BackupService(
      storage: storage,
      data: RepositoryBackupDataStore(phoneA.deps),
      mediaFiles: phoneA.files,
      workDirectory: () async => Directory('${phoneA.root.path}/work'),
      clock: () => now = now.add(const Duration(days: 1)),
    );

    final backups = [
      for (var i = 0; i < 4; i++)
        await service().createBackup(uid: uid, key: key),
    ];

    final listed = await service().listBackups(uid);
    expect(listed.map((b) => b.id), [backups[3].id, backups[2].id]);
    expect(
      storage.objects.keys.where(
        (k) => k.contains(backups[0].id) || k.contains(backups[1].id),
      ),
      isEmpty,
    );
  });

  test("another account's backups cannot be listed or read", () async {
    await seed(phoneA);
    final backup = await backUp(phoneA);
    final other = FakeBackupStorage(currentUid: () => 'uid-b')
      ..objects.addAll(storage.objects)
      ..metadataOf.addAll(storage.metadataOf);
    final service = phoneB.service(other);

    await expectLater(
      service.listBackups(uid),
      throwsA(
        isA<BackupException>().having(
          (e) => e.failure,
          'failure',
          BackupFailure.unauthorized,
        ),
      ),
    );
    await expectLater(
      service.prepareRestore(uid: uid, backup: backup, key: key),
      throwsA(isA<BackupException>()),
    );
  });

  test('a backup from a newer app version is refused', () async {
    await seed(phoneA);
    final backup = await backUp(phoneA);
    final folder = 'users/$uid/backups/${backup.id}';
    final cipher = BackupCipher(key);
    storage.objects['$folder/manifest.bin'] = await cipher.encryptBytes(
      utf8.encode(jsonEncode({'formatVersion': 99, 'backupId': backup.id})),
      context: '${backup.id}/manifest.bin',
    );

    await expectLater(
      phoneB
          .service(storage)
          .prepareRestore(uid: uid, backup: backup, key: key),
      throwsA(
        isA<BackupException>().having(
          (e) => e.failure,
          'failure',
          BackupFailure.unsupported,
        ),
      ),
    );
  });

  test('a photo already missing is skipped, its record kept', () async {
    await seed(phoneA);
    final photoRecord = (await phoneA.snapshot()).visitMedia.first;
    await phoneA.files.delete(photoRecord.fileName);

    final backup = await backUp(phoneA);
    final prepared = await phoneB
        .service(storage)
        .prepareRestore(uid: uid, backup: backup, key: key);
    expect(prepared.missingFiles, 1);
    await phoneB.service(storage).applyRestore(prepared, userConfirmed: true);

    expect((await phoneB.snapshot()).visitMedia, hasLength(2));
    expect(phoneB.mediaFileNames(), hasLength(1));
  });
}

/// Saves everything, then fails, inside the transaction: the local
/// database must roll it all back.
class _FailingAfterReplace implements BackupDataStore {
  _FailingAfterReplace(this._inner, this._device);

  final RepositoryBackupDataStore _inner;
  final _Device _device;

  @override
  Future<BackupSnapshot> export() => _inner.export();

  @override
  Future<void> replaceAll(BackupSnapshot snapshot) =>
      _device.deps.transactions.run(() async {
        await _inner.replaceAll(snapshot);
        throw StateError('simulated failure after writing');
      });
}
