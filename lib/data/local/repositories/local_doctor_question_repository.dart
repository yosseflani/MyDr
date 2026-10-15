import 'package:drift/drift.dart';
import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/local/repositories/local_repository_support.dart';
import 'package:mydr/data/local/storage_codecs.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/repositories/doctor_question_repository.dart';

class LocalDoctorQuestionRepository extends LocalRepository
    implements DoctorQuestionRepository {
  LocalDoctorQuestionRepository(super.db);

  @override
  Future<List<DoctorQuestion>> getAll({
    String? memberId,
    String? appointmentId,
  }) => guard(() async {
    final query = db.select(db.doctorQuestions)
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
  Future<DoctorQuestion?> getById(String id) => guard(() async {
    final row = await (db.select(
      db.doctorQuestions,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toModel(row);
  });

  /// Refused (a [LocalDataException]) if the family member does not exist,
  /// or the linked appointment does not exist or belongs to another member.
  @override
  Future<void> add(DoctorQuestion item) =>
      insertNew(db.doctorQuestions, item.id, _toRow(item));

  @override
  Future<void> update(DoctorQuestion item) => guard(() async {
    final rows = await (db.update(
      db.doctorQuestions,
    )..where((t) => t.id.equals(item.id))).write(_toRow(item));
    expectUpdated(rows, item.id);
  });

  @override
  Future<void> delete(String id) => guard(() async {
    await (db.delete(db.doctorQuestions)..where((t) => t.id.equals(id))).go();
  });

  @override
  Future<void> detachFromAppointment(String appointmentId) => guard(() async {
    await (db.update(db.doctorQuestions)
          ..where((t) => t.appointmentId.equals(appointmentId)))
        .write(const DoctorQuestionsCompanion(appointmentId: Value(null)));
  });

  @override
  Future<void> deleteByMember(String memberId) => guard(() async {
    await (db.delete(
      db.doctorQuestions,
    )..where((t) => t.memberId.equals(memberId))).go();
  });

  static DoctorQuestionsCompanion _toRow(DoctorQuestion question) =>
      DoctorQuestionsCompanion.insert(
        id: question.id,
        memberId: question.memberId,
        appointmentId: Value(question.appointmentId),
        questionText: question.text,
        createdAt: StorageCodecs.encodeInstant(question.createdAt),
        isResolved: Value(question.isResolved ? 1 : 0),
        doctorAnswer: Value(question.doctorAnswer),
      );

  static DoctorQuestion _toModel(DoctorQuestionRow row) => DoctorQuestion(
    id: row.id,
    memberId: row.memberId,
    appointmentId: row.appointmentId,
    text: row.questionText,
    createdAt: StorageCodecs.decodeInstant(row.createdAt),
    isResolved: row.isResolved == 1,
    doctorAnswer: row.doctorAnswer,
  );
}
