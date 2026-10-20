import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/backup/backup_snapshot.dart';
import 'package:mydr/data/mock/mock_data.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/family_member.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);

  BackupSnapshot demo({List<Appointment>? appointments}) => BackupSnapshot(
    familyMembers: MockData.members(),
    appointments: appointments ?? MockData.appointments(now),
    doctorQuestions: MockData.questions(now),
    symptoms: MockData.symptoms(now),
    visitMedia: const [],
    medications: MockData.medications(now),
    doseRecords: MockData.doseRecords(now),
  );

  Matcher refused() => throwsA(isA<BackupFormatException>());

  test('round-trips every kind of record exactly', () {
    final snapshot = demo();
    final back = BackupSnapshot.decode(snapshot.encode());
    expect(back.familyMembers, snapshot.familyMembers);
    expect(back.appointments, snapshot.appointments);
    expect(back.doctorQuestions, snapshot.doctorQuestions);
    expect(back.symptoms, snapshot.symptoms);
    expect(back.medications, snapshot.medications);
    expect(back.doseRecords, snapshot.doseRecords);
    expect(back.counts.toJson(), snapshot.counts.toJson());
  });

  test("refuses a record pointing at another member's record", () {
    final appointment = MockData.appointments(now).first;
    expect(
      () => demo(
        appointments: [
          ...MockData.appointments(now),
          Appointment(
            id: 'x',
            memberId: 'nobody',
            doctorName: 'd',
            dateTime: appointment.dateTime,
          ),
        ],
      ).validate(),
      refused(),
    );
    final twoSelves = BackupSnapshot(
      familyMembers: [
        FamilyMember(id: 'a', name: 'א', relation: FamilyRelation.self),
        FamilyMember(id: 'b', name: 'ב', relation: FamilyRelation.self),
      ],
      appointments: const [],
      doctorQuestions: const [],
      symptoms: const [],
      visitMedia: const [],
      medications: const [],
      doseRecords: const [],
    );
    expect(twoSelves.validate, refused());
  });

  test('refuses unreadable or foreign content, and newer versions', () {
    expect(() => BackupSnapshot.decode(utf8.encode('not json')), refused());
    expect(() => BackupSnapshot.decode(utf8.encode('{"a":1}')), refused());
    final json = jsonDecode(utf8.decode(demo().encode())) as Map;
    json['formatVersion'] = BackupSnapshot.formatVersion + 1;
    expect(
      () => BackupSnapshot.decode(utf8.encode(jsonEncode(json))),
      throwsA(
        isA<BackupFormatException>().having(
          (e) => e.reason,
          'reason',
          'unsupported version',
        ),
      ),
    );
    json['formatVersion'] = 1;
    (json['familyMembers'] as List).first['relation'] = 'cousin';
    expect(
      () => BackupSnapshot.decode(utf8.encode(jsonEncode(json))),
      refused(),
    );
  });

  group('format 2: shared children', () {
    final children = [
      for (final m in MockData.members())
        if (m.relation == FamilyRelation.child) m.id,
    ];

    test('round-trip', () {
      final snapshot = BackupSnapshot(
        familyMembers: MockData.members(),
        appointments: const [],
        doctorQuestions: const [],
        symptoms: const [],
        visitMedia: const [],
        medications: const [],
        doseRecords: const [],
        sharedMemberIds: [children.first],
      );
      final json = jsonDecode(utf8.decode(snapshot.encode())) as Map;
      expect(json['formatVersion'], 2);
      expect(BackupSnapshot.decode(snapshot.encode()).sharedMemberIds, [
        children.first,
      ]);
    });

    test('a format 1 backup still reads, with nothing shared', () {
      final json = jsonDecode(utf8.decode(demo().encode())) as Map;
      json['formatVersion'] = 1;
      json.remove('sharedMemberIds');
      final back = BackupSnapshot.decode(utf8.encode(jsonEncode(json)));
      expect(back.sharedMemberIds, isEmpty);
      expect(back.familyMembers, MockData.members());
    });

    test('only an existing child can be listed as shared', () {
      final adult = MockData.members().firstWhere(
        (m) => m.relation != FamilyRelation.child,
      );
      for (final ids in [
        [adult.id],
        ['nobody'],
        [children.first, children.first],
      ]) {
        final json = jsonDecode(utf8.decode(demo().encode())) as Map;
        json['sharedMemberIds'] = ids;
        expect(
          () => BackupSnapshot.decode(utf8.encode(jsonEncode(json))),
          refused(),
          reason: '$ids',
        );
      }
    });
  });
}
