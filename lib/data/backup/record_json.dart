import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/models/visit_media.dart';

/// A backup's (or a synced change's) content that is not a file was not
/// readable or not valid.
class BackupFormatException implements Exception {
  const BackupFormatException(this.reason);

  /// For developers only; never contains stored values.
  final String reason;

  @override
  String toString() => 'BackupFormatException($reason)';
}

/// Every record type as JSON, with the same value formats as the local
/// database (see [StorageCodecs]), so a record reads back exactly.
///
/// Shared by the backup snapshot and household sync, so both always agree
/// on what a record looks like.
abstract final class RecordJson {
  static Map<String, Object?> member(FamilyMember m) => {
    'id': m.id,
    'name': m.name,
    'relation': m.relation.name,
    'birthDate': m.birthDate == null
        ? null
        : StorageCodecs.encodeDate(m.birthDate!),
    'allergies': m.allergies,
    'chronicConditions': m.chronicConditions,
    'notes': m.notes,
  };

  static FamilyMember readMember(RecordFields f) => FamilyMember(
    id: f.id(),
    name: f.text('name'),
    relation: FamilyRelation.values.byName(f.text('relation')),
    birthDate: f.optionalDate('birthDate'),
    allergies: f.texts('allergies'),
    chronicConditions: f.texts('chronicConditions'),
    notes: f.optionalText('notes'),
  );

  static Map<String, Object?> appointment(Appointment a) => {
    'id': a.id,
    'memberId': a.memberId,
    'doctorName': a.doctorName,
    'dateTime': StorageCodecs.encodeLocalDateTime(a.dateTime),
    'specialty': a.specialty,
    'location': a.location,
    'notes': a.notes,
  };

  static Appointment readAppointment(RecordFields f) => Appointment(
    id: f.id(),
    memberId: f.text('memberId'),
    doctorName: f.text('doctorName'),
    dateTime: f.localDateTime('dateTime'),
    specialty: f.optionalText('specialty'),
    location: f.optionalText('location'),
    notes: f.optionalText('notes'),
  );

  static Map<String, Object?> question(DoctorQuestion q) => {
    'id': q.id,
    'memberId': q.memberId,
    'appointmentId': q.appointmentId,
    'text': q.text,
    'createdAt': StorageCodecs.encodeInstant(q.createdAt),
    'isResolved': q.isResolved,
    'doctorAnswer': q.doctorAnswer,
  };

  static DoctorQuestion readQuestion(RecordFields f) => DoctorQuestion(
    id: f.id(),
    memberId: f.text('memberId'),
    appointmentId: f.optionalText('appointmentId'),
    text: f.text('text'),
    createdAt: f.instant('createdAt'),
    isResolved: f.flag('isResolved'),
    doctorAnswer: f.optionalText('doctorAnswer'),
  );

  static Map<String, Object?> symptom(SymptomEntry s) => {
    'id': s.id,
    'memberId': s.memberId,
    'name': s.name,
    'startedAt': StorageCodecs.encodeLocalDateTime(s.startedAt),
    'severity': s.severity,
    'status': s.status.name,
    'durationMicros': s.duration?.inMicroseconds,
    'notes': s.notes,
  };

  static SymptomEntry readSymptom(RecordFields f) {
    final duration = f.optionalInt('durationMicros');
    return SymptomEntry(
      id: f.id(),
      memberId: f.text('memberId'),
      name: f.text('name'),
      startedAt: f.localDateTime('startedAt'),
      severity: f.integer('severity'),
      status: SymptomStatus.values.byName(f.text('status')),
      duration: duration == null ? null : Duration(microseconds: duration),
      notes: f.optionalText('notes'),
    );
  }

  static Map<String, Object?> media(VisitMedia m) => {
    'id': m.id,
    'memberId': m.memberId,
    'appointmentId': m.appointmentId,
    'kind': m.kind.name,
    'fileName': m.fileName,
    'byteSize': m.byteSize,
    'createdAt': StorageCodecs.encodeInstant(m.createdAt),
    'description': m.description,
  };

  static VisitMedia readMedia(RecordFields f) => VisitMedia(
    id: f.id(),
    memberId: f.text('memberId'),
    appointmentId: f.text('appointmentId'),
    kind: VisitMediaKind.values.byName(f.text('kind')),
    fileName: f.text('fileName'),
    byteSize: f.integer('byteSize'),
    createdAt: f.instant('createdAt'),
    description: f.optionalText('description'),
  );

  static Map<String, Object?> medication(Medication m) => {
    'id': m.id,
    'memberId': m.memberId,
    'name': m.name,
    'dose': m.dose,
    'instructions': m.instructions,
    'reminderTimes': [for (final t in m.reminderTimes) t.format()],
    'startDate': StorageCodecs.encodeDate(m.startDate),
    'endDate': m.endDate == null ? null : StorageCodecs.encodeDate(m.endDate!),
  };

  static Medication readMedication(RecordFields f) => Medication(
    id: f.id(),
    memberId: f.text('memberId'),
    name: f.text('name'),
    dose: f.text('dose'),
    instructions: f.optionalText('instructions'),
    reminderTimes: [
      for (final t in f.texts('reminderTimes')) DoseTime.parse(t),
    ],
    startDate: f.date('startDate'),
    endDate: f.optionalDate('endDate'),
  );

  static Map<String, Object?> dose(DoseRecord r) => {
    'id': r.id,
    'memberId': r.memberId,
    'medicationId': r.medicationId,
    'scheduledAt': StorageCodecs.encodeLocalDateTime(r.scheduledAt),
    'status': r.status.name,
    'recordedAt': StorageCodecs.encodeInstant(r.recordedAt),
  };

  static DoseRecord readDose(RecordFields f) => DoseRecord(
    id: f.id(),
    memberId: f.text('memberId'),
    medicationId: f.text('medicationId'),
    scheduledAt: f.localDateTime('scheduledAt'),
    status: DoseStatus.values.byName(f.text('status')),
    recordedAt: f.instant('recordedAt'),
  );
}

/// Typed reads from one JSON record; anything unexpected throws a
/// [BackupFormatException] (or a [FormatException] for a malformed value).
class RecordFields {
  RecordFields(this._json);

  final Map<String, Object?> _json;

  String id() {
    final value = text('id');
    if (value.isEmpty) throw const BackupFormatException('empty id');
    return value;
  }

  String text(String key) => switch (_json[key]) {
    final String value => value,
    _ => throw BackupFormatException(key),
  };

  String? optionalText(String key) => switch (_json[key]) {
    null => null,
    final String value => value,
    _ => throw BackupFormatException(key),
  };

  int integer(String key) => switch (_json[key]) {
    final int value => value,
    _ => throw BackupFormatException(key),
  };

  int? optionalInt(String key) => switch (_json[key]) {
    null => null,
    final int value => value,
    _ => throw BackupFormatException(key),
  };

  bool flag(String key) => switch (_json[key]) {
    final bool value => value,
    _ => throw BackupFormatException(key),
  };

  List<String> texts(String key) => switch (_json[key]) {
    final List<Object?> values when values.every((v) => v is String) =>
      values.cast<String>(),
    _ => throw BackupFormatException(key),
  };

  DateTime date(String key) => StorageCodecs.decodeDate(text(key));

  DateTime? optionalDate(String key) {
    final value = optionalText(key);
    return value == null ? null : StorageCodecs.decodeDate(value);
  }

  DateTime localDateTime(String key) =>
      StorageCodecs.decodeLocalDateTime(text(key));

  DateTime instant(String key) => StorageCodecs.decodeInstant(integer(key));
}
