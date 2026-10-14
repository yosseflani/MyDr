import 'package:flutter_test/flutter_test.dart';
import 'package:mydr/data/models/symptom_entry.dart';

void main() {
  SymptomEntry buildEntry({int severity = 4}) {
    return SymptomEntry(
      id: 's1',
      memberId: 'm1',
      name: 'כאב ראש',
      startedAt: DateTime(2026, 10, 10, 8),
      severity: severity,
      duration: const Duration(hours: 2),
      notes: 'אחרי העבודה',
    );
  }

  group('severity', () {
    test('accepts the full 1-10 range', () {
      expect(buildEntry(severity: 1).severity, 1);
      expect(buildEntry(severity: 10).severity, 10);
    });

    test('rejects values outside 1-10', () {
      expect(() => buildEntry(severity: 0), throwsRangeError);
      expect(() => buildEntry(severity: 11), throwsRangeError);
      expect(() => buildEntry().copyWith(severity: 11), throwsRangeError);
    });
  });

  group('status', () {
    test('is ongoing by default', () {
      final entry = buildEntry();
      expect(entry.status, SymptomStatus.ongoing);
      expect(entry.isOngoing, isTrue);
    });

    test('can be resolved while keeping or clearing the duration', () {
      final resolved = buildEntry().copyWith(status: SymptomStatus.resolved);
      expect(resolved.isOngoing, isFalse);
      expect(resolved.duration, const Duration(hours: 2));

      final unknownDuration = resolved.copyWith(duration: () => null);
      expect(unknownDuration.isOngoing, isFalse);
      expect(unknownDuration.duration, isNull);
    });
  });

  test('copyWith changes only the given fields', () {
    final entry = buildEntry();
    final updated = entry.copyWith(severity: 6, notes: () => null);
    expect(updated.severity, 6);
    expect(updated.notes, isNull);
    expect(updated.id, entry.id);
    expect(updated.name, entry.name);
    expect(updated.startedAt, entry.startedAt);
    expect(updated.duration, entry.duration);
  });

  test('uses value equality', () {
    expect(buildEntry(), buildEntry());
    expect(buildEntry().hashCode, buildEntry().hashCode);
    expect(buildEntry(), isNot(buildEntry(severity: 5)));
  });

  test('toString does not expose medical details', () {
    expect(buildEntry().toString(), 'SymptomEntry(id: s1)');
  });
}
