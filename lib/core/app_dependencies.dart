import 'dart:io';

import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/emergency/emergency_dialer.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/local_transaction_runner.dart';
import 'package:mydr/data/local/repositories/local_appointment_repository.dart';
import 'package:mydr/data/local/repositories/local_doctor_question_repository.dart';
import 'package:mydr/data/local/repositories/local_dose_record_repository.dart';
import 'package:mydr/data/local/repositories/local_family_repository.dart';
import 'package:mydr/data/local/repositories/local_medication_repository.dart';
import 'package:mydr/data/local/repositories/local_symptom_repository.dart';
import 'package:mydr/data/local/repositories/local_visit_media_repository.dart';
import 'package:mydr/data/media/media_picker.dart';
import 'package:mydr/data/media/visit_media_file_store.dart';
import 'package:mydr/data/mock/mock_data.dart';
import 'package:mydr/data/reminders/local_notification_reminder_scheduler.dart';
import 'package:mydr/data/reminders/reminder_scheduler.dart';
import 'package:mydr/data/repositories/appointment_repository.dart';
import 'package:mydr/data/repositories/doctor_question_repository.dart';
import 'package:mydr/data/repositories/dose_record_repository.dart';
import 'package:mydr/data/repositories/family_repository.dart';
import 'package:mydr/data/repositories/first_aid_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_appointment_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_doctor_question_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_dose_record_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_family_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_medication_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_visit_media_repository.dart';
import 'package:mydr/data/repositories/medication_repository.dart';
import 'package:mydr/data/repositories/symptom_repository.dart';
import 'package:mydr/data/repositories/transaction_runner.dart';
import 'package:mydr/data/repositories/visit_media_repository.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// The single shared instance of each repository used across the app.
///
/// Created once at startup and exposed to screens through [AppScope], so
/// every screen reads and writes the same data.
class AppDependencies {
  /// Visit documentation defaults to in-memory records and files, and to the
  /// platform picker; medications to in-memory records, with no reminders.
  AppDependencies({
    required this.familyRepository,
    required this.appointmentRepository,
    required this.doctorQuestionRepository,
    required this.symptomRepository,
    VisitMediaRepository? visitMediaRepository,
    VisitMediaFileStore? visitMediaFiles,
    MediaPicker? mediaPicker,
    MedicationRepository? medicationRepository,
    DoseRecordRepository? doseRecordRepository,
    this.reminderScheduler = const UnsupportedReminderScheduler(),
    this.emergencyDialer = const UrlLauncherEmergencyDialer(),
    this.firstAidRepository = const AssetFirstAidRepository(),
    this.transactions = const SequentialTransactionRunner(),
    this.persistsData = false,
  }) : visitMediaRepository =
           visitMediaRepository ?? InMemoryVisitMediaRepository(),
       visitMediaFiles = visitMediaFiles ?? InMemoryVisitMediaFileStore(),
       mediaPicker = mediaPicker ?? ImagePickerMediaPicker(),
       medicationRepository =
           medicationRepository ?? InMemoryMedicationRepository(),
       doseRecordRepository =
           doseRecordRepository ?? InMemoryDoseRecordRepository();

  /// Local notifications on Android and iOS; none elsewhere.
  static ReminderScheduler platformReminderScheduler() =>
      LocalNotificationReminderScheduler.isSupportedPlatform
      ? LocalNotificationReminderScheduler(
          texts: const ReminderTexts(
            title: AppStrings.reminderNotificationTitle,
            body: AppStrings.reminderNotificationBody,
            channelName: AppStrings.reminderChannelName,
            channelDescription: AppStrings.reminderChannelDescription,
          ),
        )
      : const UnsupportedReminderScheduler();

  /// The encrypted local database: everything is saved on the device and
  /// kept across restarts. Starts empty; no demo data is ever added.
  ///
  /// Photos and videos are copied into the app's private storage (see
  /// [PrivateVisitMediaFileStore]); only their records are in the database.
  ///
  /// Dose reminders go through [reminderScheduler]; the app passes
  /// [platformReminderScheduler]. None are scheduled when it is omitted.
  factory AppDependencies.local(
    LocalDatabase database, {
    EmergencyDialer emergencyDialer = const UrlLauncherEmergencyDialer(),
    FirstAidRepository firstAidRepository = const AssetFirstAidRepository(),
    VisitMediaFileStore? visitMediaFiles,
    MediaPicker? mediaPicker,
    ReminderScheduler reminderScheduler = const UnsupportedReminderScheduler(),
  }) {
    return AppDependencies(
      familyRepository: LocalFamilyRepository(database),
      appointmentRepository: LocalAppointmentRepository(database),
      doctorQuestionRepository: LocalDoctorQuestionRepository(database),
      symptomRepository: LocalSymptomRepository(database),
      visitMediaRepository: LocalVisitMediaRepository(database),
      visitMediaFiles: visitMediaFiles ?? PrivateVisitMediaFileStore(),
      mediaPicker: mediaPicker,
      medicationRepository: LocalMedicationRepository(database),
      doseRecordRepository: LocalDoseRecordRepository(database),
      reminderScheduler: reminderScheduler,
      emergencyDialer: emergencyDialer,
      firstAidRepository: firstAidRepository,
      transactions: LocalTransactionRunner(database),
      persistsData: true,
    );
  }

  /// Demo mode: in-memory repositories seeded with fictional demo data, for
  /// development and tests only. Nothing is persisted; all changes are lost
  /// when the app closes. No reminders are scheduled for the demo data.
  factory AppDependencies.withMockData(
    DateTime now, {
    EmergencyDialer emergencyDialer = const UrlLauncherEmergencyDialer(),
    FirstAidRepository firstAidRepository = const AssetFirstAidRepository(),
  }) {
    return AppDependencies(
      familyRepository: InMemoryFamilyRepository(MockData.members()),
      appointmentRepository: InMemoryAppointmentRepository(
        MockData.appointments(now),
      ),
      doctorQuestionRepository: InMemoryDoctorQuestionRepository(
        MockData.questions(now),
      ),
      symptomRepository: InMemorySymptomRepository(MockData.symptoms(now)),
      medicationRepository: InMemoryMedicationRepository(
        MockData.medications(now),
      ),
      doseRecordRepository: InMemoryDoseRecordRepository(
        MockData.doseRecords(now),
      ),
      // Real files, so videos can play, but in the temporary directory and
      // cleared on every start, like the rest of the demo data.
      visitMediaFiles: PrivateVisitMediaFileStore(
        locateDirectory: () async => Directory(
          p.join((await getTemporaryDirectory()).path, 'mydr_demo_media'),
        ),
      ),
      emergencyDialer: emergencyDialer,
      firstAidRepository: firstAidRepository,
    );
  }

  /// Empty in-memory repositories, mainly for tests.
  factory AppDependencies.empty({
    EmergencyDialer? emergencyDialer,
    FirstAidRepository? firstAidRepository,
    VisitMediaFileStore? visitMediaFiles,
    MediaPicker? mediaPicker,
    ReminderScheduler? reminderScheduler,
  }) {
    return AppDependencies(
      familyRepository: InMemoryFamilyRepository(),
      appointmentRepository: InMemoryAppointmentRepository(),
      doctorQuestionRepository: InMemoryDoctorQuestionRepository(),
      symptomRepository: InMemorySymptomRepository(),
      visitMediaFiles: visitMediaFiles,
      mediaPicker: mediaPicker,
      reminderScheduler:
          reminderScheduler ?? const UnsupportedReminderScheduler(),
      emergencyDialer: emergencyDialer ?? const UrlLauncherEmergencyDialer(),
      firstAidRepository: firstAidRepository ?? const AssetFirstAidRepository(),
    );
  }

  final FamilyRepository familyRepository;
  final AppointmentRepository appointmentRepository;
  final DoctorQuestionRepository doctorQuestionRepository;
  final SymptomRepository symptomRepository;

  /// Records of the photos and videos prepared for doctor visits.
  final VisitMediaRepository visitMediaRepository;

  /// The photo and video files themselves.
  final VisitMediaFileStore visitMediaFiles;

  /// Camera and photo library access.
  final MediaPicker mediaPicker;

  /// Medications and their daily reminder times.
  final MedicationRepository medicationRepository;

  /// Scheduled doses recorded as taken or skipped.
  final DoseRecordRepository doseRecordRepository;

  /// Local notifications for scheduled doses.
  final ReminderScheduler reminderScheduler;

  /// Opens the phone's dialer for emergency numbers.
  final EmergencyDialer emergencyDialer;

  /// First-aid content, bundled with the app.
  final FirstAidRepository firstAidRepository;

  /// Runs operations that span repositories as one unit; atomic with the
  /// local database.
  final TransactionRunner transactions;

  /// Whether changes are saved on the device. When false (demo mode and
  /// tests), screens show that the data is not kept.
  final bool persistsData;
}
