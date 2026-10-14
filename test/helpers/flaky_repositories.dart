import 'dart:async';

import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_appointment_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_doctor_question_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_family_repository.dart';

/// In-memory repositories whose operations can be switched to fail, for
/// testing error handling. Each flag stays on until reset by the test.

class SimulatedFailure implements Exception {
  const SimulatedFailure();
}

class FlakyFamilyRepository extends InMemoryFamilyRepository {
  FlakyFamilyRepository([super.initialMembers]);

  bool failGetAll = false;
  bool failAdd = false;
  bool failUpdate = false;
  bool failDelete = false;

  /// When set, [getAll] waits for it to complete, to observe loading states.
  Completer<void>? getAllGate;

  /// When set, [add] waits for it to complete, to observe saving states.
  Completer<void>? addGate;

  /// Number of times [add] was called.
  int addCalls = 0;

  @override
  Future<List<FamilyMember>> getAll() async {
    await getAllGate?.future;
    if (failGetAll) throw const SimulatedFailure();
    return super.getAll();
  }

  @override
  Future<void> add(FamilyMember item) async {
    addCalls++;
    await addGate?.future;
    if (failAdd) throw const SimulatedFailure();
    return super.add(item);
  }

  @override
  Future<void> update(FamilyMember item) async {
    if (failUpdate) throw const SimulatedFailure();
    return super.update(item);
  }

  /// When set, [delete] waits for it to complete, to observe deleting states.
  Completer<void>? deleteGate;

  /// Number of times [delete] was called.
  int deleteCalls = 0;

  @override
  Future<void> delete(String id) async {
    deleteCalls++;
    await deleteGate?.future;
    if (failDelete) throw const SimulatedFailure();
    return super.delete(id);
  }
}

class FlakyAppointmentRepository extends InMemoryAppointmentRepository {
  FlakyAppointmentRepository([super.initialAppointments]);

  bool failDeleteByMember = false;

  @override
  Future<void> deleteByMember(String memberId) async {
    if (failDeleteByMember) throw const SimulatedFailure();
    return super.deleteByMember(memberId);
  }
}

class FlakyDoctorQuestionRepository extends InMemoryDoctorQuestionRepository {
  FlakyDoctorQuestionRepository([super.initialQuestions]);

  bool failGetAll = false;
  bool failDeleteByMember = false;

  @override
  Future<List<DoctorQuestion>> getAll({
    String? memberId,
    String? appointmentId,
  }) async {
    if (failGetAll) throw const SimulatedFailure();
    return super.getAll(memberId: memberId, appointmentId: appointmentId);
  }

  @override
  Future<void> deleteByMember(String memberId) async {
    if (failDeleteByMember) throw const SimulatedFailure();
    return super.deleteByMember(memberId);
  }
}
