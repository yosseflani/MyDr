import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/repositories/first_aid_repository.dart';
import 'package:mydr/features/dashboard/widgets/emergency_card.dart';
import 'package:mydr/features/emergency/emergency_screen.dart';
import 'package:mydr/features/emergency/first_aid_topic_screen.dart';
import 'package:mydr/features/emergency/widgets/first_aid_topic_tile.dart';

import 'helpers/fake_emergency_dialer.dart';
import 'helpers/fake_first_aid_repository.dart';
import 'helpers/pump_app.dart';

/// Emergency calling in the real app widget, from the home screen, with a
/// fake dialer so no real dialer opens.
void main() {
  testWidgets('dial 101 from home, open the emergency center, dial another '
      'number, handle an unavailable dialer, and come back', (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    tester.setScreenSize(const Size(400, 2000));
    final dialer = FakeEmergencyDialer();
    await tester.pumpWidget(
      MyDrApp(
        dependencies: AppDependencies.withMockData(
          DateTime.now(),
          emergencyDialer: dialer,
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tapAndSettle(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    final card = find.byType(EmergencyCard);

    // One tap from the home screen opens the dialer with 101.
    await tapAndSettle(
      find.descendant(
        of: card,
        matching: find.text(AppStrings.callMedicalEmergency),
      ),
    );
    expect(dialer.dialed, ['101']);

    // Into the emergency center; fire and rescue.
    await tapAndSettle(
      find.descendant(
        of: card,
        matching: find.text(AppStrings.openEmergencyCenter),
      ),
    );
    expect(find.byType(EmergencyScreen), findsOneWidget);
    await tapAndSettle(find.text(AppStrings.serviceFire));
    expect(dialer.dialed, ['101', '102']);

    // A device that cannot dial: the number is shown instead.
    dialer.opens = false;
    await tapAndSettle(find.text(AppStrings.callMedicalEmergencyTitle));
    expect(
      find.text(AppStrings.dialerUnavailableMessage('101')),
      findsOneWidget,
    );
    await tapAndSettle(find.text(AppStrings.close));

    // Back home; the tabs work as before.
    await tapAndSettle(find.byType(BackButton));
    expect(find.byType(EmergencyScreen), findsNothing);
    expect(card, findsOneWidget);

    await tapAndSettle(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text(AppStrings.tabSymptoms),
      ),
    );
    expect(find.text(AppStrings.symptomsTitle), findsOneWidget);
    expect(dialer.dialed, ['101', '102', '101']);
  });

  testWidgets('home, emergency center, first-aid library, a topic, back to '
      'the center and home', (tester) async {
    WidgetController.hitTestWarningShouldBeFatal = true;
    addTearDown(() => WidgetController.hitTestWarningShouldBeFatal = false);
    tester.setScreenSize(const Size(400, 2000));
    final dialer = FakeEmergencyDialer();
    await tester.pumpWidget(
      MyDrApp(
        dependencies: AppDependencies.withMockData(
          DateTime.now(),
          emergencyDialer: dialer,
          firstAidRepository: FakeFirstAidRepository(bundledHebrewContent()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    Future<void> tapAndSettle(Finder finder) async {
      await tester.ensureVisible(finder);
      await tester.pumpAndSettle();
      await tester.tap(finder);
      await tester.pumpAndSettle();
    }

    await tapAndSettle(
      find.descendant(
        of: find.byType(EmergencyCard),
        matching: find.text(AppStrings.openEmergencyCenter),
      ),
    );
    expect(find.byType(EmergencyScreen), findsOneWidget);
    expect(find.text(AppStrings.firstAidSectionTitle), findsOneWidget);
    expect(find.byType(FirstAidTopicTile), findsNWidgets(7));

    await tapAndSettle(find.text('תגובה אלרגית חמורה'));
    expect(find.byType(FirstAidTopicScreen), findsOneWidget);
    expect(find.text(AppStrings.firstAidPendingTitle), findsOneWidget);
    expect(find.text(AppStrings.firstAidStepsTitle), findsNothing);

    // The call bar on the topic dials 101 at once.
    await tapAndSettle(
      find.text('${AppStrings.callMedicalEmergencyTitle} · 101'),
    );
    expect(dialer.dialed, ['101']);

    await tapAndSettle(find.byType(BackButton));
    expect(find.byType(FirstAidTopicScreen), findsNothing);
    expect(find.byType(EmergencyScreen), findsOneWidget);

    await tapAndSettle(find.byType(BackButton));
    expect(find.byType(EmergencyScreen), findsNothing);
    expect(find.byType(EmergencyCard), findsOneWidget);
  });

  for (final (name, content) in [
    ('a broken content file', '{"schemaVersion": 1, "topics": ['),
    ('an unsupported schema', '{"schemaVersion": 2, "topics": []}'),
    ('a missing content file', null),
  ]) {
    testWidgets('$name does not disturb the emergency center', (tester) async {
      tester.setScreenSize(const Size(400, 2000));
      final dialer = FakeEmergencyDialer();
      await tester.pumpWidget(
        MyDrApp(
          dependencies: AppDependencies.withMockData(
            DateTime.now(),
            emergencyDialer: dialer,
            // The real repository and parser, reading a bad file.
            firstAidRepository: AssetFirstAidRepository(
              bundle: FakeAssetBundle(content),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(EmergencyCard),
          matching: find.text(AppStrings.openEmergencyCenter),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.firstAidLoadErrorTitle), findsOneWidget);
      expect(find.byType(FirstAidTopicTile), findsNothing);

      await tester.tap(find.text(AppStrings.callMedicalEmergencyTitle));
      await tester.pumpAndSettle();
      await tester.tap(find.text(AppStrings.servicePolice));
      await tester.pumpAndSettle();
      expect(dialer.dialed, ['101', '100']);
      expect(find.byType(AlertDialog), findsNothing);
    });
  }
}
