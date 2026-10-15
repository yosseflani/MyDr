import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/core/l10n/strings.dart';
import 'package:mydr/core/widgets/load_error_views.dart';
import 'package:mydr/core/widgets/not_found_view.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/features/family/family_controller.dart';
import 'package:mydr/features/symptoms/symptom_controller.dart';
import 'package:mydr/features/symptoms/symptom_form_screen.dart';
import 'package:mydr/features/symptoms/symptom_formatting.dart';
import 'package:mydr/features/symptoms/symptom_track_screen.dart';
import 'package:mydr/features/symptoms/symptoms_screen.dart';
import 'package:mydr/features/symptoms/widgets/symptom_card.dart';

import '../../helpers/flaky_repositories.dart';
import '../../helpers/pump_app.dart';

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

  // Noa's cough, written slightly differently once, months apart, and twice
  // at the same moment; plus records that must not be included.
  final sampleEntries = [
    entry('c3', 'm2', 'שיעול', DateTime(2026, 10, 15, 8), 2, notes: 'פחות'),
    entry('c1', 'm2', 'שיעול', DateTime(2026, 1, 10, 9), 3, notes: 'בחורף'),
    entry('c4', 'm2', 'שיעול', DateTime(2026, 10, 15, 8), 1),
    entry('c2', 'm2', '  שיעול ', DateTime(2026, 10, 13, 20), 4),
    entry('other-member', 'm1', 'שיעול', DateTime(2026, 10, 14, 9), 5),
    entry('other-name', 'm2', 'כאב ראש', DateTime(2026, 10, 14, 10), 2),
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

  Future<void> pumpTrack(WidgetTester tester, {String name = 'שיעול'}) => pump(
    tester,
    SymptomTrackScreen(memberId: 'm2', name: name, clock: () => now),
  );

  String dateTime(WidgetTester tester, DateTime value) => formatSymptomDateTime(
    value,
    MaterialLocalizations.of(tester.element(find.byType(Scaffold).first)),
  );

  /// Ids of the shown records, top to bottom.
  List<String> shownIds(WidgetTester tester) {
    final ids = ['c1', 'c2', 'c3', 'c4', 'new', 'other-member', 'other-name'];
    final shown = [
      for (final id in ids)
        if (find.byKey(ValueKey(id)).evaluate().isNotEmpty)
          (id, tester.getTopLeft(find.byKey(ValueKey(id))).dy),
    ]..sort((a, b) => a.$2.compareTo(b.$2));
    return [for (final (id, _) in shown) id];
  }

  Finder severityButton(int level) => find.descendant(
    of: find.byType(SegmentedButton<int>),
    matching: find.text('$level'),
  );

  Future<void> tapAndSettle(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('summary and records', () {
    testWidgets('shows the symptom, member, count, last record and a note '
        'that it is not interpreted', (tester) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      expect(find.text(AppStrings.symptomTrackTitle), findsOneWidget);
      expect(find.text('שיעול'), findsOneWidget);
      expect(find.text('נועה'), findsOneWidget);
      expect(find.text(AppStrings.symptomRecordCount(4)), findsOneWidget);
      expect(
        find.text(
          AppStrings.lastRecordedAt(
            dateTime(tester, DateTime(2026, 10, 15, 8)),
          ),
        ),
        findsOneWidget,
      );
      expect(find.text(AppStrings.symptomTrackDisclaimer), findsOneWidget);
    });

    testWidgets('only this member and this name, oldest first, records at '
        'the same moment in a fixed order', (tester) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      // c3 and c4 share a moment: the reverse of the journal's id order.
      expect(shownIds(tester), ['c1', 'c2', 'c4', 'c3']);
    });

    testWidgets('the same name written differently is the same group', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester, name: '  שיעול  ');

      expect(find.text(AppStrings.symptomRecordCount(4)), findsOneWidget);
    });

    testWidgets('each record shows when, the rating and the notes', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      final record = find.byKey(const ValueKey('c1'));
      Finder inRecord(String text) =>
          find.descendant(of: record, matching: find.text(text));
      expect(inRecord(dateTime(tester, DateTime(2026, 1, 10, 9))), findsOne);
      expect(inRecord(AppStrings.symptomSeverity(3, 5)), findsOneWidget);
      expect(inRecord('בחורף'), findsOneWidget);
    });

    testWidgets('a single record is shown as such', (tester) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester, name: 'כאב ראש');

      expect(find.text(AppStrings.symptomRecordCount(1)), findsOneWidget);
      expect(shownIds(tester), ['other-name']);
    });

    testWidgets('fits a narrow screen with large text', (tester) async {
      await setUpWith(sampleEntries);
      tester.platformDispatcher.textScaleFactorTestValue = 1.5;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pump(
        tester,
        SymptomTrackScreen(memberId: 'm2', name: 'שיעול', clock: () => now),
        size: const Size(320, 568),
      );

      for (var i = 0; i < 6; i++) {
        await tester.drag(find.byType(ListView), const Offset(0, -400));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      expect(find.byKey(const ValueKey('c3')), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('journal cards link to their track, with the count', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pump(tester, SymptomsScreen(clock: () => now));

      final card = find.byKey(const ValueKey('c3'));
      final link = find.descendant(
        of: card,
        matching: find.text(AppStrings.openSymptomTrack(4)),
      );
      expect(link, findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('other-name')),
          matching: find.text(AppStrings.openSymptomTrack(1)),
        ),
        findsOneWidget,
      );

      await tapAndSettle(tester, link);

      final track = tester.widget<SymptomTrackScreen>(
        find.byType(SymptomTrackScreen),
      );
      expect(track.memberId, 'm2');
      expect(SymptomController.normalizeName(track.name), 'שיעול');
    });

    testWidgets('tapping a journal card still edits that record', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pump(tester, SymptomsScreen(clock: () => now));

      await tapAndSettle(tester, find.text('פחות'));

      expect(
        tester
            .widget<SymptomFormScreen>(find.byType(SymptomFormScreen))
            .entryId,
        'c3',
      );
      expect(find.byType(SymptomTrackScreen), findsNothing);
    });

    testWidgets('tapping a record opens it for editing', (tester) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      await tapAndSettle(tester, find.byKey(const ValueKey('c2')));

      expect(
        tester
            .widget<SymptomFormScreen>(find.byType(SymptomFormScreen))
            .entryId,
        'c2',
      );
    });
  });

  group('follow-up', () {
    testWidgets('opens the form with the member and name filled in', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      await tapAndSettle(tester, find.text(AppStrings.addFollowUpRecord));

      final form = tester.widget<SymptomFormScreen>(
        find.byType(SymptomFormScreen),
      );
      expect(form.entryId, isNull);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byType(DropdownButtonFormField<String>),
            )
            .initialValue,
        'm2',
      );
      expect(
        tester
            .widget<TextFormField>(
              find.widgetWithText(TextFormField, AppStrings.symptomNameLabel),
            )
            .controller!
            .text,
        'שיעול',
      );

      // Filled-in values are not unsaved changes: leaving does not ask.
      await tapAndSettle(tester, find.byType(BackButton));
      expect(find.text(AppStrings.discardChangesTitle), findsNothing);
      expect(find.byType(SymptomTrackScreen), findsOneWidget);
    });

    testWidgets('saving returns to the track, with the new record last', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      await tapAndSettle(tester, find.text(AppStrings.addFollowUpRecord));
      await tapAndSettle(tester, severityButton(3));
      await tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, AppStrings.save),
      );

      expect(find.byType(SymptomFormScreen), findsNothing);
      expect(find.text(AppStrings.symptomRecordCount(5)), findsOneWidget);
      final added = symptomController.groupFor('m2', 'שיעול')!.latest;
      expect(added.startedAt, now);
      expect(shownIds(tester).length, 4);
      final ids = [
        for (final e in symptomController.groupFor('m2', 'שיעול')!.entries)
          e.id,
      ];
      expect(ids.last, added.id);
      expect(
        tester.getTopLeft(find.byKey(ValueKey(added.id))).dy,
        greaterThan(tester.getTopLeft(find.byKey(const ValueKey('c3'))).dy),
      );
    });

    testWidgets('the filled-in name can be changed; the record then goes '
        'to its own group', (tester) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      await tapAndSettle(tester, find.text(AppStrings.addFollowUpRecord));
      await tester.enterText(
        find.widgetWithText(TextFormField, AppStrings.symptomNameLabel),
        'צרידות',
      );
      await tapAndSettle(tester, severityButton(2));
      await tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, AppStrings.save),
      );

      expect(find.text(AppStrings.symptomRecordCount(4)), findsOneWidget);
      expect(symptomController.groupFor('m2', 'צרידות'), isNotNull);
    });
  });

  group('changes while open', () {
    testWidgets('a record added elsewhere appears', (tester) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      await tester.runAsync(
        () => symptomController.add(
          entry('new', 'm2', 'שיעול', DateTime(2026, 10, 15, 11), 2),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(AppStrings.symptomRecordCount(5)), findsOneWidget);
      expect(shownIds(tester).last, 'new');
    });

    testWidgets('an edited rating and notes show right away', (tester) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      await tester.runAsync(
        () => symptomController.update(
          'c1',
          memberId: 'm2',
          name: 'שיעול',
          startedAt: DateTime(2026, 1, 10, 9),
          severity: 5,
          notes: 'עדכון',
        ),
      );
      await tester.pumpAndSettle();

      final record = find.byKey(const ValueKey('c1'));
      expect(
        find.descendant(of: record, matching: find.text('עדכון')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: record,
          matching: find.text(AppStrings.symptomSeverity(5, 5)),
        ),
        findsOneWidget,
      );
    });

    testWidgets('a renamed record or one moved to another member leaves', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      await tester.runAsync(
        () => symptomController.update(
          'c1',
          memberId: 'm2',
          name: 'שיעול יבש',
          startedAt: DateTime(2026, 1, 10, 9),
          severity: 3,
          notes: null,
        ),
      );
      await tester.runAsync(
        () => symptomController.update(
          'c2',
          memberId: 'm1',
          name: 'שיעול',
          startedAt: DateTime(2026, 10, 13, 20),
          severity: 4,
          notes: null,
        ),
      );
      await tester.pumpAndSettle();

      expect(shownIds(tester), ['c4', 'c3']);
      expect(find.text(AppStrings.symptomRecordCount(2)), findsOneWidget);
    });

    testWidgets('deleting records; once none are left, says so', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      for (final id in ['c1', 'c2', 'c3']) {
        await tester.runAsync(
          () => symptomController.delete(id, userConfirmed: true),
        );
      }
      await tester.pumpAndSettle();
      expect(find.text(AppStrings.symptomRecordCount(1)), findsOneWidget);
      expect(
        find.text(
          AppStrings.lastRecordedAt(
            dateTime(tester, DateTime(2026, 10, 15, 8)),
          ),
        ),
        findsOneWidget,
      );

      await tester.runAsync(
        () => symptomController.delete('c4', userConfirmed: true),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NotFoundView), findsOneWidget);
      expect(
        find.text(AppStrings.symptomTrackEmptyTitle('שיעול')),
        findsOneWidget,
      );
      // Still possible to start again from here.
      expect(find.text(AppStrings.addFollowUpRecord), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a deleted family member: their track is gone', (tester) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      await tester.runAsync(
        () => familyController.delete('m2', userConfirmed: true),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(AppStrings.symptomTrackMemberMissingTitle),
        findsOneWidget,
      );
      expect(find.text(AppStrings.addFollowUpRecord), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('editing from the track and saving returns to it', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      await pumpTrack(tester);

      await tapAndSettle(tester, find.byKey(const ValueKey('c2')));
      await tapAndSettle(tester, severityButton(1));
      await tapAndSettle(
        tester,
        find.widgetWithText(FilledButton, AppStrings.save),
      );

      expect(find.byType(SymptomTrackScreen), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('c2')),
          matching: find.text(AppStrings.symptomSeverity(1, 5)),
        ),
        findsOneWidget,
      );
    });
  });

  group('loading', () {
    testWidgets('shows progress, then the records', (tester) async {
      await setUpWith(sampleEntries, load: false);
      symptomRepository.getAllGate = Completer<void>();
      unawaited(symptomController.load());
      await pumpTrack(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(NotFoundView), findsNothing);

      symptomRepository.getAllGate!.complete();
      await tester.pumpAndSettle();
      expect(shownIds(tester), hasLength(4));
    });

    testWidgets('a failed load offers a retry that works', (tester) async {
      await setUpWith(sampleEntries, load: false);
      symptomRepository.failGetAll = true;
      await symptomController.load();
      await pumpTrack(tester);

      expect(find.byType(LoadErrorView), findsOneWidget);
      expect(find.byType(NotFoundView), findsNothing);

      symptomRepository.failGetAll = false;
      await tapAndSettle(tester, find.text(AppStrings.retry));

      expect(find.byType(LoadErrorView), findsNothing);
      expect(shownIds(tester), hasLength(4));
    });

    testWidgets('a failed refresh keeps the records, with a warning', (
      tester,
    ) async {
      await setUpWith(sampleEntries);
      symptomRepository.failGetAll = true;
      await symptomController.load();
      await pumpTrack(tester);

      expect(find.byType(RefreshErrorCard), findsOneWidget);
      expect(shownIds(tester), hasLength(4));
    });
  });

  testWidgets('the journal card count follows the group', (tester) async {
    await setUpWith(sampleEntries);
    await pump(tester, SymptomsScreen(clock: () => now));

    await tester.runAsync(
      () => symptomController.delete('c1', userConfirmed: true),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(SymptomCard),
        matching: find.text(AppStrings.openSymptomTrack(3)),
      ),
      findsNWidgets(3),
    );
  });
}
