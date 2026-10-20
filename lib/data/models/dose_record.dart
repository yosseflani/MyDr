import 'dart:convert';

import 'package:crypto/crypto.dart';

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

  /// The id a record of the dose of [medicationId] scheduled at
  /// [scheduledAt] gets: derived from the two, so the same dose marked on
  /// two devices of a household is the same record, never a duplicate. A
  /// random-looking UUID (version 8) that reveals nothing without the
  /// medication's id.
  static String idFor(String medicationId, DateTime scheduledAt) {
    final minute =
        '${scheduledAt.year.toString().padLeft(4, '0')}-'
        '${scheduledAt.month.toString().padLeft(2, '0')}-'
        '${scheduledAt.day.toString().padLeft(2, '0')}T'
        '${scheduledAt.hour.toString().padLeft(2, '0')}:'
        '${scheduledAt.minute.toString().padLeft(2, '0')}';
    final bytes = sha256
        .convert(utf8.encode('mydr-dose-v1|$medicationId|$minute'))
        .bytes
        .sublist(0, 16);
    bytes[6] = (bytes[6] & 0x0f) | 0x80; // Version 8 (custom).
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 9562 variant.
    final hex = [for (final b in bytes) b.toRadixString(16).padLeft(2, '0')];
    return '${hex.sublist(0, 4).join()}-${hex.sublist(4, 6).join()}-'
        '${hex.sublist(6, 8).join()}-${hex.sublist(8, 10).join()}-'
        '${hex.sublist(10).join()}';
  }

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
