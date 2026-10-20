import 'dart:convert';

import 'package:mydr/data/backup/record_json.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/models/visit_media.dart';

export 'package:mydr/data/backup/record_json.dart' show BackupFormatException;

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
///
/// Format 2 adds [sharedMemberIds], the children shared with a household.
/// Sync bookkeeping (versions, tombstones, pending changes, conflicts, read
/// positions) is deliberately not backed up: it belongs to one device's
/// place in the household's history, and restoring an old copy of it could
/// replay stale changes or push mass deletions. Format 1 is still read.
class BackupSnapshot {
  BackupSnapshot({
    required List<FamilyMember> familyMembers,
    required List<Appointment> appointments,
    required List<DoctorQuestion> doctorQuestions,
    required List<SymptomEntry> symptoms,
    required List<VisitMedia> visitMedia,
    required List<Medication> medications,
    required List<DoseRecord> doseRecords,
    List<String> sharedMemberIds = const [],
  }) : familyMembers = List.unmodifiable(familyMembers),
       appointments = List.unmodifiable(appointments),
       doctorQuestions = List.unmodifiable(doctorQuestions),
       symptoms = List.unmodifiable(symptoms),
       visitMedia = List.unmodifiable(visitMedia),
       medications = List.unmodifiable(medications),
       doseRecords = List.unmodifiable(doseRecords),
       sharedMemberIds = List.unmodifiable(sharedMemberIds);

  /// Version of this JSON format. A newer one is refused.
  static const int formatVersion = 2;

  final List<FamilyMember> familyMembers;
  final List<Appointment> appointments;
  final List<DoctorQuestion> doctorQuestions;
  final List<SymptomEntry> symptoms;
  final List<VisitMedia> visitMedia;
  final List<Medication> medications;
  final List<DoseRecord> doseRecords;

  /// Children that were shared with a household when the backup was made
  /// (empty in format 1). Restored only on a device that is in a household.
  final List<String> sharedMemberIds;

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
        sharedMemberIds: sharedMemberIds,
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
    unique(sharedMemberIds, 'shared member');
    final children = {
      for (final m in familyMembers)
        if (m.relation == FamilyRelation.child) m.id,
    };
    // As in the database: only an existing child profile can be shared.
    if (!sharedMemberIds.every(children.contains)) {
      throw const BackupFormatException('shared member');
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
      'familyMembers': [for (final m in familyMembers) RecordJson.member(m)],
      'appointments': [for (final a in appointments) RecordJson.appointment(a)],
      'doctorQuestions': [for (final q in doctorQuestions) RecordJson.question(q)],
      'symptoms': [for (final s in symptoms) RecordJson.symptom(s)],
      'visitMedia': [for (final m in visitMedia) RecordJson.media(m)],
      'medications': [for (final m in medications) RecordJson.medication(m)],
      'doseRecords': [for (final r in doseRecords) RecordJson.dose(r)],
      'sharedMemberIds': sharedMemberIds,
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
      List<T> list<T>(String key, T Function(RecordFields) read) {
        final items = json[key];
        if (items is! List) throw BackupFormatException(key);
        return [
          for (final item in items)
            if (item is Map<String, Object?>)
              read(RecordFields(item))
            else
              throw BackupFormatException(key),
        ];
      }

      final snapshot = BackupSnapshot(
        familyMembers: list('familyMembers', RecordJson.readMember),
        appointments: list('appointments', RecordJson.readAppointment),
        doctorQuestions: list('doctorQuestions', RecordJson.readQuestion),
        symptoms: list('symptoms', RecordJson.readSymptom),
        visitMedia: list('visitMedia', RecordJson.readMedia),
        medications: list('medications', RecordJson.readMedication),
        doseRecords: list('doseRecords', RecordJson.readDose),
        sharedMemberIds: version < 2
            ? const []
            : RecordFields(json).texts('sharedMemberIds'),
      )..validate();
      return snapshot;
    } on BackupFormatException {
      rethrow;
    } catch (_) {
      // FormatException, TypeError, RangeError, ArgumentError…
      throw const BackupFormatException('unreadable');
    }
  }
}
