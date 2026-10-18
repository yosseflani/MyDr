import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/theme/app_theme.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/backup/backup_controller.dart';
import 'package:mydr/features/emergency/first_aid_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/visit_preparation/visit_media_controller.dart';

extension PumpApp on WidgetTester {
  /// Pumps [child] with the same theme, Hebrew locale, RTL setup and
  /// [AppScope] as the app. Uses fresh empty repositories unless
  /// [dependencies] is given, and controllers built on them unless
  /// [familyController], [appointmentController],
  /// [doctorQuestionController], [symptomController], [firstAidController],
  /// [visitMediaController], [medicationController] or [backupController]
  /// is given.
  Future<void> pumpApp(
    Widget child, {
    AppDependencies? dependencies,
    FamilyController? familyController,
    AppointmentController? appointmentController,
    DoctorQuestionController? doctorQuestionController,
    SymptomController? symptomController,
    FirstAidController? firstAidController,
    VisitMediaController? visitMediaController,
    MedicationController? medicationController,
    BackupController? backupController,
  }) {
    final resolvedDependencies = dependencies ?? AppDependencies.empty();
    final resolvedController =
        familyController ?? FamilyController(resolvedDependencies);
    if (familyController == null) addTearDown(resolvedController.dispose);
    final resolvedAppointmentController =
        appointmentController ??
        AppointmentController(
          dependencies: resolvedDependencies,
          familyController: resolvedController,
        );
    // Tear-downs run in reverse order, so this one is disposed first.
    if (appointmentController == null) {
      addTearDown(resolvedAppointmentController.dispose);
    }
    final resolvedQuestionController =
        doctorQuestionController ??
        DoctorQuestionController(
          dependencies: resolvedDependencies,
          familyController: resolvedController,
          appointmentController: resolvedAppointmentController,
        );
    if (doctorQuestionController == null) {
      addTearDown(resolvedQuestionController.dispose);
    }
    final resolvedSymptomController =
        symptomController ??
        SymptomController(
          dependencies: resolvedDependencies,
          familyController: resolvedController,
        );
    if (symptomController == null) {
      addTearDown(resolvedSymptomController.dispose);
    }

    final resolvedFirstAidController =
        firstAidController ??
        FirstAidController(resolvedDependencies.firstAidRepository);
    if (firstAidController == null) {
      addTearDown(resolvedFirstAidController.dispose);
    }

    final resolvedVisitMediaController =
        visitMediaController ??
        VisitMediaController(
          dependencies: resolvedDependencies,
          familyController: resolvedController,
          appointmentController: resolvedAppointmentController,
        );
    if (visitMediaController == null) {
      addTearDown(resolvedVisitMediaController.dispose);
    }

    final resolvedMedicationController =
        medicationController ??
        MedicationController(
          dependencies: resolvedDependencies,
          familyController: resolvedController,
        );
    if (medicationController == null) {
      addTearDown(resolvedMedicationController.dispose);
    }

    final resolvedBackupController =
        backupController ??
        BackupController(
          dependencies: resolvedDependencies,
          familyController: resolvedController,
        );
    if (backupController == null) {
      addTearDown(resolvedBackupController.dispose);
    }

    return pumpWidget(
      AppScope(
        dependencies: resolvedDependencies,
        familyController: resolvedController,
        appointmentController: resolvedAppointmentController,
        doctorQuestionController: resolvedQuestionController,
        symptomController: resolvedSymptomController,
        firstAidController: resolvedFirstAidController,
        visitMediaController: resolvedVisitMediaController,
        medicationController: resolvedMedicationController,
        backupController: resolvedBackupController,
        child: MaterialApp(
          theme: AppTheme.light,
          locale: MyDrApp.hebrew,
          supportedLocales: const [MyDrApp.hebrew],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: child,
        ),
      ),
    );
  }

  /// Sets the logical screen size for the current test.
  void setScreenSize(Size size) {
    view.physicalSize = size;
    view.devicePixelRatio = 1;
    addTearDown(view.reset);
  }
}
