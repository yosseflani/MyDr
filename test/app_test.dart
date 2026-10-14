import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/app.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/features/dashboard/widgets/emergency_card.dart';
import 'package:mydr/features/shell/home_shell.dart';

void main() {
  testWidgets('app uses Hebrew locale and right-to-left layout', (
    tester,
  ) async {
    await tester.pumpWidget(MyDrApp(dependencies: AppDependencies.empty()));

    final context = tester.element(find.byType(HomeShell));
    expect(Localizations.localeOf(context), const Locale('he'));
    expect(Directionality.of(context), TextDirection.rtl);
  });

  testWidgets('navigation bar shows the four tabs', (tester) async {
    await tester.pumpWidget(MyDrApp(dependencies: AppDependencies.empty()));

    expect(find.byType(NavigationDestination), findsNWidgets(4));
    for (final label in [
      AppStrings.tabHome,
      AppStrings.tabFamily,
      AppStrings.tabAppointments,
      AppStrings.tabSymptoms,
    ]) {
      expect(find.text(label), findsOneWidget);
    }
  });

  testWidgets('home tab shows the emergency card', (tester) async {
    await tester.pumpWidget(MyDrApp(dependencies: AppDependencies.empty()));

    expect(find.byType(EmergencyCard), findsOneWidget);
    expect(find.text(AppStrings.emergencyTitle), findsOneWidget);
  });

  testWidgets('tapping each tab shows its screen', (tester) async {
    await tester.pumpWidget(MyDrApp(dependencies: AppDependencies.empty()));

    final tabsToTitles = {
      AppStrings.tabFamily: AppStrings.familyTitle,
      AppStrings.tabAppointments: AppStrings.appointmentsTitle,
      AppStrings.tabSymptoms: AppStrings.symptomsTitle,
    };

    for (final MapEntry(key: tab, value: title) in tabsToTitles.entries) {
      expect(find.text(title), findsNothing);
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
    }

    await tester.tap(find.text(AppStrings.tabHome));
    await tester.pumpAndSettle();
    expect(find.byType(EmergencyCard), findsOneWidget);
  });
}
