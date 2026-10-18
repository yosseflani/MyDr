import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/theme/app_theme.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/backup/backup_controller.dart';
import 'package:mydr/features/emergency/first_aid_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/medications/medication_controller.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/shell/home_shell.dart';
import 'package:mydr/features/visit_preparation/visit_media_controller.dart';

/// Root widget. Hebrew is the only supported locale, so the whole
/// widget tree is laid out right-to-left.
class MyDrApp extends StatefulWidget {
  const MyDrApp({
    super.key,
    required this.dependencies,
    this.home = const HomeShell(),
  });

  final AppDependencies dependencies;

  /// The first screen; the tabbed app unless the app is still starting.
  final Widget home;

  static const Locale hebrew = Locale('he');

  @override
  State<MyDrApp> createState() => _MyDrAppState();
}

class _MyDrAppState extends State<MyDrApp> {
  late final FamilyController _familyController = FamilyController(
    widget.dependencies,
  )..load();

  late final AppointmentController _appointmentController =
      AppointmentController(
        dependencies: widget.dependencies,
        familyController: _familyController,
      )..load();

  late final DoctorQuestionController _doctorQuestionController =
      DoctorQuestionController(
        dependencies: widget.dependencies,
        familyController: _familyController,
        appointmentController: _appointmentController,
      )..load();

  late final SymptomController _symptomController = SymptomController(
    dependencies: widget.dependencies,
    familyController: _familyController,
  )..load();

  /// Also clears leftover media files once, at start-up.
  late final VisitMediaController _visitMediaController = VisitMediaController(
    dependencies: widget.dependencies,
    familyController: _familyController,
    appointmentController: _appointmentController,
  )..load(cleanUpFiles: true);

  /// Plans dose reminders after loading, so they are rebuilt from the saved
  /// data on every start.
  late final MedicationController _medicationController = MedicationController(
    dependencies: widget.dependencies,
    familyController: _familyController,
  )..load();

  /// Reschedules reminders whenever the app returns to the foreground: the
  /// day, the time zone or the notification setting may have changed, and
  /// only a limited number of reminders is scheduled ahead.
  late final AppLifecycleListener _lifecycle;

  /// Connects to the cloud only when the backup screen is opened.
  late final BackupController _backupController = BackupController(
    dependencies: widget.dependencies,
    familyController: _familyController,
  );

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => _medicationController.refreshReminders(),
    );
  }

  /// Independent of the others: emergency calling never waits for it.
  late final FirstAidController _firstAidController = FirstAidController(
    widget.dependencies.firstAidRepository,
  )..load();

  @override
  void dispose() {
    _lifecycle.dispose();
    _backupController.dispose();
    _firstAidController.dispose();
    // Disposed in reverse order of creation, since each listens to the
    // ones created before it.
    _medicationController.dispose();
    _visitMediaController.dispose();
    _symptomController.dispose();
    _doctorQuestionController.dispose();
    _appointmentController.dispose();
    _familyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: widget.dependencies,
      familyController: _familyController,
      appointmentController: _appointmentController,
      doctorQuestionController: _doctorQuestionController,
      symptomController: _symptomController,
      firstAidController: _firstAidController,
      visitMediaController: _visitMediaController,
      medicationController: _medicationController,
      backupController: _backupController,
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        locale: MyDrApp.hebrew,
        supportedLocales: const [MyDrApp.hebrew],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: widget.home,
      ),
    );
  }
}
