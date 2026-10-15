import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/section_header.dart';
import 'package:mydr/features/appointments/appointment_form_screen.dart';
import 'package:mydr/features/dashboard/widgets/dashboard_header.dart';
import 'package:mydr/features/dashboard/widgets/emergency_card.dart';
import 'package:mydr/features/dashboard/widgets/family_card.dart';
import 'package:mydr/features/dashboard/widgets/next_appointment_card.dart';
import 'package:mydr/features/dashboard/widgets/quick_actions_row.dart';
import 'package:mydr/features/questions/doctor_questions_screen.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.clock = DateTime.now});

  /// Source of the current time; replaceable in tests.
  final DateTime Function() clock;

  /// Content stays readable on tablets instead of stretching edge to edge.
  static const double _maxContentWidth = 600;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final horizontalPadding = math.max(
              16.0,
              (constraints.maxWidth - _maxContentWidth) / 2,
            );

            return ListView(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                16,
                horizontalPadding,
                24,
              ),
              children: [
                DashboardHeader(date: clock()),
                const SizedBox(height: 16),
                const EmergencyCard(),
                const SizedBox(height: 24),
                const FamilyCard(),
                const SizedBox(height: 24),
                const SectionHeader(title: AppStrings.quickActionsTitle),
                QuickActionsRow(
                  onNewAppointment: () => Navigator.of(
                    context,
                  ).push(AppointmentFormScreen.addRoute(clock: clock)),
                  onDoctorQuestions: () => Navigator.of(
                    context,
                  ).push(DoctorQuestionsScreen.route(clock: clock)),
                ),
                const SizedBox(height: 24),
                NextAppointmentCard(clock: clock),
              ],
            );
          },
        ),
      ),
    );
  }
}
