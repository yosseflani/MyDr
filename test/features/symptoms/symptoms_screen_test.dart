import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/demo_data_banner.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/symptoms/symptom_form_screen.dart';
import 'package:mydr/features/symptoms/symptom_formatting.dart';
import 'package:mydr/features/symptoms/symptoms_screen.dart';
import 'package:mydr/features/symptoms/widgets/symptom_card.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

void main() {
  // A Thursday.
  final now = DateTime(2026, 10, 15, 12);

  final members = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
    FamilyMember(id: 'm2', name: 'נועה', relation: FamilyRelation.child),
    FamilyMember(id: 'm3', name: 'אבי', relation: FamilyRelation.spouse),
  ];

  SymptomEntry entry(
    String id,
    String memberId,
    String name,
    DateTime startedAt,
    int severity, {
    String? notes,
  }) => SymptomEntry(
    id: id,
    memberId: memberId,
    name: name,
    startedAt: startedAt,
    severity: severity,
    notes: notes,
  );

  // m3 has no records. Stored out of order on purpose.
  final sampleEntries = [
    entry('old', 'm1', 'שיעול', DateTime(2026, 10, 10, 18), 1),
    entry('fever-1', 'm2', 'חום', DateTime(2026, 10, 14, 20), 3),
    entry(
      'headache',
      'm1',
      'כאב ראש',
      DateTime(2026, 10, 15, 9, 30),
      2,
      notes: 'אחרי העבודה',
    ),
    entry('fever-2', 'm2', 'חום', DateTime(2026, 10, 15, 8), 4),
  ];

  late FlakyFamilyRepository familyRepository;
  late FlakySymptomRepository symptomRepository;
  late AppDependencies dependencies;
  late FamilyController familyController;
  late SymptomController symptomController;

  void setUpWith(List<SymptomEntry> entries) {
    familyRepository = FlakyFamilyRepository(members);
    symptomRepository = FlakySymptomRepository(entries);
    dependencies = AppDependencies(
      familyRepository: familyRepository,
      appointmentRepository: FlakyAppointmentRepository(),
      doctorQuestionRepository: FlakyDoctorQuestionRepository(),
      symptomRepository: symptomRepository,
    );
    familyController = FamilyController(dependencies);
    symptomController = SymptomController(
      dependencies: dependencies,
      familyController: familyController,
      clock: () => now,
    );
    addTearDown(() {
      symptomController.dispose();
      familyController.dispose();
    });
  }

  Future<void> loadAll() async {
    await familyController.load();
    await symptomController.load();
  }

  /// Tall by default, so every card is built; tests of narrow screens set
  /// their own size first.
  Future<void> pumpScreen(WidgetTester tester) {
    if (tester.view.physicalSize == const Size(2400, 1800)) {
      tester.setScreenSize(const Size(400, 2400));
    }
    return tester.pumpApp(
      SymptomsScreen(clock: () => now),
      dependencies: dependencies,
      familyController: familyController,
      symptomController: symptomController,
    );
  }

  double top(WidgetTester tester, Finder finder) =>
      tester.getTopLeft(finder).dy;

  /// Ids of the shown cards, top to bottom.
  List<String> shownIds(WidgetTester tester) {
    final cards = tester.widgetList<SymptomCard>(find.byType(SymptomCard));
    final byPosition = [
      for (final card in cards)
        (card.entry.id, top(tester, find.byWidget(card))),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final (id, _) in byPosition) id];
  }

  String dayTitle(WidgetTester tester, DateTime day) => formatSymptomDay(
    day,
    now,
    MaterialLocalizations.of(tester.element(find.byType(SymptomsScreen))),
  );

  Future<void> selectFilter(WidgetTester tester, String label) async {
    await tester.tap(find.widgetWithText(ChoiceChip, label));
    await tester.pumpAndSettle();
  }

  group('header', () {
    testWidgets('shows the title, demo notice and disclaimer', (tester) async {
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);

      expect(find.text(AppStrings.symptomsTitle), findsOneWidget);
      expect(find.byType(DemoDataBanner), findsOneWidget);
      expect(find.text(AppStrings.symptomsDisclaimer), findsOneWidget);
    });

    testWidgets('"log a symptom" opens the form for the filtered member', (
      tester,
    ) async {
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);
      await selectFilter(tester, 'נועה');

      await tester.tap(find.text(AppStrings.actionLogSymptom));
      await tester.pumpAndSettle();

      final form = tester.widget<SymptomFormScreen>(
        find.byType(SymptomFormScreen),
      );
      expect(form.entryId, isNull);
      expect(form.initialMemberId, 'm2');
    });

    testWidgets('tapping a card opens it for editing', (tester) async {
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('headache')));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<SymptomFormScreen>(find.byType(SymptomFormScreen))
            .entryId,
        'headache',
      );
    });
  });

  group('records', () {
    testWidgets('newest first, grouped by day under dated headings', (
      tester,
    ) async {
      tester.setScreenSize(const Size(400, 2400));
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);

      expect(shownIds(tester), ['headache', 'fever-2', 'fever-1', 'old']);

      final today = find.text(dayTitle(tester, now));
      final yesterday = find.text(dayTitle(tester, DateTime(2026, 10, 14)));
      final older = find.text(dayTitle(tester, DateTime(2026, 10, 10)));
      expect(today, findsOneWidget);
      expect(yesterday, findsOneWidget);
      expect(older, findsOneWidget);

      double card(String id) => top(tester, find.byKey(ValueKey(id)));
      expect(top(tester, today), lessThan(card('headache')));
      expect(card('fever-2'), lessThan(top(tester, yesterday)));
      expect(top(tester, yesterday), lessThan(card('fever-1')));
      expect(card('fever-1'), lessThan(top(tester, older)));
      expect(top(tester, older), lessThan(card('old')));
    });

    testWidgets('day headings always include the date', (tester) async {
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);

      expect(find.text('היום · יום ה׳, 15 באוק׳'), findsOneWidget);
      expect(find.text('אתמול · יום ד׳, 14 באוק׳'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('יום שבת, 10 באוקטובר 2026'),
        300,
      );
      expect(find.text('יום שבת, 10 באוקטובר 2026'), findsOneWidget);
      // The card itself carries the full date and time.
      expect(find.text('15 באוק׳ 2026 · 9:30'), findsOneWidget);
    });

    testWidgets('a card shows what, who, when, the rating and the notes', (
      tester,
    ) async {
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);

      final card = find.byKey(const ValueKey('headache'));
      Finder inCard(String text) =>
          find.descendant(of: card, matching: find.text(text));

      expect(inCard('כאב ראש'), findsOneWidget);
      expect(inCard('דנה'), findsOneWidget);
      expect(
        find.descendant(of: card, matching: find.text('15 באוק׳ 2026 · 9:30')),
        findsOneWidget,
      );
      expect(inCard(AppStrings.symptomSeverity(2, 5)), findsOneWidget);
      expect(inCard('אחרי העבודה'), findsOneWidget);
    });

    testWidgets('a card without notes shows no notes line', (tester) async {
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);

      final card = find.byKey(const ValueKey('fever-2'));
      final texts = tester
          .widgetList<Text>(
            find.descendant(of: card, matching: find.byType(Text)),
          )
          .map((t) => t.data)
          .toList();
      // Name, member, time, rating and the track link.
      expect(texts, hasLength(5));
    });

    testWidgets('the rating uses one neutral color at every level', (
      tester,
    ) async {
      setUpWith([
        entry('low', 'm1', 'עייפות', DateTime(2026, 10, 15, 7), 1),
        entry('high', 'm1', 'עייפות', DateTime(2026, 10, 15, 6), 5),
      ]);
      await loadAll();
      await pumpScreen(tester);

      Color? dotColor(String id, int level) {
        final dot = tester.widget<Container>(
          find.descendant(
            of: find.byKey(ValueKey(id)),
            matching: find.byKey(ValueKey('severity-dot-$level')),
          ),
        );
        return (dot.decoration! as BoxDecoration).color;
      }

      final primary = Theme.of(
        tester.element(find.byType(SymptomsScreen)),
      ).colorScheme.primary;
      expect(dotColor('low', 1), primary);
      expect(dotColor('low', 2), isNot(primary));
      for (var level = 1; level <= 5; level++) {
        expect(dotColor('high', level), primary);
      }
    });

    testWidgets('a record of an unknown member is still shown', (tester) async {
      setUpWith([entry('orphan', 'gone', 'שיעול', now, 2)]);
      await loadAll();
      await pumpScreen(tester);

      expect(find.text(AppStrings.unknownMember), findsOneWidget);
    });
  });

  group('member filter', () {
    testWidgets('starts on the whole family', (tester) async {
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, AppStrings.filterAllFamily),
      );
      expect(chip.selected, isTrue);
      expect(find.byType(SymptomCard), findsNWidgets(4));
    });

    testWidgets('shows only the chosen member, and back to everyone', (
      tester,
    ) async {
      tester.setScreenSize(const Size(400, 2400));
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);

      await selectFilter(tester, 'נועה');
      expect(shownIds(tester), ['fever-2', 'fever-1']);
      // Days with no records of hers are not shown.
      expect(find.text(dayTitle(tester, DateTime(2026, 10, 10))), findsNothing);

      await selectFilter(tester, 'דנה');
      expect(shownIds(tester), ['headache', 'old']);

      await selectFilter(tester, AppStrings.filterAllFamily);
      expect(shownIds(tester), ['headache', 'fever-2', 'fever-1', 'old']);
    });

    testWidgets('a member without records gets their own empty state', (
      tester,
    ) async {
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);

      await selectFilter(tester, 'אבי');

      expect(find.byType(SymptomCard), findsNothing);
      expect(
        find.text(AppStrings.symptomsEmptyForMember('אבי')),
        findsOneWidget,
      );
      expect(find.text(AppStrings.symptomsEmptyTitle), findsNothing);

      await tester.tap(find.text(AppStrings.showAllFamily));
      await tester.pumpAndSettle();
      expect(find.byType(SymptomCard), findsNWidgets(4));
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, AppStrings.filterAllFamily),
            )
            .selected,
        isTrue,
      );
    });
  });

  group('states', () {
    testWidgets('without any records: an empty state and no filter', (
      tester,
    ) async {
      setUpWith([]);
      await loadAll();
      await pumpScreen(tester);

      expect(find.text(AppStrings.symptomsEmptyTitle), findsOneWidget);
      expect(find.byType(ChoiceChip), findsNothing);
      // The disabled button and notices are still there.
      expect(find.text(AppStrings.actionLogSymptom), findsOneWidget);
      expect(find.text(AppStrings.symptomsDisclaimer), findsOneWidget);
    });

    testWidgets('shows progress while loading, then the records', (
      tester,
    ) async {
      setUpWith(sampleEntries);
      await familyController.load();
      symptomRepository.getAllGate = Completer<void>();
      unawaited(symptomController.load());
      await pumpScreen(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text(AppStrings.symptomsEmptyTitle), findsNothing);

      symptomRepository.getAllGate!.complete();
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.byType(SymptomCard), findsNWidgets(4));
    });

    testWidgets('a failed first load offers a retry that works', (
      tester,
    ) async {
      setUpWith(sampleEntries);
      await familyController.load();
      symptomRepository.failGetAll = true;
      await symptomController.load();
      await pumpScreen(tester);

      expect(find.byType(LoadErrorView), findsOneWidget);
      expect(find.text(AppStrings.symptomsLoadErrorTitle), findsOneWidget);
      expect(find.text(AppStrings.symptomsEmptyTitle), findsNothing);

      symptomRepository.failGetAll = false;
      await tester.tap(find.text(AppStrings.retry));
      await tester.pumpAndSettle();

      expect(find.byType(LoadErrorView), findsNothing);
      expect(find.byType(SymptomCard), findsNWidgets(4));
    });

    testWidgets('a failed refresh keeps the records and offers a retry', (
      tester,
    ) async {
      setUpWith(sampleEntries);
      await loadAll();
      symptomRepository.failGetAll = true;
      await symptomController.load();
      await pumpScreen(tester);

      expect(find.byType(RefreshErrorCard), findsOneWidget);
      expect(find.byType(SymptomCard), findsNWidgets(4));

      symptomRepository.failGetAll = false;
      await tester.tap(find.text(AppStrings.retry));
      await tester.pumpAndSettle();

      expect(find.byType(RefreshErrorCard), findsNothing);
    });
  });

  group('updates', () {
    testWidgets('follows records added, changed and deleted elsewhere', (
      tester,
    ) async {
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);

      final added = entry(
        symptomController.createId(),
        'm3',
        'כאב גב',
        DateTime(2026, 10, 15, 11),
        3,
      );
      await tester.runAsync(() => symptomController.add(added));
      await tester.pumpAndSettle();
      expect(find.text('כאב גב'), findsOneWidget);

      await tester.runAsync(
        () => symptomController.update(
          added.id,
          memberId: 'm3',
          name: 'כאב כתף',
          startedAt: added.startedAt,
          severity: 3,
          notes: null,
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('כאב גב'), findsNothing);
      expect(find.text('כאב כתף'), findsOneWidget);

      await tester.runAsync(
        () => symptomController.delete(added.id, userConfirmed: true),
      );
      await tester.pumpAndSettle();
      expect(find.text('כאב כתף'), findsNothing);
      expect(find.byType(SymptomCard), findsNWidgets(4));
    });

    testWidgets('a member deleted while filtered on: back to everyone, '
        'without their records', (tester) async {
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);
      await selectFilter(tester, 'נועה');

      await tester.runAsync(
        () => familyController.delete('m2', userConfirmed: true),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'נועה'), findsNothing);
      expect(
        tester
            .widget<ChoiceChip>(
              find.widgetWithText(ChoiceChip, AppStrings.filterAllFamily),
            )
            .selected,
        isTrue,
      );
      expect(find.text('חום'), findsNothing);
      expect(find.byType(SymptomCard), findsNWidgets(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('a member deletion that failed keeps everything shown', (
      tester,
    ) async {
      setUpWith(sampleEntries);
      await loadAll();
      await pumpScreen(tester);
      symptomRepository.failDeleteByMember = true;

      await tester.runAsync(
        () => familyController.delete('m2', userConfirmed: true),
      );
      await tester.pumpAndSettle();

      expect(find.widgetWithText(ChoiceChip, 'נועה'), findsOneWidget);
      expect(find.byType(SymptomCard), findsNWidgets(4));
    });
  });

  testWidgets('lays out without overflow on a narrow screen with large text', (
    tester,
  ) async {
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    setUpWith([
      ...sampleEntries,
      entry(
        'long',
        'm3',
        'תסמין עם שם ארוך מאוד לבדיקת שבירת שורות בכרטיס',
        DateTime(2025, 1, 31, 23, 59),
        5,
        notes:
            'הערה ארוכה מאוד שנכתבה כדי לבדוק שהטקסט נשבר כראוי '
            'לשורות נוספות ואינו חורג מגבולות הכרטיס במסך צר',
      ),
    ]);
    await loadAll();
    symptomRepository.failGetAll = true;
    await symptomController.load(); // Also shows the refresh warning.
    await pumpScreen(tester);

    for (var i = 0; i < 6; i++) {
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }
    expect(find.byKey(const ValueKey('long')), findsOneWidget);
  });

  testWidgets('empty and error states fit a narrow screen with large text', (
    tester,
  ) async {
    tester.setScreenSize(const Size(320, 568));
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    setUpWith(sampleEntries);
    await familyController.load();
    symptomRepository.failGetAll = true;
    await symptomController.load();
    await pumpScreen(tester);

    expect(find.byType(LoadErrorView), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
