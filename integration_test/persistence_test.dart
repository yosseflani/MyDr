import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mydr/app_bootstrap.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/local/database_key_store.dart';
import 'package:mydr/data/local/local_database_opener.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/shell/home_shell.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/symptoms/widgets/symptom_card.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../test/helpers/fake_emergency_dialer.dart';

/// The real app start-up (MyDrBootstrap) on a device: the platform's
/// SQLCipher and the Android Keystore, across several "restarts" of the
/// app. Each test starts the app afresh from the same encrypted file.
///
///   `flutter test integration_test/persistence_test.dart -d DEVICE`
///
/// Uses its own file and key name and removes both at the end, so the
/// app's real data is never touched. All data is fictional.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const keyName = 'mydr.database_key.persistence_test';
  const storage = FlutterSecureStorage(aOptions: AndroidOptions());
  late File file;

  setUpAll(() async {
    final directory = await getApplicationSupportDirectory();
    file = File(p.join(directory.path, 'persistence_test.sqlite'));
    if (file.existsSync()) file.deleteSync();
    await storage.delete(key: keyName);
  });

  tearDownAll(() async {
    if (file.existsSync()) file.deleteSync();
    await storage.delete(key: keyName);
  });

  /// Starts the app on the test database and returns its scope.
  Future<AppScope> startApp(WidgetTester tester) async {
    await tester.pumpWidget(
      MyDrBootstrap(
        openDatabase: () => LocalDatabaseOpener(
          keyStore: const SecureDatabaseKeyStore(keyName: keyName),
          locateFile: () async => file,
        ).open(),
        emergencyDialer: FakeEmergencyDialer(),
      ),
    );
    // Opening goes through the Keystore, a platform call: wait for it.
    final deadline = DateTime.now().add(const Duration(seconds: 20));
    while (find.byType(HomeShell).evaluate().isEmpty &&
        DateTime.now().isBefore(deadline)) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    await tester.pumpAndSettle();
    expect(find.byType(HomeShell), findsOneWidget);
    return AppScope.of(tester.element(find.byType(HomeShell)));
  }

  /// Closes the app, and with it the database.
  Future<void> stopApp(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox());
    await tester.pumpAndSettle();
    await Future<void>.delayed(const Duration(milliseconds: 200));
  }

  testWidgets('1. first start is empty; add one of each record', (
    tester,
  ) async {
    final scope = await startApp(tester);
    expect(scope.dependencies.persistsData, isTrue);
    expect(scope.familyController.members, isEmpty);
    expect(find.text(AppStrings.demoDataBanner), findsNothing);

    final family = scope.familyController;
    expect(
      await family.add(
        FamilyMember(
          id: family.createId(),
          name: 'נועה בדיקה',
          relation: FamilyRelation.child,
          allergies: const ['אבקה'],
        ),
      ),
      FamilySaveResult.success,
    );
    final memberId = family.members.single.id;

    final appointments = scope.appointmentController;
    final appointmentResult = await appointments.add(
      Appointment(
        id: appointments.createId(),
        memberId: memberId,
        doctorName: 'רופא בדיקה',
        dateTime: DateTime.now().add(const Duration(days: 3)),
      ),
    );
    expect(appointmentResult, AppointmentSaveResult.success);
    final appointmentId = appointments.appointments.single.id;

    final questions = scope.doctorQuestionController;
    final questionResult = await questions.add(
      DoctorQuestion(
        id: questions.createId(),
        memberId: memberId,
        appointmentId: appointmentId,
        text: 'שאלת בדיקה',
        createdAt: DateTime.now(),
      ),
    );
    expect(questionResult, QuestionSaveResult.success);
    final symptoms = scope.symptomController;
    final symptomResult = await symptoms.add(
      SymptomEntry(
        id: symptoms.createId(),
        memberId: memberId,
        name: 'תסמין בדיקה',
        startedAt: DateTime.now().subtract(const Duration(hours: 1)),
        severity: 2,
      ),
    );
    expect(symptomResult, SymptomSaveResult.success);

    // Today's 08:00 dose is always recordable, whatever the time now.
    final medications = scope.medicationController;
    final today = DateTime.now();
    final medicationResult = await medications.add(
      Medication(
        id: medications.createId(),
        memberId: memberId,
        name: 'תרופת בדיקה',
        dose: '1 tablet',
        reminderTimes: [DoseTime(8, 0)],
        startDate: today,
        endDate: today.add(const Duration(days: 7)),
      ),
    );
    expect(medicationResult, MedicationSaveResult.success);
    final dose = DateTime(today.year, today.month, today.day, 8);
    expect(
      await medications.recordDose(
        medications.medications.single.id,
        dose,
        DoseStatus.taken,
      ),
      DoseRecordResult.success,
    );
    await tester.pumpAndSettle();

    expect(appointments.appointments, hasLength(1));
    expect(questions.questions, hasLength(1));
    expect(symptoms.entries, hasLength(1));
    expect(medications.records(), hasLength(1));
    await stopApp(tester);
  });

  testWidgets('2. after a restart everything is there; edit it', (
    tester,
  ) async {
    final scope = await startApp(tester);
    final member = scope.familyController.members.single;
    expect(member.name, 'נועה בדיקה');
    expect(member.allergies, ['אבקה']);
    expect(
      scope.appointmentController.appointments.single.doctorName,
      'רופא בדיקה',
    );
    final question = scope.doctorQuestionController.questions.single;
    expect(
      question.appointmentId,
      scope.appointmentController.appointments.single.id,
    );
    final symptom = scope.symptomController.entries.single;
    expect(symptom.severity, 2);

    // The dose record survived the restart; marking it again adds nothing.
    final medications = scope.medicationController;
    final medication = medications.medications.single;
    expect(medication.name, 'תרופת בדיקה');
    final record = medications.records().single;
    expect(record.status, DoseStatus.taken);
    expect(
      await medications.recordDose(
        medication.id,
        record.scheduledAt,
        DoseStatus.taken,
      ),
      DoseRecordResult.success,
    );
    expect(medications.records(), hasLength(1));

    // Shown on screen too.
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.tabSymptoms),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.widgetWithText(SymptomCard, 'תסמין בדיקה'), findsOneWidget);

    expect(
      await scope.familyController.update(member.copyWith(name: 'נועה עודכן')),
      FamilySaveResult.success,
    );
    final symptomUpdate = await scope.symptomController.update(
      symptom.id,
      memberId: symptom.memberId,
      name: symptom.name,
      startedAt: symptom.startedAt,
      severity: 4,
      notes: 'עודכן',
    );
    expect(symptomUpdate, SymptomSaveResult.success);
    expect(
      await scope.doctorQuestionController.setResolved(
        question.id,
        resolved: true,
      ),
      QuestionSaveResult.success,
    );
    await tester.pumpAndSettle();
    await stopApp(tester);
  });

  testWidgets('3. after a restart the edits are kept; delete the member', (
    tester,
  ) async {
    final scope = await startApp(tester);
    final member = scope.familyController.members.single;
    expect(member.name, 'נועה עודכן');
    final symptom = scope.symptomController.entries.single;
    expect(symptom.severity, 4);
    expect(symptom.notes, 'עודכן');
    expect(scope.doctorQuestionController.questions.single.isResolved, isTrue);
    expect(scope.medicationController.records(), hasLength(1));

    final result = await scope.familyController.delete(
      member.id,
      userConfirmed: true,
    );
    expect(result.isSuccess, isTrue);
    await tester.pumpAndSettle();
    await stopApp(tester);
  });

  testWidgets('4. after a restart the member and all their records are gone', (
    tester,
  ) async {
    final scope = await startApp(tester);
    expect(scope.familyController.members, isEmpty);
    expect(scope.appointmentController.appointments, isEmpty);
    expect(scope.doctorQuestionController.questions, isEmpty);
    expect(scope.symptomController.entries, isEmpty);
    expect(scope.medicationController.medications, isEmpty);
    expect(scope.medicationController.records(), isEmpty);

    // The file on the device is encrypted.
    final header = String.fromCharCodes(file.readAsBytesSync().sublist(0, 16));
    expect(header, isNot('SQLite format 3\u0000'));
    await stopApp(tester);
  });
}
