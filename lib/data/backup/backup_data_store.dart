import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/backup/backup_snapshot.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/sync/local_records.dart';

/// Reads all records for a backup, and replaces them all on restore.
abstract interface class BackupDataStore {
  Future<BackupSnapshot> export();

  /// Deletes every record on the device and saves [snapshot] instead, as
  /// one unit where the storage allows it: with the local database, a
  /// failure keeps everything exactly as it was.
  ///
  /// In a household, the device's sync history is reset in the same unit
  /// (see [RepositoryBackupDataStore.replaceAll]), so a restore never
  /// uploads the records it removed as deletions.
  Future<void> replaceAll(BackupSnapshot snapshot);
}

/// [BackupDataStore] over the app's repositories and transaction runner,
/// so it works the same with the encrypted database and in memory.
class RepositoryBackupDataStore implements BackupDataStore {
  const RepositoryBackupDataStore(
    this._deps, {
    DateTime Function() clock = DateTime.now,
  }) : _clock = clock;

  final AppDependencies _deps;
  final DateTime Function() _clock;

  @override
  Future<BackupSnapshot> export() async {
    final d = _deps;
    final (members, appointments, questions, symptoms, media) = await (
      d.familyRepository.getAll(),
      d.appointmentRepository.getAll(),
      d.doctorQuestionRepository.getAll(),
      d.symptomRepository.getAll(),
      d.visitMediaRepository.getAll(),
    ).wait;
    final (medications, doses, shared) = await (
      d.medicationRepository.getAll(),
      d.doseRecordRepository.getAll(),
      d.syncStateRepository.sharedMemberIds(),
    ).wait;
    return BackupSnapshot(
      familyMembers: members,
      appointments: appointments,
      doctorQuestions: questions,
      symptoms: symptoms,
      visitMedia: media,
      medications: medications,
      doseRecords: doses,
      sharedMemberIds: shared.toList()..sort(),
    );
  }

  /// With household sharing on, the sync history is forgotten first (in
  /// the same transaction), so none of the deletions and insertions below
  /// is noted as a change to upload: a restore never pushes mass deletions
  /// to the other parent. The membership stays; the restored children that
  /// were shared are shared again and offered in full at the next sync,
  /// which first downloads the household's history and compares it with
  /// them: identical records are matched, differing ones become conflicts
  /// for the user, never silent overwrites.
  @override
  Future<void> replaceAll(BackupSnapshot snapshot) {
    snapshot.validate();
    final d = _deps;
    return d.transactions.run(() async {
      final sync = d.syncStateRepository;
      final inHousehold = (await sync.settings()).isActive;
      await sync.resetHistory();
      // Children first, as when deleting a family member.
      for (final member in await d.familyRepository.getAll()) {
        await d.doseRecordRepository.deleteByMember(member.id);
        await d.medicationRepository.deleteByMember(member.id);
        await d.symptomRepository.deleteByMember(member.id);
        await d.doctorQuestionRepository.deleteByMember(member.id);
        await d.visitMediaRepository.deleteByMember(member.id);
        await d.appointmentRepository.deleteByMember(member.id);
        await d.familyRepository.delete(member.id);
      }
      // Parents first.
      for (final m in snapshot.familyMembers) {
        await d.familyRepository.add(m);
      }
      for (final a in snapshot.appointments) {
        await d.appointmentRepository.add(a);
      }
      for (final q in snapshot.doctorQuestions) {
        await d.doctorQuestionRepository.add(q);
      }
      for (final s in snapshot.symptoms) {
        await d.symptomRepository.add(s);
      }
      for (final m in snapshot.visitMedia) {
        await d.visitMediaRepository.add(m);
      }
      for (final m in snapshot.medications) {
        await d.medicationRepository.add(m);
      }
      for (final r in snapshot.doseRecords) {
        await d.doseRecordRepository.save(r);
      }
      if (inHousehold) {
        final children = {
          for (final m in snapshot.familyMembers)
            if (m.relation == FamilyRelation.child) m.id,
        };
        for (final id in snapshot.sharedMemberIds) {
          if (!children.contains(id)) continue;
          await sync.setShared(id, shared: true, at: _clock());
          await LocalRecords(d).markAllPending(id);
        }
      }
    });
  }
}
