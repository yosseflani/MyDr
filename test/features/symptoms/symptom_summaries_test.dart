import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/features/dashboard/widgets/recent_symptoms_card.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/family/member_detail_screen.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/symptoms/symptom_form_screen.dart';
import 'package:mydr/features/symptoms/symptom_formatting.dart';
import 'package:mydr/features/symptoms/symptom_track_screen.dart';
import 'package:mydr/features/symptoms/symptoms_screen.dart';
import 'package:mydr/features/symptoms/widgets/member_symptoms_section.dart';
import 'package:mydr/features/symptoms/widgets/recent_symptom_tile.dart';
import 'package:mydr/features/symptoms/widgets/symptom_card.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

/// The symptom summaries outside the journal: the home screen card and the
/// section in a family member's profile.
void main() {
  final now = DateTime(2026, 10, 15, 12);

  final members = [
    FamilyMember(id: 'm1', name: 'דנה', relation: FamilyRelation.self),
    FamilyMember(id: 'm2', name: 'נועה', relation: FamilyRelation.child),
  ];

  SymptomEntry entry(
    String id,
    String memberId,
    String name,
    DateTime startedAt,
  ) => SymptomEntry(
    id: id,
    memberId: memberId,
    name: name,
    startedAt: startedAt,
    severity: 2,
  );

  // Dana has four records; Noa has the newest one overall.
  final sampleEntries = [
    entry('a3', 'm1', 'שיעול', DateTime(2026, 10, 13, 8)),
    entry('b1', 'm2', 'חום', DateTime(2026, 10, 15, 10)),
    entry('a1', 'm1', 'כאב ראש', DateTime(2026, 10, 15, 9)),
    entry('a4', 'm1', 'חום', DateTime(2026, 10, 1, 8)),
    entry('a2', 'm1', 'שיעול', DateTime(2026, 10, 14, 8)),
  ];

  late FlakyFamilyRepository familyRepository;
  late FlakySymptomRepository symptomRepository;
  late AppDependencies dependencies;
  late FamilyController familyController;
  late SymptomController symptomController;

  Future<void> setUpWith(List<SymptomEntry> entries, {bool load = true}) async {
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
    await familyController.load();
    if (load) await symptomController.load();
  }

  Future<void> pump(WidgetTester tester, Widget screen, {Size? size}) {
    tester.setScreenSize(size ?? const Size(400, 2400));
    return tester.pumpApp(
      screen,
      dependencies: dependencies,
      familyController: familyController,
      symptomController: symptomController,
    );
  }

  /// Ids of the shown summary rows, top to bottom.
  List<String> shownIds(WidgetTester tester) {
    final tiles = tester.widgetList<RecentSymptomTile>(
      find.byType(RecentSymptomTile),
    );
    final byPosition = [
      for (final tile in tiles)
        (tile.entry.id, tester.getTopLeft(find.byWidget(tile)).dy),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final (id, _) in byPosition) id];
  }

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('home screen card', () {
    var showAllTaps = 0;

    Widget card({bool withShowAll = true}) => Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          RecentSymptomsCard(
            onShowAll: withShowAll ? () => showAllTaps++ : null,
            clock: () => now,
          ),
        ],
      ),
    );

    setUp(() => showAllTaps = 0);

    testWidgets('shows the three latest records of the whole family, with '
        'who and when, and the disclaimer', (tester) async {
      await setUpWith(sampleEntries);
      await pump(tester, card());

      expect(shownIds(tester), ['b1', 'a1', 'a2']);
      final localizations = MaterialLocalizations.of(
        tester.element(find.byType(RecentSymptomsCard)),
      );
      expect(
        find.text(
          'נועה · '
          '${formatSymptomDateTime(DateTime(2026, 10, 15, 10), localizations)}',
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.symptomsDisclaimer), findsOneWidget);
    });

    testWidgets('a record opens for editing', (tester) async {
      await setUpWith(sampleEntries);
      await pump(tester, card());

      await tapAndSettle(tester, find.byKey(const ValueKey('a1')));

      expect(
        tester
            .widget<SymptomFormScreen>(find.byType(SymptomFormScreen))
            .entryId,
        'a1',
      );
    });

    testWidgets('"show all" asks to show the journal', (tester) async {
      await setUpWith(sampleEntries);
      await pump(tester, card());

      await tapAndSettle(tester, find.text(AppStrings.showAllSymptoms));

      expect(showAllTaps, 1);
    });

    testWidgets('without a way to show all, there is no such link', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pump(tester, card(withShowAll: false));

      expect(find.text(AppStrings.showAllSymptoms), findsNothing);
    });

    testWidgets('empty, loading and failed states', (tester) async {
      await setUpWith([], load: false);
      symptomRepository.getAllGate = Completer<void>();
      unawaited(symptomController.load());
      await pump(tester, card());
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      symptomRepository.getAllGate!.complete();
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.recentSymptomsEmptyTitle), findsOneWidget);

      symptomRepository.failGetAll = true;
      await tester.runAsync(symptomController.load);
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.symptomsLoadErrorTitle), findsOneWidget);

      symptomRepository
        ..failGetAll = false
        ..add(entry('new', 'm1', 'בחילה', DateTime(2026, 10, 15, 11)));
      await tapAndSettle(tester, find.text(AppStrings.retry));
      expect(shownIds(tester), ['new']);
    });

    testWidgets('follows records added and deleted, and deleted members', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pump(tester, card());

      await tester.runAsync(
        () => symptomController.add(
          entry('new', 'm1', 'בחילה', DateTime(2026, 10, 15, 11)),
        ),
      );
      await tester.pumpAndSettle();
      expect(shownIds(tester), ['new', 'b1', 'a1']);

      await tester.runAsync(
        () => symptomController.delete('new', userConfirmed: true),
      );
      await tester.pumpAndSettle();
      expect(shownIds(tester), ['b1', 'a1', 'a2']);

      await tester.runAsync(
        () => familyController.delete('m2', userConfirmed: true),
      );
      await tester.pumpAndSettle();
      expect(shownIds(tester), ['a1', 'a2', 'a3']);
      expect(find.textContaining('נועה'), findsNothing);
    });

    testWidgets('fits a narrow screen with large text', (tester) async {
      await setUpWith([
        ...sampleEntries,
        entry(
          'long',
          'm2',
          'תסמין עם שם ארוך מאוד לבדיקת שבירת שורות',
          DateTime(2026, 10, 15, 11, 30),
        ),
      ]);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(tester, card(), size: const Size(320, 568));

      await tester.drag(find.byType(ListView), const Offset(0, -1000));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });

  group('profile section', () {
    Future<void> pumpProfile(WidgetTester tester, String memberId) =>
        pump(tester, MemberDetailScreen(memberId: memberId));

    final section = find.byType(MemberSymptomsSection);

    testWidgets("shows only this member's latest records, and how many", (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pumpProfile(tester, 'm1');

      expect(section, findsOneWidget);
      expect(shownIds(tester), ['a1', 'a2', 'a3']);
      expect(
        find.descendant(
          of: section,
          matching: find.text(AppStrings.symptomRecordCount(4)),
        ),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('b1')), findsNothing);
      expect(
        find.descendant(
          of: section,
          matching: find.text(AppStrings.symptomsDisclaimer),
        ),
        findsOneWidget,
      );
    });

    testWidgets('another member sees only their own', (tester) async {
      await setUpWith(sampleEntries);
      await pumpProfile(tester, 'm2');

      expect(shownIds(tester), ['b1']);
    });

    testWidgets('a record opens for editing', (tester) async {
      await setUpWith(sampleEntries);
      await pumpProfile(tester, 'm1');

      await tapAndSettle(tester, find.text('כאב ראש'));

      expect(
        tester
            .widget<SymptomFormScreen>(find.byType(SymptomFormScreen))
            .entryId,
        'a1',
      );
    });

    testWidgets("a record's track button opens that symptom's track for "
        'this member', (tester) async {
      await setUpWith(sampleEntries);
      await pumpProfile(tester, 'm1');

      await tapAndSettle(
        tester,
        find.descendant(
          of: find.byKey(const ValueKey('a2')),
          matching: find.byTooltip(AppStrings.symptomTrackTitle),
        ),
      );

      final track = tester.widget<SymptomTrackScreen>(
        find.byType(SymptomTrackScreen),
      );
      expect(track.memberId, 'm1');
      expect(track.name, 'שיעול');
      expect(find.text(AppStrings.symptomRecordCount(2)), findsOneWidget);
    });

    testWidgets('"log a symptom" preselects this member', (tester) async {
      await setUpWith(sampleEntries);
      await pumpProfile(tester, 'm2');

      await tapAndSettle(
        tester,
        find.descendant(
          of: section,
          matching: find.text(AppStrings.actionLogSymptom),
        ),
      );

      expect(
        tester
            .widget<SymptomFormScreen>(find.byType(SymptomFormScreen))
            .initialMemberId,
        'm2',
      );
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .initialValue,
        'm2',
      );
    });

    testWidgets('"all records" opens the journal filtered on this member', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pumpProfile(tester, 'm1');

      await tapAndSettle(tester, find.text(AppStrings.allMemberSymptoms));

      expect(find.byType(SymptomsScreen), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'דנה'))
            .selected,
        isTrue,
      );
      expect(find.byType(SymptomCard), findsNWidgets(4));
      expect(find.byKey(const ValueKey('b1')), findsNothing);

      await tapAndSettle(tester, find.byType(BackButton));
      expect(find.byType(MemberDetailScreen), findsOneWidget);
    });

    testWidgets('without records: says so, still offers to log one', (
      tester,
    ) async {
      await setUpWith([sampleEntries[1]]);
      await pumpProfile(tester, 'm1');

      expect(find.text(AppStrings.memberSymptomsEmpty), findsOneWidget);
      expect(find.text(AppStrings.allMemberSymptoms), findsNothing);
      expect(
        find.descendant(
          of: section,
          matching: find.text(AppStrings.actionLogSymptom),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a failed load offers a retry', (tester) async {
      await setUpWith(sampleEntries, load: false);
      symptomRepository.failGetAll = true;
      await symptomController.load();
      await pumpProfile(tester, 'm1');

      expect(
        find.descendant(
          of: section,
          matching: find.text(AppStrings.symptomsLoadErrorTitle),
        ),
        findsOneWidget,
      );

      symptomRepository.failGetAll = false;
      await tapAndSettle(
        tester,
        find.descendant(of: section, matching: find.text(AppStrings.retry)),
      );
      expect(shownIds(tester), ['a1', 'a2', 'a3']);
    });

    testWidgets("follows changes: only this member's records come and go", (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pumpProfile(tester, 'm2');

      await tester.runAsync(
        () => symptomController.add(
          entry('dana-new', 'm1', 'בחילה', DateTime(2026, 10, 15, 11)),
        ),
      );
      await tester.runAsync(
        () => symptomController.add(
          entry('noa-new', 'm2', 'בחילה', DateTime(2026, 10, 15, 11)),
        ),
      );
      await tester.pumpAndSettle();
      expect(shownIds(tester), ['noa-new', 'b1']);

      // Moved to another member: gone from this profile.
      await tester.runAsync(
        () => symptomController.update(
          'noa-new',
          memberId: 'm1',
          name: 'בחילה',
          startedAt: DateTime(2026, 10, 15, 11),
          severity: 2,
          notes: null,
        ),
      );
      await tester.pumpAndSettle();
      expect(shownIds(tester), ['b1']);

      await tester.runAsync(
        () => symptomController.delete('b1', userConfirmed: true),
      );
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.memberSymptomsEmpty), findsOneWidget);
    });

    testWidgets('fits a narrow screen with large text', (tester) async {
      await setUpWith(sampleEntries);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(
        tester,
        const MemberDetailScreen(memberId: 'm1'),
        size: const Size(320, 568),
      );

      await tester.scrollUntilVisible(
        find.text(AppStrings.allMemberSymptoms),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(tester.takeException(), isNull);
    });
  });
}
