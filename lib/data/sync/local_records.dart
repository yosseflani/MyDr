import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/backup/record_json.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/media/media_file_validator.dart';
import 'package:mydr/data/media/visit_media_file_store.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/sync_state.dart';
import 'package:mydr/data/models/visit_media.dart';

/// What happened when a change from another device was written.
enum LocalWrite {
  written,

  /// Its parent record is not on this device (yet); kept for later.
  parked,
}

/// The app's records as sync payloads: read and written only through the
/// existing repositories, so every rule they enforce (member isolation,
/// one record per scheduled dose, file checks) applies to synced changes
/// exactly as to the user's own.
///
/// Payloads are the [RecordJson] of a record, except that a photo or
/// video carries its file's extension instead of its local file name (and,
/// once uploaded, a `blob` describing the encrypted file).
class LocalRecords {
  const LocalRecords(this._deps);

  final AppDependencies _deps;

  /// Fields that differ between devices without being a change: local file
  /// names, the uploaded object, and a dose record's local id.
  static const Map<SyncKind, Set<String>> ignoredFields = {
    SyncKind.media: {'blob'},
    SyncKind.dose: {'id'},
  };

  /// The id of a record in the household (see [SyncIds]).
  static String syncIdOfDose(DoseRecord r) => SyncIds.dose(
    r.medicationId,
    StorageCodecs.encodeLocalDateTime(r.scheduledAt),
  );

  static (String, DateTime)? _doseOccurrence(String syncId) {
    final at = syncId.lastIndexOf('@');
    if (at <= 0) return null;
    try {
      return (
        syncId.substring(0, at),
        StorageCodecs.decodeLocalDateTime(syncId.substring(at + 1)),
      );
    } on FormatException {
      return null;
    }
  }

  /// The current payload of a record, or null if it is not on this device.
  Future<Map<String, Object?>?> read(SyncKind kind, String syncId) async {
    final d = _deps;
    switch (kind) {
      case SyncKind.share:
        return null;
      case SyncKind.member:
        final m = await d.familyRepository.getById(syncId);
        return m == null ? null : RecordJson.member(m);
      case SyncKind.appointment:
        final a = await d.appointmentRepository.getById(syncId);
        return a == null ? null : RecordJson.appointment(a);
      case SyncKind.question:
        final q = await d.doctorQuestionRepository.getById(syncId);
        return q == null ? null : RecordJson.question(q);
      case SyncKind.symptom:
        final s = await d.symptomRepository.getById(syncId);
        return s == null ? null : RecordJson.symptom(s);
      case SyncKind.medication:
        final m = await d.medicationRepository.getById(syncId);
        return m == null ? null : RecordJson.medication(m);
      case SyncKind.media:
        final m = await d.visitMediaRepository.getById(syncId);
        return m == null ? null : mediaPayload(m);
      case SyncKind.dose:
        final r = await _dose(syncId);
        return r == null ? null : RecordJson.dose(r);
    }
  }

  /// A photo or video's payload: its record without the local file name.
  static Map<String, Object?> mediaPayload(VisitMedia m) => {
    ...RecordJson.media(m)..remove('fileName'),
    'extension': MediaFileValidator.extensionOf(m.fileName),
  };

  /// The local id of a record (differs from [syncId] only for a dose).
  Future<String?> localIdOf(SyncKind kind, String syncId) async {
    if (kind != SyncKind.dose) return syncId;
    return (await _dose(syncId))?.id;
  }

  Future<DoseRecord?> _dose(String syncId) async {
    final occurrence = _doseOccurrence(syncId);
    if (occurrence == null) return null;
    final (medicationId, at) = occurrence;
    for (final r in await _deps.doseRecordRepository.getAll(
      medicationId: medicationId,
    )) {
      if (r.scheduledAt == at) return r;
    }
    return null;
  }

  /// The family member a payload belongs to.
  static String memberOf(SyncKind kind, Map<String, Object?> payload) =>
      kind == SyncKind.member
      ? payload['id'] as String
      : payload['memberId'] as String;

  /// Checks that [payload] is a valid record of [kind] with the household
  /// id [syncId] and of [memberId]: anything else is refused, whoever sent
  /// it. Only a child profile is ever accepted.
  static bool isValid(
    SyncKind kind,
    String syncId,
    String memberId,
    Map<String, Object?> payload,
  ) {
    try {
      final f = RecordFields(payload);
      switch (kind) {
        case SyncKind.share:
          return payload['memberId'] == syncId && payload['shared'] is bool;
        case SyncKind.member:
          final m = RecordJson.readMember(f);
          return m.id == syncId &&
              m.id == memberId &&
              m.relation == FamilyRelation.child;
        case SyncKind.appointment:
          final a = RecordJson.readAppointment(f);
          return a.id == syncId && a.memberId == memberId;
        case SyncKind.question:
          final q = RecordJson.readQuestion(f);
          return q.id == syncId && q.memberId == memberId;
        case SyncKind.symptom:
          final s = RecordJson.readSymptom(f);
          return s.id == syncId &&
              s.memberId == memberId &&
              s.severity >= 1 &&
              s.severity <= 5;
        case SyncKind.medication:
          final m = RecordJson.readMedication(f);
          final end = m.endDate;
          return m.id == syncId &&
              m.memberId == memberId &&
              m.reminderTimes.isNotEmpty &&
              (end == null || !end.isBefore(m.startDate));
        case SyncKind.media:
          final m = RecordJson.readMedia(
            RecordFields({...payload, 'fileName': 'x'}),
          );
          final extension = f.text('extension');
          return m.id == syncId &&
              m.memberId == memberId &&
              (MediaFileValidator.photoExtensions.contains(extension) ||
                  MediaFileValidator.videoExtensions.contains(extension));
        case SyncKind.dose:
          final r = RecordJson.readDose(f);
          return syncIdOfDose(r) == syncId && r.memberId == memberId;
      }
    } catch (_) {
      return false;
    }
  }

  /// Writes a change from another device: adds the record or replaces it.
  /// [mediaFile] is the imported file of a new photo or video. Returns
  /// [LocalWrite.parked] (and writes nothing) when a record it belongs to
  /// is not on this device, so foreign keys always hold.
  Future<LocalWrite> write(
    SyncKind kind,
    Map<String, Object?> payload, {
    StoredMediaFile? mediaFile,
  }) async {
    final d = _deps;
    final f = RecordFields(payload);
    Future<bool> memberExists(String id) async =>
        await d.familyRepository.getById(id) != null;

    switch (kind) {
      case SyncKind.share:
        return LocalWrite.written;
      case SyncKind.member:
        final m = RecordJson.readMember(f);
        if (await d.familyRepository.getById(m.id) == null) {
          await d.familyRepository.add(m);
        } else {
          await d.familyRepository.update(m);
        }
      case SyncKind.appointment:
        final a = RecordJson.readAppointment(f);
        if (!await memberExists(a.memberId)) return LocalWrite.parked;
        final stored = await d.appointmentRepository.getById(a.id);
        if (stored == null) {
          await d.appointmentRepository.add(a);
        } else {
          // Moving a shared appointment is blocked on every device; one
          // that arrives moved anyway waits rather than break the links
          // of its questions or photos.
          if (stored.memberId != a.memberId) return LocalWrite.parked;
          await d.appointmentRepository.update(a);
        }
      case SyncKind.question:
        final q = RecordJson.readQuestion(f);
        if (!await memberExists(q.memberId)) return LocalWrite.parked;
        final appointmentId = q.appointmentId;
        if (appointmentId != null) {
          final a = await d.appointmentRepository.getById(appointmentId);
          if (a == null || a.memberId != q.memberId) return LocalWrite.parked;
        }
        if (await d.doctorQuestionRepository.getById(q.id) == null) {
          await d.doctorQuestionRepository.add(q);
        } else {
          await d.doctorQuestionRepository.update(q);
        }
      case SyncKind.symptom:
        final s = RecordJson.readSymptom(f);
        if (!await memberExists(s.memberId)) return LocalWrite.parked;
        if (await d.symptomRepository.getById(s.id) == null) {
          await d.symptomRepository.add(s);
        } else {
          await d.symptomRepository.update(s);
        }
      case SyncKind.medication:
        final m = RecordJson.readMedication(f);
        if (!await memberExists(m.memberId)) return LocalWrite.parked;
        final stored = await d.medicationRepository.getById(m.id);
        if (stored == null) {
          await d.medicationRepository.add(m);
        } else {
          if (stored.memberId != m.memberId) return LocalWrite.parked;
          await d.medicationRepository.update(m);
        }
      case SyncKind.media:
        final description = f.optionalText('description');
        final id = f.id();
        final stored = await d.visitMediaRepository.getById(id);
        if (stored != null) {
          await d.visitMediaRepository.update(
            stored.copyWith(description: () => description),
          );
          return LocalWrite.written;
        }
        final memberId = f.text('memberId');
        final appointment = await d.appointmentRepository.getById(
          f.text('appointmentId'),
        );
        if (appointment == null ||
            appointment.memberId != memberId ||
            mediaFile == null) {
          return LocalWrite.parked;
        }
        final kindName = f.text('kind');
        if (mediaFile.kind.name != kindName) {
          throw const BackupFormatException('media kind');
        }
        await d.visitMediaRepository.add(
          VisitMedia(
            id: id,
            memberId: memberId,
            appointmentId: appointment.id,
            kind: mediaFile.kind,
            fileName: mediaFile.fileName,
            byteSize: mediaFile.byteSize,
            createdAt: f.instant('createdAt'),
            description: description,
          ),
        );
      case SyncKind.dose:
        final r = RecordJson.readDose(f);
        final medication = await d.medicationRepository.getById(r.medicationId);
        if (medication == null || medication.memberId != r.memberId) {
          return LocalWrite.parked;
        }
        final existing = await _dose(syncIdOfDose(r));
        await d.doseRecordRepository.save(
          DoseRecord(
            id: existing?.id ?? r.id,
            memberId: r.memberId,
            medicationId: r.medicationId,
            scheduledAt: r.scheduledAt,
            status: r.status,
            recordedAt: r.recordedAt,
          ),
        );
    }
    return LocalWrite.written;
  }

  /// Notes every record of [memberId] (and the profile and its sharing) as
  /// changed, so the next sync uploads them: used when a child is shared,
  /// and after a restore.
  Future<void> markAllPending(String memberId) async {
    final d = _deps;
    final state = d.syncStateRepository;
    await state.markPending(SyncKind.share, memberId, memberId);
    await state.markPending(SyncKind.member, memberId, memberId);
    for (final a in await d.appointmentRepository.getAll(memberId: memberId)) {
      await state.markPending(SyncKind.appointment, a.id, a.id);
    }
    for (final m in await d.medicationRepository.getAll(memberId: memberId)) {
      await state.markPending(SyncKind.medication, m.id, m.id);
    }
    for (final q in await d.doctorQuestionRepository.getAll(
      memberId: memberId,
    )) {
      await state.markPending(SyncKind.question, q.id, q.id);
    }
    for (final s in await d.symptomRepository.getAll(memberId: memberId)) {
      await state.markPending(SyncKind.symptom, s.id, s.id);
    }
    for (final m in await d.visitMediaRepository.getAll(memberId: memberId)) {
      await state.markPending(SyncKind.media, m.id, m.id);
    }
    for (final r in await d.doseRecordRepository.getAll(memberId: memberId)) {
      await state.markPending(SyncKind.dose, syncIdOfDose(r), r.id);
    }
  }
}
