import 'dart:convert';

import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/models/visit_media.dart';

/// A backup's content that is not a file was not readable or not valid.
class BackupFormatException implements Exception {
  const BackupFormatException(this.reason);

  /// For developers only; never contains stored values.
  final String reason;

  @override
  String toString() => 'BackupFormatException($reason)';
}

/// How many records of each kind a snapshot holds. Shown before a restore.
class BackupCounts {
  const BackupCounts({
    required this.familyMembers,
    required this.appointments,
    required this.doctorQuestions,
    required this.symptoms,
    required this.visitMedia,
    required this.medications,
    required this.doseRecords,
  });

  final int familyMembers;
  final int appointments;
  final int doctorQuestions;
  final int symptoms;
  final int visitMedia;
  final int medications;
  final int doseRecords;

  bool get isEmpty =>
      familyMembers +
          appointments +
          doctorQuestions +
          symptoms +
          visitMedia +
          medications +
          doseRecords ==
      0;

  Map<String, int> toJson() => {
    'familyMembers': familyMembers,
    'appointments': appointments,
    'doctorQuestions': doctorQuestions,
    'symptoms': symptoms,
    'visitMedia': visitMedia,
    'medications': medications,
    'doseRecords': doseRecords,
  };

  static BackupCounts fromJson(Map<String, Object?> json) {
    int count(String key) => switch (json[key]) {
      final int value when value >= 0 => value,
      _ => throw BackupFormatException('count $key'),
    };
    return BackupCounts(
      familyMembers: count('familyMembers'),
      appointments: count('appointments'),
      doctorQuestions: count('doctorQuestions'),
      symptoms: count('symptoms'),
      visitMedia: count('visitMedia'),
      medications: count('medications'),
      doseRecords: count('doseRecords'),
    );
  }
}

/// Every record in the app at one moment, as backed up.
///
/// Serialized as versioned JSON with the same value formats as the local
/// database (see [StorageCodecs]), so a backup reads back exactly. The
/// photo and video files themselves are separate backup objects.
class BackupSnapshot {
  BackupSnapshot({
    required List<FamilyMember> familyMembers,
    required List<Appointment> appointments,
    required List<DoctorQuestion> doctorQuestions,
    required List<SymptomEntry> symptoms,
    required List<VisitMedia> visitMedia,
    required List<Medication> medications,
    required List<DoseRecord> doseRecords,
  }) : familyMembers = List.unmodifiable(familyMembers),
       appointments = List.unmodifiable(appointments),
       doctorQuestions = List.unmodifiable(doctorQuestions),
       symptoms = List.unmodifiable(symptoms),
       visitMedia = List.unmodifiable(visitMedia),
       medications = List.unmodifiable(medications),
       doseRecords = List.unmodifiable(doseRecords);

  /// Version of this JSON format. A newer one is refused.
  static const int formatVersion = 1;

  final List<FamilyMember> familyMembers;
  final List<Appointment> appointments;
  final List<DoctorQuestion> doctorQuestions;
  final List<SymptomEntry> symptoms;
  final List<VisitMedia> visitMedia;
  final List<Medication> medications;
  final List<DoseRecord> doseRecords;

  BackupCounts get counts => BackupCounts(
    familyMembers: familyMembers.length,
    appointments: appointments.length,
    doctorQuestions: doctorQuestions.length,
    symptoms: symptoms.length,
    visitMedia: visitMedia.length,
    medications: medications.length,
    doseRecords: doseRecords.length,
  );

  /// The same records with each media file name replaced as in [names]
  /// (restored files get new names on this device).
  BackupSnapshot withMediaFileNames(Map<String, String> names) =>
      BackupSnapshot(
        familyMembers: familyMembers,
        appointments: appointments,
        doctorQuestions: doctorQuestions,
        symptoms: symptoms,
        visitMedia: [
          for (final m in visitMedia)
            VisitMedia(
              id: m.id,
              memberId: m.memberId,
              appointmentId: m.appointmentId,
              kind: m.kind,
              fileName: names[m.fileName] ?? m.fileName,
              byteSize: m.byteSize,
              createdAt: m.createdAt,
              description: m.description,
            ),
        ],
        medications: medications,
        doseRecords: doseRecords,
      );

  /// Checks what the database would refuse, before anything is changed:
  /// unique ids, one "self" profile, and every record pointing at an
  /// existing record of the same family member.
  void validate() {
    void unique(Iterable<String> ids, String what) {
      final list = ids.toList();
      if (list.toSet().length != list.length) {
        throw BackupFormatException('duplicate $what id');
      }
    }

    unique(familyMembers.map((m) => m.id), 'member');
    unique(appointments.map((a) => a.id), 'appointment');
    unique(doctorQuestions.map((q) => q.id), 'question');
    unique(symptoms.map((s) => s.id), 'symptom');
    unique(visitMedia.map((m) => m.id), 'media');
    unique(visitMedia.map((m) => m.fileName), 'media file');
    unique(medications.map((m) => m.id), 'medication');
    unique(doseRecords.map((r) => r.id), 'dose record');
    unique(
      doseRecords.map((r) => '${r.medicationId}\u0000${r.scheduledAt}'),
      'scheduled dose',
    );

    if (familyMembers.where((m) => m.relation == FamilyRelation.self).length >
        1) {
      throw const BackupFormatException('two self profiles');
    }
    final members = {for (final m in familyMembers) m.id};
    final appointmentMembers = {for (final a in appointments) a.id: a.memberId};
    final medicationMembers = {for (final m in medications) m.id: m.memberId};

    void member(String id) {
      if (!members.contains(id)) {
        throw const BackupFormatException('missing member');
      }
    }

    for (final owner in [
      for (final a in appointments) a.memberId,
      for (final s in symptoms) s.memberId,
      for (final m in medications) m.memberId,
    ]) {
      member(owner);
    }
    for (final q in doctorQuestions) {
      member(q.memberId);
      final appointmentId = q.appointmentId;
      if (appointmentId != null &&
          appointmentMembers[appointmentId] != q.memberId) {
        throw const BackupFormatException('question appointment');
      }
    }
    for (final m in visitMedia) {
      if (appointmentMembers[m.appointmentId] != m.memberId) {
        throw const BackupFormatException('media appointment');
      }
    }
    for (final r in doseRecords) {
      if (medicationMembers[r.medicationId] != r.memberId) {
        throw const BackupFormatException('dose record medication');
      }
    }
    for (final m in medications) {
      final end = m.endDate;
      if (m.reminderTimes.isEmpty ||
          (end != null && end.isBefore(m.startDate))) {
        throw const BackupFormatException('medication');
      }
    }
  }

  List<int> encode() => utf8.encode(
    jsonEncode({
      'format': 'mydr-backup',
      'formatVersion': formatVersion,
      'familyMembers': [for (final m in familyMembers) _member(m)],
      'appointments': [for (final a in appointments) _appointment(a)],
      'doctorQuestions': [for (final q in doctorQuestions) _question(q)],
      'symptoms': [for (final s in symptoms) _symptom(s)],
      'visitMedia': [for (final m in visitMedia) _media(m)],
      'medications': [for (final m in medications) _medication(m)],
      'doseRecords': [for (final r in doseRecords) _dose(r)],
    }),
  );

  /// Reads [bytes] back and [validate]s them. Throws a
  /// [BackupFormatException] for anything unreadable or invalid.
  static BackupSnapshot decode(List<int> bytes) {
    try {
      final json = jsonDecode(utf8.decode(bytes));
      if (json is! Map<String, Object?> || json['format'] != 'mydr-backup') {
        throw const BackupFormatException('not a backup');
      }
      final version = json['formatVersion'];
      if (version is! int || version < 1 || version > formatVersion) {
        throw const BackupFormatException('unsupported version');
      }
      List<T> list<T>(String key, T Function(_Fields) read) {
        final items = json[key];
        if (items is! List) throw BackupFormatException(key);
        return [
          for (final item in items)
            if (item is Map<String, Object?>)
              read(_Fields(item))
            else
              throw BackupFormatException(key),
        ];
      }

      final snapshot = BackupSnapshot(
        familyMembers: list('familyMembers', _readMember),
        appointments: list('appointments', _readAppointment),
        doctorQuestions: list('doctorQuestions', _readQuestion),
        symptoms: list('symptoms', _readSymptom),
        visitMedia: list('visitMedia', _readMedia),
        medications: list('medications', _readMedication),
        doseRecords: list('doseRecords', _readDose),
      )..validate();
      return snapshot;
    } on BackupFormatException {
      rethrow;
    } catch (_) {
      // FormatException, TypeError, RangeError, ArgumentError…
      throw const BackupFormatException('unreadable');
    }
  }

  static Map<String, Object?> _member(FamilyMember m) => {
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

  static FamilyMember _readMember(_Fields f) => FamilyMember(
    id: f.id(),
    name: f.text('name'),
    relation: FamilyRelation.values.byName(f.text('relation')),
    birthDate: f.optionalDate('birthDate'),
    allergies: f.texts('allergies'),
    chronicConditions: f.texts('chronicConditions'),
    notes: f.optionalText('notes'),
  );

  static Map<String, Object?> _appointment(Appointment a) => {
    'id': a.id,
    'memberId': a.memberId,
    'doctorName': a.doctorName,
    'dateTime': StorageCodecs.encodeLocalDateTime(a.dateTime),
    'specialty': a.specialty,
    'location': a.location,
    'notes': a.notes,
  };

  static Appointment _readAppointment(_Fields f) => Appointment(
    id: f.id(),
    memberId: f.text('memberId'),
    doctorName: f.text('doctorName'),
    dateTime: f.localDateTime('dateTime'),
    specialty: f.optionalText('specialty'),
    location: f.optionalText('location'),
    notes: f.optionalText('notes'),
  );

  static Map<String, Object?> _question(DoctorQuestion q) => {
    'id': q.id,
    'memberId': q.memberId,
    'appointmentId': q.appointmentId,
    'text': q.text,
    'createdAt': StorageCodecs.encodeInstant(q.createdAt),
    'isResolved': q.isResolved,
    'doctorAnswer': q.doctorAnswer,
  };

  static DoctorQuestion _readQuestion(_Fields f) => DoctorQuestion(
    id: f.id(),
    memberId: f.text('memberId'),
    appointmentId: f.optionalText('appointmentId'),
    text: f.text('text'),
    createdAt: f.instant('createdAt'),
    isResolved: f.flag('isResolved'),
    doctorAnswer: f.optionalText('doctorAnswer'),
  );

  static Map<String, Object?> _symptom(SymptomEntry s) => {
    'id': s.id,
    'memberId': s.memberId,
    'name': s.name,
    'startedAt': StorageCodecs.encodeLocalDateTime(s.startedAt),
    'severity': s.severity,
    'status': s.status.name,
    'durationMicros': s.duration?.inMicroseconds,
    'notes': s.notes,
  };

  static SymptomEntry _readSymptom(_Fields f) {
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

  static Map<String, Object?> _media(VisitMedia m) => {
    'id': m.id,
    'memberId': m.memberId,
    'appointmentId': m.appointmentId,
    'kind': m.kind.name,
    'fileName': m.fileName,
    'byteSize': m.byteSize,
    'createdAt': StorageCodecs.encodeInstant(m.createdAt),
    'description': m.description,
  };

  static VisitMedia _readMedia(_Fields f) => VisitMedia(
    id: f.id(),
    memberId: f.text('memberId'),
    appointmentId: f.text('appointmentId'),
    kind: VisitMediaKind.values.byName(f.text('kind')),
    fileName: f.text('fileName'),
    byteSize: f.integer('byteSize'),
    createdAt: f.instant('createdAt'),
    description: f.optionalText('description'),
  );

  static Map<String, Object?> _medication(Medication m) => {
    'id': m.id,
    'memberId': m.memberId,
    'name': m.name,
    'dose': m.dose,
    'instructions': m.instructions,
    'reminderTimes': [for (final t in m.reminderTimes) t.format()],
    'startDate': StorageCodecs.encodeDate(m.startDate),
    'endDate': m.endDate == null ? null : StorageCodecs.encodeDate(m.endDate!),
  };

  static Medication _readMedication(_Fields f) => Medication(
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

  static Map<String, Object?> _dose(DoseRecord r) => {
    'id': r.id,
    'memberId': r.memberId,
    'medicationId': r.medicationId,
    'scheduledAt': StorageCodecs.encodeLocalDateTime(r.scheduledAt),
    'status': r.status.name,
    'recordedAt': StorageCodecs.encodeInstant(r.recordedAt),
  };

  static DoseRecord _readDose(_Fields f) => DoseRecord(
    id: f.id(),
    memberId: f.text('memberId'),
    medicationId: f.text('medicationId'),
    scheduledAt: f.localDateTime('scheduledAt'),
    status: DoseStatus.values.byName(f.text('status')),
    recordedAt: f.instant('recordedAt'),
  );
}

/// Typed reads from one JSON record; anything unexpected throws.
class _Fields {
  _Fields(this._json);

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
