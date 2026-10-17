import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/media/media_picker.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_visit_media_repository.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/appointments/appointment_detail_screen.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/visit_preparation/visit_media_controller.dart';
import 'package:mydr/features/visit_preparation/visit_media_viewer_screen.dart';
import 'package:mydr/features/visit_preparation/widgets/visit_media_section.dart';

import '../../helpers/fake_media.dart';
import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  final now = DateTime(2026, 10, 17, 20);
  DateTime clock() => now;

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
    doctorName: 'ד״ר לוי',
    dateTime: DateTime(2026, 10, 19, 9),
  );
  final siblingVisit = Appointment(
    id: 'a2',
    memberId: 'm2',
    doctorName: 'ד״ר כהן',
    dateTime: DateTime(2026, 10, 19, 10),
  );

  late FakeMediaPicker picker;
  late FakeVisitMediaFileStore files;
  late InMemoryVisitMediaRepository mediaRepository;
  late AppDependencies dependencies;
  late FamilyController family;
  late AppointmentController appointments;
  late VisitMediaController media;

  setUp(() async {
    picker = FakeMediaPicker();
    files = FakeVisitMediaFileStore();
    mediaRepository = InMemoryVisitMediaRepository();
    dependencies = AppDependencies(
      familyRepository: FlakyFamilyRepository([child, sibling]),
      appointmentRepository: FlakyAppointmentRepository([
        childVisit,
        siblingVisit,
      ]),
      doctorQuestionRepository: FlakyDoctorQuestionRepository(),
      symptomRepository: FlakySymptomRepository(),
      visitMediaRepository: mediaRepository,
      visitMediaFiles: files,
      mediaPicker: picker,
    );
    family = FamilyController(dependencies);
    appointments = AppointmentController(
      dependencies: dependencies,
      familyController: family,
    );
    media = VisitMediaController(
      dependencies: dependencies,
      familyController: family,
      appointmentController: appointments,
      clock: clock,
    );
    await family.load();
    await appointments.load();
    await media.load();
  });

  tearDown(() {
    media.dispose();
    appointments.dispose();
    family.dispose();
  });

  Future<void> openDetails(WidgetTester tester, String appointmentId) async {
    tester.setScreenSize(const Size(420, 2400));
    await tester.pumpApp(
      AppointmentDetailScreen(appointmentId: appointmentId, clock: clock),
      dependencies: dependencies,
      familyController: family,
      appointmentController: appointments,
      visitMediaController: media,
    );
    await tester.pumpAndSettle();
  }

  void preparePhoto([String path = '/cache/rash.jpg']) {
    files.sources[path] = fakeJpeg();
    picker.next = [PickedMedia(path)];
  }

  Future<void> tapButton(WidgetTester tester, String label) async {
    final button = find.text(label);
    await tester.ensureVisible(button);
    await tester.tap(button);
    await tester.pumpAndSettle();
  }

  testWidgets('the appointment shows the visit preparation section', (
    tester,
  ) async {
    await openDetails(tester, 'a1');

    expect(find.text(AppStrings.visitPreparationTitle), findsOneWidget);
    // The existing questions feature, reused.
    expect(find.text(AppStrings.doctorQuestionsTitle), findsOneWidget);
    expect(find.text(AppStrings.addQuestionToAppointment), findsOneWidget);
    expect(find.text(AppStrings.visitMediaTitle), findsOneWidget);
    expect(find.text(AppStrings.visitMediaEmpty), findsOneWidget);
    expect(find.text(AppStrings.visitMediaPrivacyNote), findsOneWidget);
    expect(find.text(AppStrings.takePhoto), findsOneWidget);
    expect(find.text(AppStrings.recordVideo), findsOneWidget);
    expect(find.text(AppStrings.chooseFromGallery), findsOneWidget);
  });

  testWidgets('taking a photo saves it and asks for a description right away', (
    tester,
  ) async {
    preparePhoto();
    await openDetails(tester, 'a1');

    await tapButton(tester, AppStrings.takePhoto);

    expect(picker.requests, [MediaSource.cameraPhoto]);
    expect(find.text(AppStrings.visitMediaDescriptionTitle), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'הפריחה הופיעה אתמול בערב');
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.save));
    await tester.pumpAndSettle();

    expect(find.byType(VisitMediaTile), findsOneWidget);
    expect(find.text('הפריחה הופיעה אתמול בערב'), findsOneWidget);
    expect(find.text(AppStrings.visitMediaEmpty), findsNothing);
    final saved = (await mediaRepository.getAll()).single;
    expect(saved.memberId, 'm1');
    expect(saved.description, 'הפריחה הופיעה אתמול בערב');
  });

  testWidgets('a video from the gallery appears as a video', (tester) async {
    files.sources['/cache/cough.mp4'] = fakeMp4();
    picker.next = const [PickedMedia('/cache/cough.mp4')];
    await openDetails(tester, 'a1');

    await tapButton(tester, AppStrings.chooseFromGallery);
    // Skips the description.
    await tester.tap(find.widgetWithText(TextButton, AppStrings.cancel));
    await tester.pumpAndSettle();

    expect(find.byType(VisitMediaTile), findsOneWidget);
    expect(
      find.textContaining('${AppStrings.visitMediaVideo} · '),
      findsOneWidget,
    );
    expect(find.text(AppStrings.visitMediaNoDescription), findsOneWidget);
  });

  testWidgets(
    'a refused camera permission shows a clear message and nothing breaks',
    (tester) async {
      picker.error = const MediaPickException(MediaPickError.permissionDenied);
      await openDetails(tester, 'a1');

      await tapButton(tester, AppStrings.takePhoto);

      expect(find.text(AppStrings.cameraPermissionDenied), findsOneWidget);
      expect(tester.takeException(), isNull);
      // The other options still work.
      picker.error = null;
      preparePhoto();
      await tapButton(tester, AppStrings.chooseFromGallery);
      expect(find.text(AppStrings.visitMediaDescriptionTitle), findsOneWidget);
    },
  );

  testWidgets('an unsupported file is explained and not saved', (tester) async {
    files.sources['/cache/notes.jpg'] = fakeText();
    picker.next = const [PickedMedia('/cache/notes.jpg')];
    await openDetails(tester, 'a1');

    await tapButton(tester, AppStrings.chooseFromGallery);

    expect(find.text(AppStrings.mediaRejectedUnsupported(1)), findsOneWidget);
    expect(find.byType(VisitMediaTile), findsNothing);
    expect(files.files, isEmpty);
  });

  testWidgets('deleting asks first; confirming removes the record and file', (
    tester,
  ) async {
    preparePhoto();
    await media.addFrom(childVisit, MediaSource.cameraPhoto);
    await openDetails(tester, 'a1');

    Future<void> openDelete() async {
      await tester.tap(find.byTooltip(AppStrings.visitMediaMoreActions));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.deleteVisitMedia));
      await tester.pumpAndSettle();
    }

    await openDelete();
    expect(find.text(AppStrings.deleteVisitMediaTitle), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, AppStrings.cancel));
    await tester.pumpAndSettle();
    expect(find.byType(VisitMediaTile), findsOneWidget);
    expect(files.files, hasLength(1));

    await openDelete();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.delete));
    await tester.pumpAndSettle();

    expect(find.byType(VisitMediaTile), findsNothing);
    expect(find.text(AppStrings.visitMediaDeleted), findsOneWidget);
    expect(await mediaRepository.getAll(), isEmpty);
    expect(files.files, isEmpty);
  });

  testWidgets("another member's appointment does not show the photo", (
    tester,
  ) async {
    preparePhoto();
    await media.addFrom(childVisit, MediaSource.cameraPhoto);

    await openDetails(tester, 'a2');

    expect(find.byType(VisitMediaTile), findsNothing);
    expect(find.text(AppStrings.visitMediaEmpty), findsOneWidget);
  });

  testWidgets('the viewer shows the description and handles a missing file', (
    tester,
  ) async {
    preparePhoto();
    final id = (await media.addFrom(
      childVisit,
      MediaSource.cameraPhoto,
    )).addedIds.single;
    await media.updateDescription(id, 'פריחה ביד');
    files.files.clear();
    await openDetails(tester, 'a1');

    await tester.tap(find.byType(VisitMediaTile));
    await tester.pumpAndSettle();

    expect(find.byType(VisitMediaViewerScreen), findsOneWidget);
    expect(find.text('פריחה ביד'), findsOneWidget);
    expect(find.text(AppStrings.mediaFileMissing), findsOneWidget);
    // The record can still be deleted from the viewer.
    await tester.tap(find.byTooltip(AppStrings.deleteVisitMedia));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.delete));
    await tester.pumpAndSettle();
    expect(find.byType(VisitMediaViewerScreen), findsNothing);
    expect(await mediaRepository.getAll(), isEmpty);
  });

  testWidgets('deleting the appointment says its media will be deleted too', (
    tester,
  ) async {
    preparePhoto();
    await media.addFrom(childVisit, MediaSource.cameraPhoto);
    await openDetails(tester, 'a1');

    final delete = find.text(AppStrings.deleteAppointment);
    await tester.ensureVisible(delete);
    await tester.tap(delete);
    await tester.pumpAndSettle();

    expect(find.text(AppStrings.deleteAppointmentMedia(1)), findsOneWidget);
  });

  testWidgets('lays out on a narrow screen with large text', (tester) async {
    preparePhoto();
    await media.addFrom(childVisit, MediaSource.cameraPhoto);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    tester.setScreenSize(const Size(320, 4000));
    await tester.pumpApp(
      AppointmentDetailScreen(appointmentId: 'a1', clock: clock),
      dependencies: dependencies,
      familyController: family,
      appointmentController: appointments,
      visitMediaController: media,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(VisitMediaSection), findsOneWidget);
  });
}
