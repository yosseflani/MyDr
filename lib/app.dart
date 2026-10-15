import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/app_scope.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/theme/app_theme.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/shell/home_shell.dart';

/// Root widget. Hebrew is the only supported locale, so the whole
/// widget tree is laid out right-to-left.
class MyDrApp extends StatefulWidget {
  const MyDrApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

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

  @override
  void dispose() {
    // Disposed in reverse order of creation, since each listens to the
    // ones created before it.
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
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        locale: MyDrApp.hebrew,
        supportedLocales: const [MyDrApp.hebrew],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        home: const HomeShell(),
      ),
    );
  }
}
