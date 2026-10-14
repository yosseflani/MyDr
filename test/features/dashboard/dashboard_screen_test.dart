import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/coming_soon_badge.dart';
import 'package:mydr/features/dashboard/dashboard_screen.dart';
import 'package:mydr/features/dashboard/widgets/next_appointment_card.dart';
import 'package:mydr/features/dashboard/widgets/quick_actions_row.dart';

import '../../helpers/pump_app.dart';

void main() {
  testWidgets('shows all dashboard sections', (tester) async {
    tester.setScreenSize(const Size(400, 1600));
    await tester.pumpApp(const DashboardScreen());

    expect(find.text(AppStrings.dashboardSubtitle), findsOneWidget);
    expect(find.text(AppStrings.emergencyTitle), findsOneWidget);
    expect(find.text(AppStrings.familyCardTitle), findsOneWidget);
    expect(find.text(AppStrings.quickActionsTitle), findsOneWidget);
    expect(find.text(AppStrings.nextAppointmentTitle), findsOneWidget);
  });

  testWidgets('emergency card keeps the 101 number and the disclaimer', (
    tester,
  ) async {
    await tester.pumpApp(const DashboardScreen());

    expect(find.text(AppStrings.emergencyCallLine), findsOneWidget);
    expect(find.text(AppStrings.emergencyNoInstructions), findsOneWidget);
  });

  testWidgets('quick actions are shown as unavailable', (tester) async {
    tester.setScreenSize(const Size(400, 1600));
    await tester.pumpApp(const DashboardScreen());

    final tiles = find.byType(QuickActionTile);
    expect(tiles, findsNWidgets(3));
    for (final label in [
      AppStrings.actionNewAppointment,
      AppStrings.actionLogSymptom,
      AppStrings.actionDoctorQuestions,
    ]) {
      expect(find.text(label), findsOneWidget);
    }

    // Each tile has a "coming soon" badge and no tap handler.
    expect(
      find.descendant(of: tiles, matching: find.byType(ComingSoonBadge)),
      findsNWidgets(3),
    );
    expect(
      find.descendant(of: tiles, matching: find.byType(InkWell)),
      findsNothing,
    );
  });

  testWidgets('next appointment card shows the empty state', (tester) async {
    tester.setScreenSize(const Size(400, 1600));
    await tester.pumpApp(const DashboardScreen());

    expect(find.byType(NextAppointmentCard), findsOneWidget);
    expect(find.text(AppStrings.nextAppointmentEmptyTitle), findsOneWidget);
  });

  for (final size in const [Size(320, 568), Size(1024, 768)]) {
    testWidgets('lays out without overflow at ${size.width}x${size.height} '
        'with large text', (tester) async {
      tester.setScreenSize(size);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await tester.pumpApp(const DashboardScreen());
      await tester.scrollUntilVisible(
        find.byType(NextAppointmentCard),
        300,
        scrollable: find.byType(Scrollable),
      );

      // Any RenderFlex overflow would be reported as a test failure.
      expect(tester.takeException(), isNull);
      expect(find.byType(NextAppointmentCard), findsOneWidget);
    });
  }
}
