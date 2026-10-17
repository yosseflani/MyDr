import 'package:mydr/data/models/dose_record.dart';

/// Records of scheduled doses taken or skipped.
///
/// A scheduled dose (a medication and its date and time) has at most one
/// record, so there is no plain `add`: [save] adds a record or replaces the
/// existing one.
abstract interface class DoseRecordRepository {
  /// Returns a new unique id to use when saving a record.
  String createId();

  /// Records ordered by scheduled time, newest first, optionally filtered
  /// by family member and/or medication.
  Future<List<DoseRecord>> getAll({String? memberId, String? medicationId});

  /// Saves the record of a scheduled dose. If that dose (same medication
  /// and [DoseRecord.scheduledAt]) already has a record, its status and
  /// time of recording are replaced and its id is kept. Returns the record
  /// as stored.
  Future<DoseRecord> save(DoseRecord record);

  /// Removes the record of one scheduled dose, if there is one.
  Future<void> deleteOccurrence(String medicationId, DateTime scheduledAt);

  /// Deletes all records of a medication. Part of deleting it, which
  /// requires explicit user confirmation.
  Future<void> deleteByMedication(String medicationId);

  /// Deletes all records of a family member. Part of deleting the member,
  /// which requires explicit user confirmation.
  Future<void> deleteByMember(String memberId);
}
