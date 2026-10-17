import 'package:drift/drift.dart';
import 'package:mydr/data/local/local_database.dart' hide VisitMedia;
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/visit_media.dart';
import 'package:mydr/data/repositories/visit_media_repository.dart';

class LocalVisitMediaRepository extends LocalRepository
    implements VisitMediaRepository {
  LocalVisitMediaRepository(super.db);

  @override
  Future<List<VisitMedia>> getAll({String? memberId, String? appointmentId}) =>
      guard(() async {
        final query = db.select(db.visitMedia)
          ..orderBy([
            (t) => OrderingTerm.asc(t.createdAt),
            (t) => OrderingTerm.asc(t.id),
          ]);
        if (memberId != null) query.where((t) => t.memberId.equals(memberId));
        if (appointmentId != null) {
          query.where((t) => t.appointmentId.equals(appointmentId));
        }
        return List.unmodifiable((await query.get()).map(_toModel));
      });

  @override
  Future<VisitMedia?> getById(String id) => guard(() async {
    final row = await (db.select(
      db.visitMedia,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  });

  /// Refused (a [LocalDataException]) if the appointment does not exist or
  /// belongs to another family member, or the file name is already used.
  @override
  Future<void> add(VisitMedia item) =>
      insertNew(db.visitMedia, item.id, _toRow(item));

  @override
  Future<void> update(VisitMedia item) => guard(() async {
    final rows =
        await (db.update(db.visitMedia)..where((t) => t.id.equals(item.id)))
            .write(VisitMediaCompanion(description: Value(item.description)));
    expectUpdated(rows, item.id);
  });

  @override
  Future<void> delete(String id) => guard(() async {
    await (db.delete(db.visitMedia)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<void> deleteByAppointment(String appointmentId) => guard(() async {
    await (db.delete(
      db.visitMedia,
    )..where((t) => t.appointmentId.equals(appointmentId))).go();
  });

  @override
  Future<void> deleteByMember(String memberId) => guard(() async {
    await (db.delete(
      db.visitMedia,
    )..where((t) => t.memberId.equals(memberId))).go();
  });

  static VisitMediaCompanion _toRow(VisitMedia media) =>
      VisitMediaCompanion.insert(
        id: media.id,
        memberId: media.memberId,
        appointmentId: media.appointmentId,
        kind: media.kind.name,
        fileName: media.fileName,
        byteSize: media.byteSize,
        description: Value(media.description),
        createdAt: StorageCodecs.encodeInstant(media.createdAt),
      );

  static VisitMedia _toModel(VisitMediaRow row) => VisitMedia(
    id: row.id,
    memberId: row.memberId,
    appointmentId: row.appointmentId,
    kind: VisitMediaKind.values.byName(row.kind),
    fileName: row.fileName,
    byteSize: row.byteSize,
    description: row.description,
    createdAt: StorageCodecs.decodeInstant(row.createdAt),
  );
}
