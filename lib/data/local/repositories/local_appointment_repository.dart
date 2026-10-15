import 'package:drift/drift.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/repositories/appointment_repository.dart';

class LocalAppointmentRepository extends LocalRepository
    implements AppointmentRepository {
  LocalAppointmentRepository(super.db);

  @override
  Future<List<Appointment>> getAll({String? memberId}) => guard(() async {
    final query = db.select(db.appointments)
      ..orderBy([
        // Stored times sort as text in time order.
        (t) => OrderingTerm.asc(t.scheduledAt),
        (t) => OrderingTerm.asc(t.id),
      ]);
    if (memberId != null) query.where((t) => t.memberId.equals(memberId));
    return List.unmodifiable((await query.get()).map(_toModel));
  });

  @override
  Future<Appointment?> getById(String id) => guard(() async {
    final row = await (db.select(
      db.appointments,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  });

  /// Refused (a [LocalDataException]) if the family member does not exist.
  @override
  Future<void> add(Appointment item) =>
      insertNew(db.appointments, item.id, _toRow(item));

  /// Moving an appointment to another family member is refused while
  /// questions are linked to it: unlink them first.
  @override
  Future<void> update(Appointment item) => guard(() async {
    final rows = await (db.update(
      db.appointments,
    )..where((t) => t.id.equals(item.id))).write(_toRow(item));
    expectUpdated(rows, item.id);
  });

  /// Refused while questions are linked to it: unlink them first.
  @override
  Future<void> delete(String id) => guard(() async {
    await (db.delete(db.appointments)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<void> deleteByMember(String memberId) => guard(() async {
    await (db.delete(
      db.appointments,
    )..where((t) => t.memberId.equals(memberId))).go();
  });

  static AppointmentsCompanion _toRow(Appointment appointment) =>
      AppointmentsCompanion.insert(
        id: appointment.id,
        memberId: appointment.memberId,
        doctorName: appointment.doctorName,
        scheduledAt: StorageCodecs.encodeLocalDateTime(appointment.dateTime),
        specialty: Value(appointment.specialty),
        location: Value(appointment.location),
        notes: Value(appointment.notes),
      );

  static Appointment _toModel(AppointmentRow row) => Appointment(
    id: row.id,
    memberId: row.memberId,
    doctorName: row.doctorName,
    dateTime: StorageCodecs.decodeLocalDateTime(row.scheduledAt),
    specialty: row.specialty,
    location: row.location,
    notes: row.notes,
  );
}
