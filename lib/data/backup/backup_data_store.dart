import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/backup/backup_snapshot.dart';

/// Reads all records for a backup, and replaces them all on restore.
abstract interface class BackupDataStore {
  Future<BackupSnapshot> export();

  /// Deletes every record on the device and saves [snapshot] instead, as
  /// one unit where the storage allows it: with the local database, a
  /// failure keeps everything exactly as it was.
  Future<void> replaceAll(BackupSnapshot snapshot);
}

/// [BackupDataStore] over the app's repositories and transaction runner,
/// so it works the same with the encrypted database and in memory.
class RepositoryBackupDataStore implements BackupDataStore {
  const RepositoryBackupDataStore(this._deps);

  final AppDependencies _deps;

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
    final (medications, doses) = await (
      d.medicationRepository.getAll(),
      d.doseRecordRepository.getAll(),
    ).wait;
    return BackupSnapshot(
      familyMembers: members,
      appointments: appointments,
      doctorQuestions: questions,
      symptoms: symptoms,
      visitMedia: media,
      medications: medications,
      doseRecords: doses,
    );
  }

  @override
  Future<void> replaceAll(BackupSnapshot snapshot) {
    snapshot.validate();
    final d = _deps;
    return d.transactions.run(() async {
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
    });
  }
}
