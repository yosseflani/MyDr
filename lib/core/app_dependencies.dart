import 'package:mydr/data/emergency/emergency_dialer.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/local_transaction_runner.dart';
import 'package:mydr/data/local/repositories/local_appointment_repository.dart';
import 'package:mydr/data/local/repositories/local_doctor_question_repository.dart';
import 'package:mydr/data/local/repositories/local_family_repository.dart';
import 'package:mydr/data/local/repositories/local_symptom_repository.dart';
import 'package:mydr/data/mock/mock_data.dart';
import 'package:mydr/data/repositories/appointment_repository.dart';
import 'package:mydr/data/repositories/doctor_question_repository.dart';
import 'package:mydr/data/repositories/family_repository.dart';
import 'package:mydr/data/repositories/first_aid_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_appointment_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_doctor_question_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_family_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';
import 'package:mydr/data/repositories/symptom_repository.dart';
import 'package:mydr/data/repositories/transaction_runner.dart';

/// The single shared instance of each repository used across the app.
///
/// Created once at startup and exposed to screens through [AppScope], so
/// every screen reads and writes the same data.
class AppDependencies {
  const AppDependencies({
    required this.familyRepository,
    required this.appointmentRepository,
    required this.doctorQuestionRepository,
    required this.symptomRepository,
    this.emergencyDialer = const UrlLauncherEmergencyDialer(),
    this.firstAidRepository = const AssetFirstAidRepository(),
    this.transactions = const SequentialTransactionRunner(),
    this.persistsData = false,
  });

  /// The encrypted local database: everything is saved on the device and
  /// kept across restarts. Starts empty; no demo data is ever added.
  factory AppDependencies.local(
    LocalDatabase database, {
    EmergencyDialer emergencyDialer = const UrlLauncherEmergencyDialer(),
    FirstAidRepository firstAidRepository = const AssetFirstAidRepository(),
  }) {
    return AppDependencies(
      familyRepository: LocalFamilyRepository(database),
      appointmentRepository: LocalAppointmentRepository(database),
      doctorQuestionRepository: LocalDoctorQuestionRepository(database),
      symptomRepository: LocalSymptomRepository(database),
      emergencyDialer: emergencyDialer,
      firstAidRepository: firstAidRepository,
      transactions: LocalTransactionRunner(database),
      persistsData: true,
    );
  }

  /// Demo mode: in-memory repositories seeded with fictional demo data, for
  /// development and tests only. Nothing is persisted; all changes are lost
  /// when the app closes.
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
      emergencyDialer: emergencyDialer,
      firstAidRepository: firstAidRepository,
    );
  }

  /// Empty in-memory repositories, mainly for tests.
  factory AppDependencies.empty({
    EmergencyDialer? emergencyDialer,
    FirstAidRepository? firstAidRepository,
  }) {
    return AppDependencies(
      familyRepository: InMemoryFamilyRepository(),
      appointmentRepository: InMemoryAppointmentRepository(),
      doctorQuestionRepository: InMemoryDoctorQuestionRepository(),
      symptomRepository: InMemorySymptomRepository(),
      emergencyDialer: emergencyDialer ?? const UrlLauncherEmergencyDialer(),
      firstAidRepository: firstAidRepository ?? const AssetFirstAidRepository(),
    );
  }

  final FamilyRepository familyRepository;
  final AppointmentRepository appointmentRepository;
  final DoctorQuestionRepository doctorQuestionRepository;
  final SymptomRepository symptomRepository;

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
