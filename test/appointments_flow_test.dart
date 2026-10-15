import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/features/appointments/appointment_detail_screen.dart';
import 'package:mydr/features/appointments/appointment_form_screen.dart';
import 'package:mydr/core/widgets/date_time_fields.dart';
import 'package:mydr/features/dashboard/widgets/next_appointment_card.dart';
import 'package:mydr/features/dashboard/widgets/quick_actions_row.dart';
import 'package:mydr/features/family/widgets/member_card.dart';

import 'helpers/pump_app.dart';

/// End-to-end walk through appointment management in the real app widget,
/// starting from the home screen, with the demo data the app starts with.
void main() {
  testWidgets('add, view, edit and delete an appointment from the home '
      'screen, and the home screen follows along', (tester) async {
    // A tap that lands on something covering the target fails the test.
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    tester.setScreenSize(const Size(400, 2000));
    await tester.pumpWidget(
      MyDrApp(dependencies: AppDependencies.withMockData(DateTime.now())),
    );
    await tester.pumpAndSettle();

    final card = find.byType(NextAppointmentCard);
    Finder inCard(String text) =>
        find.descendant(of: card, matching: find.text(text));
    final saveButton = find.widgetWithText(FilledButton, AppStrings.save);

    // The demo data has two upcoming appointments.
    expect(inCard('ד״ר לוי'), findsOneWidget);
    expect(inCard('ד״ר מזרחי'), findsOneWidget);

    // Add, from the home screen shortcut.
    await tester.tap(
      find.widgetWithText(QuickActionTile, AppStrings.actionNewAppointment),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppointmentFormScreen), findsOneWidget);

    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('איתי').last);
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.doctorNameLabel),
      'ד״ר חדש',
    );
    // The 15th of next month: always in the future, whatever today is.
    await tester.tap(find.byType(DatePickerField));
    await tester.pumpAndSettle();
    final localizations = MaterialLocalizations.of(
      tester.element(find.byType(DatePickerDialog)),
    );
    await tester.tap(find.byTooltip(localizations.nextMonthTooltip));
    await tester.pumpAndSettle();
    await tester.tap(
      find
          .descendant(
            of: find.byType(DatePickerDialog),
            matching: find.text('15'),
          )
          .first,
    );
    await tester.tap(find.text(localizations.okButtonLabel));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(TimePickerField));
    await tester.pumpAndSettle();
    await tester.tap(find.text(localizations.okButtonLabel));
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    // Back home, the new appointment is listed with the others.
    expect(find.byType(AppointmentFormScreen), findsNothing);
    expect(inCard('ד״ר חדש'), findsOneWidget);

    // View.
    await tester.tap(inCard('ד״ר חדש'));
    await tester.pumpAndSettle();
    expect(find.byType(AppointmentDetailScreen), findsOneWidget);

    // Edit.
    await tester.tap(find.byTooltip(AppStrings.editAppointment));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, AppStrings.doctorNameLabel),
      'ד״ר חדש מאוד',
    );
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(find.byType(AppointmentDetailScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    expect(inCard('ד״ר חדש מאוד'), findsOneWidget);

    // Delete.
    await tester.tap(inCard('ד״ר חדש מאוד'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.deleteAppointment));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.deleteAppointment),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppointmentDetailScreen), findsNothing);
    expect(find.text(AppStrings.appointmentDeleted), findsOneWidget);
    expect(inCard('ד״ר חדש מאוד'), findsNothing);

    // Deleting a family member removes their appointments from home too.
    await tester.tap(find.text(AppStrings.tabFamily));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(MemberCard, 'סבתא רחל'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.deleteProfile));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle();

    expect(inCard('ד״ר לוי'), findsNothing);
    expect(inCard('ד״ר מזרחי'), findsOneWidget);
  });
}
