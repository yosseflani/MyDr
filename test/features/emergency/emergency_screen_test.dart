import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/data/emergency/emergency_numbers.dart';
import 'package:mydr/features/dashboard/dashboard_screen.dart';
import 'package:mydr/features/dashboard/widgets/emergency_card.dart';
import 'package:mydr/features/emergency/emergency_screen.dart';
import 'package:mydr/features/emergency/widgets/first_aid_library_section.dart';
import 'package:mydr/features/family/family_controller.dart';

import '../../helpers/fake_emergency_dialer.dart';
import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  late FakeEmergencyDialer dialer;

  setUp(() => dialer = FakeEmergencyDialer());

  Future<void> pump(WidgetTester tester, Widget screen, {Size? size}) {
    tester.setScreenSize(size ?? const Size(400, 1600));
    return tester.pumpApp(
      screen,
      dependencies: AppDependencies.empty(emergencyDialer: dialer),
    );
  }

  Finder callButton(String service, String number) =>
      find.bySemanticsLabel(AppStrings.callServiceLabel(service, number));

  Finder medical() => callButton(AppStrings.serviceMedical, '101');
  Finder police() => callButton(AppStrings.servicePolice, '100');
  Finder fire() => callButton(AppStrings.serviceFire, '102');

  group('emergency center', () {
    testWidgets('shows 101 first and large, then 100 and 102, the first-aid '
        'library and the disclaimer', (tester) async {
      await pump(tester, const EmergencyScreen());

      expect(find.text(AppStrings.emergencyCenterTitle), findsOneWidget);
      expect(medical(), findsOneWidget);
      expect(police(), findsOneWidget);
      expect(fire(), findsOneWidget);

      final medicalBox = tester.getRect(medical());
      expect(medicalBox.height, greaterThanOrEqualTo(72));
      expect(medicalBox.top, lessThan(tester.getRect(police()).top));
      expect(
        tester.getRect(police()).top,
        lessThan(tester.getRect(fire()).top),
      );

      expect(find.text(AppStrings.firstAidSectionTitle), findsOneWidget);
      expect(find.byType(FirstAidLibrarySection), findsOneWidget);
      expect(find.text(AppStrings.emergencyDisclaimer), findsOneWidget);
    });

    testWidgets('has no demo-data notice: the numbers are real', (
      tester,
    ) async {
      await pump(tester, const EmergencyScreen());

      expect(find.byType(DemoDataBanner), findsNothing);
    });

    testWidgets('lists exactly the verified numbers', (tester) async {
      expect(
        [for (final n in EmergencyNumbers.israel) n.number],
        ['101', '100', '102'],
      );
      expect(EmergencyNumbers.medical.number, '101');
    });

    testWidgets('nothing is dialed until the user taps', (tester) async {
      await pump(tester, const EmergencyScreen());
      await tester.pumpAndSettle();

      expect(dialer.dialed, isEmpty);
    });

    testWidgets('tapping 101 opens the dialer right away, with no dialog', (
      tester,
    ) async {
      await pump(tester, const EmergencyScreen());

      await tester.tap(medical());
      await tester.pumpAndSettle();

      expect(dialer.dialed, ['101']);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('100 and 102 dial their own numbers', (tester) async {
      await pump(tester, const EmergencyScreen());

      await tester.tap(police());
      await tester.pumpAndSettle();
      await tester.tap(fire());
      await tester.pumpAndSettle();

      expect(dialer.dialed, ['100', '102']);
    });

    testWidgets('repeated taps while the dialer opens dial once', (
      tester,
    ) async {
      await pump(tester, const EmergencyScreen());
      dialer.gate = Completer<void>();

      await tester.tap(medical());
      await tester.tap(medical());
      await tester.pump();
      expect(dialer.dialed, ['101']);

      dialer.gate!.complete();
      dialer.gate = null;
      await tester.pumpAndSettle();
      await tester.tap(medical());
      await tester.pumpAndSettle();
      expect(dialer.dialed, ['101', '101']);
    });

    for (final failure in ['reports failure', 'throws']) {
      testWidgets('if the dialer $failure, shows the number to dial by '
          'hand, never that a call was made', (tester) async {
        await pump(tester, const EmergencyScreen());
        if (failure == 'throws') {
          dialer.throws = true;
        } else {
          dialer.opens = false;
        }

        await tester.tap(police());
        await tester.pumpAndSettle();

        final dialog = find.byType(AlertDialog);
        expect(dialog, findsOneWidget);
        expect(find.text(AppStrings.dialerUnavailableTitle), findsOneWidget);
        expect(
          find.text(AppStrings.dialerUnavailableMessage('100')),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: dialog,
            matching: find.byWidgetPredicate(
              (w) => w is SelectableText && w.data == '100',
            ),
          ),
          findsOneWidget,
        );

        await tester.tap(find.text(AppStrings.close));
        await tester.pumpAndSettle();
        expect(dialog, findsNothing);

        // The button still works afterwards.
        dialer
          ..opens = true
          ..throws = false;
        await tester.tap(police());
        await tester.pumpAndSettle();
        expect(dialer.dialed, ['100', '100']);
        expect(find.byType(AlertDialog), findsNothing);
      });
    }

    testWidgets('the call buttons work even when the rest of the app failed '
        'to load', (tester) async {
      final dependencies = AppDependencies(
        familyRepository: FlakyFamilyRepository()..failGetAll = true,
        appointmentRepository: FlakyAppointmentRepository()..failGetAll = true,
        doctorQuestionRepository: FlakyDoctorQuestionRepository()
          ..failGetAll = true,
        symptomRepository: FlakySymptomRepository()..failGetAll = true,
        emergencyDialer: dialer,
      );
      final family = FamilyController(dependencies);
      addTearDown(family.dispose);
      await family.load();
      expect(family.hasLoadError, isTrue);

      tester.setScreenSize(const Size(400, 1600));
      await tester.pumpApp(
        const EmergencyScreen(),
        dependencies: dependencies,
        familyController: family,
      );
      await tester.tap(medical());
      await tester.pumpAndSettle();

      expect(dialer.dialed, ['101']);
    });

    testWidgets('meets tap target, label and contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(tester, const EmergencyScreen());

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(iOSTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    for (final scale in [1.5, 2.0]) {
      testWidgets('fits a narrow screen at text scale $scale, with 101 '
          'visible at the top', (tester) async {
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pump(tester, const EmergencyScreen(), size: const Size(320, 568));

        expect(tester.takeException(), isNull);
        final box = tester.getRect(medical());
        expect(box.top, lessThan(200));
        expect(box.bottom, lessThan(568));

        await tester.scrollUntilVisible(
          find.text(AppStrings.emergencyDisclaimer),
          300,
          scrollable: find.byType(Scrollable).first,
        );
        expect(tester.takeException(), isNull);
      });
    }
  });

  group('home screen card', () {
    final card = find.byType(EmergencyCard);
    Finder cardCall() => find.descendant(
      of: card,
      matching: find.text(AppStrings.callMedicalEmergency),
    );
    final openCenter = find.descendant(
      of: card,
      matching: find.text(AppStrings.openEmergencyCenter),
    );

    testWidgets('"call 101" opens the dialer and stays home', (tester) async {
      await pump(tester, const DashboardScreen());

      await tester.tap(cardCall());
      await tester.pumpAndSettle();

      expect(dialer.dialed, ['101']);
      expect(find.byType(EmergencyScreen), findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('a failed dial from home shows the number to dial', (
      tester,
    ) async {
      dialer.opens = false;
      await pump(tester, const DashboardScreen());

      await tester.tap(cardCall());
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.dialerUnavailableMessage('101')),
        findsOneWidget,
      );
    });

    testWidgets('opens the emergency center, and back returns home', (
      tester,
    ) async {
      await pump(tester, const DashboardScreen());

      await tester.tap(openCenter);
      await tester.pumpAndSettle();
      expect(find.byType(EmergencyScreen), findsOneWidget);
      expect(dialer.dialed, isEmpty);

      await tester.tap(find.byType(BackButton));
      await tester.pumpAndSettle();
      expect(find.byType(EmergencyScreen), findsNothing);
      expect(find.byType(DashboardScreen), findsOneWidget);
    });

    testWidgets('meets tap target, label and contrast guidelines', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pump(
        tester,
        const Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: EmergencyCard(),
          ),
        ),
      );

      await expectLater(tester, meetsGuideline(androidTapTargetGuideline));
      await expectLater(tester, meetsGuideline(labeledTapTargetGuideline));
      await expectLater(tester, meetsGuideline(textContrastGuideline));
      handle.dispose();
    });

    testWidgets('fits a narrow screen with large text', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, const DashboardScreen(), size: const Size(320, 568));

      await tester.scrollUntilVisible(
        openCenter,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
