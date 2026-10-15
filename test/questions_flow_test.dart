import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/features/appointments/appointment_detail_screen.dart';
import 'package:mydr/features/dashboard/widgets/next_appointment_card.dart';
import 'package:mydr/features/dashboard/widgets/quick_actions_row.dart';
import 'package:mydr/features/questions/doctor_question_form_screen.dart';
import 'package:mydr/features/questions/doctor_questions_screen.dart';
import 'package:mydr/features/questions/widgets/question_card.dart';

import 'helpers/pump_app.dart';

/// End-to-end walk through questions to the doctor in the real app widget,
/// with the demo data the app starts with.
void main() {
  testWidgets('home → questions → add → edit → appointment details → '
      'status → delete', (tester) async {
    // A tap that lands on something covering the target fails the test.
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    tester.setScreenSize(const Size(400, 2400));
    await tester.pumpWidget(
      MyDrApp(dependencies: AppDependencies.withMockData(DateTime.now())),
    );
    await tester.pumpAndSettle();

    final textField = find.widgetWithText(
      TextFormField,
      AppStrings.questionTextLabel,
    );
    final saveButton = find.widgetWithText(FilledButton, AppStrings.save);
    Finder card(String text) => find.widgetWithText(QuestionCard, text);
    Finder toggleOf(String text) =>
        find.descendant(of: card(text), matching: find.byType(IconButton));
    Finder statusOf(String text, String status) =>
        find.descendant(of: card(text), matching: find.text(status));

    // Home → all questions.
    await tester.tap(
      find.widgetWithText(QuickActionTile, AppStrings.actionDoctorQuestions),
    );
    await tester.pumpAndSettle();
    expect(find.byType(DoctorQuestionsScreen), findsOneWidget);
    expect(find.byType(QuestionCard), findsNWidgets(4));

    // Add a question linked to the grandmother's upcoming appointment.
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    await tester.tap(find.text('סבתא רחל').last);
    await tester.pumpAndSettle();
    await tester.enterText(textField, 'האם להמשיך באותו טיפול?');
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('ד״ר לוי').last);
    await tester.pumpAndSettle();
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(card('האם להמשיך באותו טיפול?'), findsOneWidget);

    // Edit it.
    await tester.tap(find.text('האם להמשיך באותו טיפול?'));
    await tester.pumpAndSettle();
    expect(find.byType(DoctorQuestionFormScreen), findsOneWidget);
    await tester.enterText(textField, 'האם להמשיך באותו טיפול תרופתי?');
    await tester.tap(saveButton);
    await tester.pumpAndSettle();
    expect(card('האם להמשיך באותו טיפול תרופתי?'), findsOneWidget);

    // Back home → appointment details, where the question is listed.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(NextAppointmentCard),
        matching: find.text('ד״ר לוי'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(AppointmentDetailScreen), findsOneWidget);
    const edited = 'האם להמשיך באותו טיפול תרופתי?';
    expect(card(edited), findsOneWidget);

    // Mark it as handled there.
    expect(statusOf(edited, AppStrings.questionStatusUnresolved), findsOne);
    await tester.tap(toggleOf(edited));
    await tester.pumpAndSettle();
    expect(statusOf(edited, AppStrings.questionStatusResolved), findsOne);

    // Delete it from its edit screen.
    await tester.tap(find.text(edited));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.deleteQuestion));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.deleteQuestion),
    );
    await tester.pumpAndSettle();

    // Back on the appointment, which still exists, without the question.
    expect(find.byType(AppointmentDetailScreen), findsOneWidget);
    expect(find.text(AppStrings.questionDeleted), findsOneWidget);
    expect(card(edited), findsNothing);
    expect(find.text('ד״ר לוי'), findsWidgets);
  });

  testWidgets('deleting an appointment keeps its questions as general; '
      'deleting a member removes theirs', (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    tester.setScreenSize(const Size(400, 2400));
    await tester.pumpWidget(
      MyDrApp(dependencies: AppDependencies.withMockData(DateTime.now())),
    );
    await tester.pumpAndSettle();

    Finder card(String text) => find.widgetWithText(QuestionCard, text);
    Finder inCard(String cardText, String text) =>
        find.descendant(of: card(cardText), matching: find.text(text));
    // Demo questions linked to the grandmother's appointment with Dr. Levi.
    const linkedQuestions = [
      'לשאול על תוצאות בדיקות הדם האחרונות',
      'מתי לקבוע את הביקורת הבאה?',
    ];

    // Delete the appointment from its details screen.
    await tester.tap(
      find.descendant(
        of: find.byType(NextAppointmentCard),
        matching: find.text('ד״ר לוי'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.deleteAppointment));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(FilledButton, AppStrings.deleteAppointment),
    );
    await tester.pumpAndSettle();

    // Its questions are still listed, now as general questions.
    await tester.tap(
      find.widgetWithText(QuickActionTile, AppStrings.actionDoctorQuestions),
    );
    await tester.pumpAndSettle();
    for (final text in linkedQuestions) {
      expect(inCard(text, AppStrings.generalQuestion), findsOneWidget);
      expect(inCard(text, 'סבתא רחל'), findsOneWidget);
    }

    // Deleting the grandmother removes her questions too.
    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tabFamily));
    await tester.pumpAndSettle();
    await tester.tap(find.text('סבתא רחל'));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.deleteProfile));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, AppStrings.delete));
    await tester.pumpAndSettle();
    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle();
    await tester.tap(
      find.widgetWithText(QuickActionTile, AppStrings.actionDoctorQuestions),
    );
    await tester.pumpAndSettle();

    for (final text in linkedQuestions) {
      expect(card(text), findsNothing);
    }
    expect(find.byType(QuestionCard), findsWidgets);
  });
}
