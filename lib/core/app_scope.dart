import 'package:flutter/widgets.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/backup/backup_controller.dart';
import 'package:mydr/features/emergency/first_aid_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/sharing/sync_controller.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/visit_preparation/visit_media_controller.dart';

/// Makes the shared [AppDependencies] and feature controllers available to
/// every widget below it.
///
/// Placed above `MaterialApp` so routes pushed with `Navigator` can reach
/// it too.
class AppScope extends InheritedWidget {
  const AppScope({
    super.key,
    required this.dependencies,
    required this.familyController,
    required this.appointmentController,
    required this.doctorQuestionController,
    required this.symptomController,
    required this.firstAidController,
    required this.visitMediaController,
    required this.medicationController,
    required this.backupController,
    required this.syncController,
    required super.child,
  });

  final AppDependencies dependencies;
  final FamilyController familyController;
  final AppointmentController appointmentController;
  final DoctorQuestionController doctorQuestionController;
  final SymptomController symptomController;
  final FirstAidController firstAidController;
  final VisitMediaController visitMediaController;
  final MedicationController medicationController;
  final BackupController backupController;

  /// Household sharing and sync.
  final SyncController syncController;

  static AppScope of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AppScope>();
    assert(scope != null, 'No AppScope found above this widget.');
    return scope!;
  }

  @override
  bool updateShouldNotify(AppScope oldWidget) =>
      !identical(dependencies, oldWidget.dependencies) ||
      !identical(familyController, oldWidget.familyController) ||
      !identical(appointmentController, oldWidget.appointmentController) ||
      !identical(
        doctorQuestionController,
        oldWidget.doctorQuestionController,
      ) ||
      !identical(symptomController, oldWidget.symptomController) ||
      !identical(firstAidController, oldWidget.firstAidController) ||
      !identical(visitMediaController, oldWidget.visitMediaController) ||
      !identical(medicationController, oldWidget.medicationController) ||
      !identical(backupController, oldWidget.backupController) ||
      !identical(syncController, oldWidget.syncController);
}
