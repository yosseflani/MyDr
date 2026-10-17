import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/local/local_database.dart' hide VisitMedia;
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/local/repositories/local_appointment_repository.dart';
import 'package:mydr/data/media/media_file_validator.dart';
import 'package:mydr/data/media/media_picker.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/visit_media.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_visit_media_repository.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/visit_preparation/visit_media_controller.dart';

import '../../helpers/fake_media.dart';
import '../../helpers/flaky_repositories.dart';
import '../../helpers/memory_key_store.dart';

class _FlakyVisitMediaRepository extends InMemoryVisitMediaRepository {
  bool failAdd = false;
  bool failDelete = false;

  @override
  Future<void> add(VisitMedia item) async {
    if (failAdd) throw const SimulatedFailure();
    return super.add(item);
  }

  @override
  Future<void> delete(String id) async {
    if (failDelete) throw const SimulatedFailure();
    return super.delete(id);
  }
}

/// Fails deleting appointments, inside an otherwise real local database.
class _FailingDeleteAppointmentRepository extends LocalAppointmentRepository {
  _FailingDeleteAppointmentRepository(super.db);

  @override
  Future<void> delete(String id) async => throw const SimulatedFailure();
}

void main() {
  final now = DateTime(2026, 10, 17, 20, 15);
  final child = FamilyMember(
    id: 'm1',
    name: 'נועה',
    relation: FamilyRelation.child,
  );
  final sibling = FamilyMember(
    id: 'm2',
    name: 'איתי',
    relation: FamilyRelation.child,
  );
  final childVisit = Appointment(
    id: 'a1',
    memberId: 'm1',
    doctorName: 'רופאת ילדים',
    dateTime: DateTime(2026, 10, 19, 9),
  );
  final siblingVisit = Appointment(
    id: 'a2',
    memberId: 'm2',
    doctorName: 'רופאת ילדים',
    dateTime: DateTime(2026, 10, 19, 10),
  );

  late FakeMediaPicker picker;
  late FakeVisitMediaFileStore files;
  late _FlakyVisitMediaRepository mediaRepository;
  late FlakyAppointmentRepository appointmentRepository;
  late AppDependencies deps;
  late FamilyController family;
  late AppointmentController appointments;
  late VisitMediaController controller;

  VisitMediaController createController(AppDependencies dependencies) {
    final createdFamily = FamilyController(dependencies);
    final createdAppointments = AppointmentController(
      dependencies: dependencies,
      familyController: createdFamily,
    );
    final created = VisitMediaController(
      dependencies: dependencies,
      familyController: createdFamily,
      appointmentController: createdAppointments,
      clock: () => now,
    );
    family = createdFamily;
    appointments = createdAppointments;
    addTearDown(() {
      created.dispose();
      createdAppointments.dispose();
      createdFamily.dispose();
    });
    return created;
  }

  void pickPhoto([String path = '/cache/rash.jpg']) {
    files.sources[path] = fakeJpeg();
    picker.next = [PickedMedia(path)];
  }

  setUp(() async {
    picker = FakeMediaPicker();
    files = FakeVisitMediaFileStore();
    mediaRepository = _FlakyVisitMediaRepository();
    appointmentRepository = FlakyAppointmentRepository([
      childVisit,
      siblingVisit,
    ]);
    deps = AppDependencies(
      familyRepository: FlakyFamilyRepository([child, sibling]),
      appointmentRepository: appointmentRepository,
      doctorQuestionRepository: FlakyDoctorQuestionRepository(),
      symptomRepository: FlakySymptomRepository(),
      visitMediaRepository: mediaRepository,
      visitMediaFiles: files,
      mediaPicker: picker,
    );
    controller = createController(deps);
    await family.load();
    await appointments.load();
    await controller.load(cleanUpFiles: true);
  });

  group('adding', () {
    test('a photo from the camera is stored privately and recorded for the '
        'appointment and its member', () async {
      pickPhoto();

      final report = await controller.addFrom(
        childVisit,
        MediaSource.cameraPhoto,
      );

      expect(report.addedIds, hasLength(1));
      expect(report.rejected, isEmpty);
      expect(picker.requests, [MediaSource.cameraPhoto]);
      final saved = (await mediaRepository.getAll()).single;
      expect(saved.appointmentId, 'a1');
      expect(saved.memberId, 'm1');
      expect(saved.kind, VisitMediaKind.photo);
      expect(saved.createdAt, now);
      expect(files.files.keys, [saved.fileName]);
      expect(controller.forAppointment(childVisit), [saved]);
      // The picker's temporary copy is removed.
      expect(picker.discarded, ['/cache/rash.jpg']);
    });

    test('several files from the gallery, photos and videos', () async {
      files.sources['/c/1.jpg'] = fakeJpeg();
      files.sources['/c/2.mp4'] = fakeMp4();
      picker.next = const [PickedMedia('/c/1.jpg'), PickedMedia('/c/2.mp4')];

      final report = await controller.addFrom(childVisit, MediaSource.gallery);

      expect(report.addedIds, hasLength(2));
      expect(
        [for (final m in controller.forAppointment(childVisit)) m.kind],
        [VisitMediaKind.photo, VisitMediaKind.video],
      );
    });

    test(
      'the member comes from the stored appointment, not the caller',
      () async {
        pickPhoto();
        // A stale copy claiming another member.
        final stale = childVisit.copyWith(memberId: 'm2');

        await controller.addFrom(stale, MediaSource.cameraPhoto);

        expect((await mediaRepository.getAll()).single.memberId, 'm1');
      },
    );

    test('cancelling adds nothing', () async {
      picker.next = const [];

      final report = await controller.addFrom(
        childVisit,
        MediaSource.cameraPhoto,
      );

      expect(report.cancelled, isTrue);
      expect(await mediaRepository.getAll(), isEmpty);
    });

    test('a refused permission is reported, not thrown', () async {
      picker.error = const MediaPickException(MediaPickError.permissionDenied);

      final report = await controller.addFrom(
        childVisit,
        MediaSource.cameraVideo,
      );

      expect(report.pickError, MediaPickError.permissionDenied);
      expect(report.cancelled, isFalse);
      expect(await mediaRepository.getAll(), isEmpty);
      expect(controller.isAdding('a1'), isFalse);
    });

    test(
      'rejected files are reported per reason and leave nothing behind',
      () async {
        files.sources['/c/ok.jpg'] = fakeJpeg();
        files.sources['/c/text.jpg'] = fakeText();
        files.sources['/c/doc.pdf'] = fakeJpeg();
        picker.next = const [
          PickedMedia('/c/ok.jpg'),
          PickedMedia('/c/text.jpg'),
          PickedMedia('/c/doc.pdf'),
          PickedMedia('/c/missing.jpg'),
        ];

        final report = await controller.addFrom(
          childVisit,
          MediaSource.gallery,
        );

        expect(report.addedIds, hasLength(1));
        expect(report.rejectedFor(MediaFileError.unsupportedType), 2);
        expect(report.rejectedFor(MediaFileError.unreadable), 1);
        expect(files.files, hasLength(1));
        // Every temporary copy is removed, accepted or not.
        expect(picker.discarded, hasLength(4));
      },
    );

    test('if the record cannot be saved, the copied file is removed', () async {
      pickPhoto();
      mediaRepository.failAdd = true;

      final report = await controller.addFrom(
        childVisit,
        MediaSource.cameraPhoto,
      );

      expect(report.rejected, [MediaFileError.storageFailed]);
      expect(files.files, isEmpty);
      expect(await mediaRepository.getAll(), isEmpty);
    });

    test('an appointment deleted meanwhile gets nothing', () async {
      pickPhoto();
      await appointmentRepository.delete('a1');

      final report = await controller.addFrom(
        childVisit,
        MediaSource.cameraPhoto,
      );

      expect(report.appointmentMissing, isTrue);
      expect(files.files, isEmpty);
      expect(await mediaRepository.getAll(), isEmpty);
    });
  });

  test('documentation of one member never shows under another', () async {
    pickPhoto();
    await controller.addFrom(childVisit, MediaSource.cameraPhoto);

    expect(controller.forAppointment(childVisit), hasLength(1));
    expect(controller.forAppointment(siblingVisit), isEmpty);
    // Even an appointment with the same id but another member.
    expect(
      controller.forAppointment(childVisit.copyWith(memberId: 'm2')),
      isEmpty,
    );
  });

  test('descriptions can be added, changed and cleared', () async {
    pickPhoto();
    final id = (await controller.addFrom(
      childVisit,
      MediaSource.cameraPhoto,
    )).addedIds.single;

    expect(
      await controller.updateDescription(id, '  הפריחה הופיעה אתמול בערב  '),
      VisitMediaSaveResult.success,
    );
    expect(controller.mediaById(id)!.description, 'הפריחה הופיעה אתמול בערב');

    await controller.updateDescription(id, '   ');
    expect(controller.mediaById(id)!.description, isNull);

    expect(
      await controller.updateDescription('missing', 'x'),
      VisitMediaSaveResult.notFound,
    );
  });

  group('deleting', () {
    test('requires explicit confirmation', () async {
      expect(
        () => controller.delete('x', userConfirmed: false),
        throwsArgumentError,
      );
    });

    test('removes the record and the private copy', () async {
      pickPhoto();
      final id = (await controller.addFrom(
        childVisit,
        MediaSource.cameraPhoto,
      )).addedIds.single;

      expect(await controller.delete(id, userConfirmed: true), isTrue);

      expect(await mediaRepository.getAll(), isEmpty);
      expect(files.files, isEmpty);
      expect(controller.forAppointment(childVisit), isEmpty);
    });

    test('a failed deletion keeps both record and file', () async {
      pickPhoto();
      final id = (await controller.addFrom(
        childVisit,
        MediaSource.cameraPhoto,
      )).addedIds.single;
      mediaRepository.failDelete = true;

      expect(await controller.delete(id, userConfirmed: true), isFalse);

      expect(await mediaRepository.getAll(), hasLength(1));
      expect(files.files, hasLength(1));
    });

    test(
      'a file that cannot be deleted now is cleaned up on the next start',
      () async {
        pickPhoto();
        final id = (await controller.addFrom(
          childVisit,
          MediaSource.cameraPhoto,
        )).addedIds.single;
        files.failDelete = true;

        expect(await controller.delete(id, userConfirmed: true), isTrue);
        expect(files.files, hasLength(1));

        files.failDelete = false;
        final restarted = createController(deps);
        await restarted.load(cleanUpFiles: true);
        expect(files.files, isEmpty);
      },
    );

    test('deleting the appointment deletes its media and files', () async {
      pickPhoto('/c/a.jpg');
      await controller.addFrom(childVisit, MediaSource.cameraPhoto);
      pickPhoto('/c/b.jpg');
      await controller.addFrom(siblingVisit, MediaSource.cameraPhoto);

      expect(await appointments.linkedVisitMediaCount('a1'), 1);
      final result = await appointments.delete('a1', userConfirmed: true);
      await pumpEventQueue();

      expect(result.isSuccess, isTrue);
      expect(
        [for (final m in await mediaRepository.getAll()) m.memberId],
        ['m2'],
      );
      expect(files.files, hasLength(1));
      // Reloaded through visitMediaRevision.
      expect(controller.forAppointment(childVisit), isEmpty);
      expect(controller.forAppointment(siblingVisit), hasLength(1));
    });

    test('deleting the member deletes their media and files only', () async {
      pickPhoto('/c/a.jpg');
      await controller.addFrom(childVisit, MediaSource.cameraPhoto);
      pickPhoto('/c/b.jpg');
      await controller.addFrom(siblingVisit, MediaSource.cameraPhoto);

      final summary = await family.relatedDataSummary('m1');
      expect(summary!.visitMedia, 1);
      final result = await family.delete('m1', userConfirmed: true);
      await pumpEventQueue();

      expect(result.isSuccess, isTrue);
      expect(
        [for (final m in await mediaRepository.getAll()) m.memberId],
        ['m2'],
      );
      expect(files.files, hasLength(1));
      expect(controller.forAppointment(siblingVisit), hasLength(1));
    });
  });

  test('an appointment with media cannot move to another member', () async {
    pickPhoto();
    await controller.addFrom(childVisit, MediaSource.cameraPhoto);

    final result = await appointments.update(
      childVisit.copyWith(memberId: 'm2'),
    );

    expect(result, AppointmentSaveResult.hasVisitMedia);
    expect((await appointmentRepository.getById('a1'))!.memberId, 'm1');
    expect((await mediaRepository.getAll()).single.memberId, 'm1');
    // Other edits are still allowed.
    expect(
      await appointments.update(childVisit.copyWith(doctorName: 'רופא אחר')),
      AppointmentSaveResult.success,
    );
  });

  test('start-up clean-up removes only unreferenced files', () async {
    pickPhoto();
    await controller.addFrom(childVisit, MediaSource.cameraPhoto);
    files.store('/leftover.jpg', fakeJpeg());
    expect(files.files, hasLength(2));

    final restarted = createController(deps);
    await restarted.load(cleanUpFiles: true);

    expect(files.files, hasLength(1));
    expect(restarted.forAppointment(childVisit), hasLength(1));
  });

  group('with the encrypted local database', () {
    late Directory directory;
    late File databaseFile;
    late MemoryDatabaseKeyStore keys;

    setUp(() {
      directory = Directory.systemTemp.createTempSync('mydr_media_ctrl');
      databaseFile = File('${directory.path}/db.sqlite');
      keys = MemoryDatabaseKeyStore();
    });

    tearDown(() => directory.deleteSync(recursive: true));

    Future<LocalDatabase> open() => LocalDatabaseOpener(
      keyStore: keys,
      locateFile: () async => databaseFile,
    ).open();

    test(
      'a photo and its description are still there after a restart',
      () async {
        var database = await open();
        var local = AppDependencies.local(
          database,
          visitMediaFiles: files,
          mediaPicker: picker,
        );
        await local.familyRepository.add(child);
        await local.appointmentRepository.add(childVisit);
        var media = createController(local);
        await media.load();
        pickPhoto();
        final id = (await media.addFrom(
          childVisit,
          MediaSource.cameraPhoto,
        )).addedIds.single;
        await media.updateDescription(id, 'הפריחה הופיעה אתמול בערב');
        await database.close();

        database = await open();
        addTearDown(database.close);
        local = AppDependencies.local(
          database,
          visitMediaFiles: files,
          mediaPicker: picker,
        );
        media = createController(local);
        await media.load(cleanUpFiles: true);

        final restored = media.forAppointment(childVisit).single;
        expect(restored.description, 'הפריחה הופיעה אתמול בערב');
        expect(await media.readPhoto(restored), isNotNull);
      },
    );

    test(
      'a failed appointment deletion rolls back and keeps media and files',
      () async {
        final database = await open();
        addTearDown(database.close);
        final base = AppDependencies.local(
          database,
          visitMediaFiles: files,
          mediaPicker: picker,
        );
        await base.familyRepository.add(child);
        await base.appointmentRepository.add(childVisit);
        final failing = AppDependencies(
          familyRepository: base.familyRepository,
          appointmentRepository: _FailingDeleteAppointmentRepository(database),
          doctorQuestionRepository: base.doctorQuestionRepository,
          symptomRepository: base.symptomRepository,
          visitMediaRepository: base.visitMediaRepository,
          visitMediaFiles: files,
          mediaPicker: picker,
          transactions: base.transactions,
          persistsData: true,
        );
        final media = createController(failing);
        await media.load();
        pickPhoto();
        await media.addFrom(childVisit, MediaSource.cameraPhoto);

        final result = await appointments.delete('a1', userConfirmed: true);

        expect(result.failedStep, AppointmentDeletionStep.appointment);
        expect(await base.visitMediaRepository.getAll(), hasLength(1));
        expect(files.files, hasLength(1));
      },
    );
  });
}
