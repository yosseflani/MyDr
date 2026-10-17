import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/repositories/dose_record_repository.dart';

/// Records kept in memory only, lost when the app closes.
class InMemoryDoseRecordRepository implements DoseRecordRepository {
  InMemoryDoseRecordRepository([
    Iterable<DoseRecord> initialRecords = const [],
  ]) {
    for (final record in initialRecords) {
      _records[_key(record.medicationId, record.scheduledAt)] = record;
    }
  }

  /// Keyed by scheduled dose, so each one has at most one record.
  final Map<String, DoseRecord> _records = {};
  int _nextId = 1;

  static String _key(String medicationId, DateTime scheduledAt) =>
      '$medicationId\u0000${scheduledAt.toIso8601String()}';

  @override
  String createId() {
    String id;
    do {
      id = 'dose-${_nextId++}';
    } while (_records.values.any((r) => r.id == id));
    return id;
  }

  @override
  Future<List<DoseRecord>> getAll({
    String? memberId,
    String? medicationId,
  }) async {
    final records =
        _records.values
            .where((r) => memberId == null || r.memberId == memberId)
            .where(
              (r) => medicationId == null || r.medicationId == medicationId,
            )
            .toList()
          ..sort((a, b) {
            final byTime = b.scheduledAt.compareTo(a.scheduledAt);
            return byTime != 0 ? byTime : a.id.compareTo(b.id);
          });
    return List.unmodifiable(records);
  }

  @override
  Future<DoseRecord> save(DoseRecord record) async {
    final key = _key(record.medicationId, record.scheduledAt);
    final existing = _records[key];
    if (existing == null) {
      if (_records.values.any((r) => r.id == record.id)) {
        throw StateError('Item with id "${record.id}" already exists');
      }
      return _records[key] = record;
    }
    return _records[key] = existing.copyWith(
      status: record.status,
      recordedAt: record.recordedAt,
    );
  }

  @override
  Future<void> deleteOccurrence(
    String medicationId,
    DateTime scheduledAt,
  ) async {
    _records.remove(_key(medicationId, _toMinute(scheduledAt)));
  }

  @override
  Future<void> deleteByMedication(String medicationId) async {
    _records.removeWhere((_, r) => r.medicationId == medicationId);
  }

  @override
  Future<void> deleteByMember(String memberId) async {
    _records.removeWhere((_, r) => r.memberId == memberId);
  }

  static DateTime _toMinute(DateTime value) =>
      DateTime(value.year, value.month, value.day, value.hour, value.minute);
}
