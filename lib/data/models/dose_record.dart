/// What the user recorded for a scheduled dose.
enum DoseStatus { taken, skipped }

/// The user's record of one scheduled dose of a [Medication].
///
/// A scheduled dose (a medication at a date and time) has at most one
/// record; recording it again replaces the status instead of adding a
/// second record.
class DoseRecord {
  DoseRecord({
    required this.id,
    required this.memberId,
    required this.medicationId,
    required DateTime scheduledAt,
    required this.status,
    required this.recordedAt,
  }) : scheduledAt = DateTime(
         scheduledAt.year,
         scheduledAt.month,
         scheduledAt.day,
         scheduledAt.hour,
         scheduledAt.minute,
       );

  final String id;

  /// Id of the [FamilyMember]; always the member of [medicationId].
  final String memberId;
  final String medicationId;

  /// The scheduled dose this records: its date and reminder time, in local
  /// wall-clock time, to the minute.
  final DateTime scheduledAt;
  final DoseStatus status;

  /// When the user recorded it.
  final DateTime recordedAt;

  DoseRecord copyWith({DoseStatus? status, DateTime? recordedAt}) {
    return DoseRecord(
      id: id,
      memberId: memberId,
      medicationId: medicationId,
      scheduledAt: scheduledAt,
      status: status ?? this.status,
      recordedAt: recordedAt ?? this.recordedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is DoseRecord &&
      other.id == id &&
      other.memberId == memberId &&
      other.medicationId == medicationId &&
      other.scheduledAt == scheduledAt &&
      other.status == status &&
      other.recordedAt == recordedAt;

  @override
  int get hashCode =>
      Object.hash(id, memberId, medicationId, scheduledAt, status, recordedAt);

  /// Shows only the id so medical details never end up in logs.
  @override
  String toString() => 'DoseRecord(id: $id)';
}
