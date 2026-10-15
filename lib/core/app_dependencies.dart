import 'package:mydr/data/emergency/emergency_dialer.dart';
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
  });

  /// In-memory repositories seeded with fictional demo data. Nothing is
  /// persisted; all changes are lost when the app closes.
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
}
