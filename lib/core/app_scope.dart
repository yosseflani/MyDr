import 'package:flutter/widgets.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/questions/doctor_question_controller.dart';

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
    required super.child,
  });

  final AppDependencies dependencies;
  final FamilyController familyController;
  final AppointmentController appointmentController;
  final DoctorQuestionController doctorQuestionController;

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
      !identical(doctorQuestionController, oldWidget.doctorQuestionController);
}
