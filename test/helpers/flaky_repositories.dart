import 'dart:async';

import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_appointment_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_doctor_question_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_family_repository.dart';
import 'package:mydr/data/repositories/in_memory/in_memory_symptom_repository.dart';

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

  bool failGetAll = false;
  bool failAdd = false;
  bool failUpdate = false;
  bool failDelete = false;
  bool failDeleteByMember = false;

  /// Number of times [getAll] was called.
  int getAllCalls = 0;

  /// When set, [getAll] waits for it to complete, to observe loading states.
  Completer<void>? getAllGate;

  @override
  Future<List<Appointment>> getAll({String? memberId}) async {
    getAllCalls++;
    await getAllGate?.future;
    if (failGetAll) throw const SimulatedFailure();
    return super.getAll(memberId: memberId);
  }

  /// When set, [add] waits for it to complete, to observe saving states.
  Completer<void>? addGate;

  /// Number of times [add] was called.
  int addCalls = 0;

  @override
  Future<void> add(Appointment item) async {
    addCalls++;
    await addGate?.future;
    if (failAdd) throw const SimulatedFailure();
    return super.add(item);
  }

  @override
  Future<void> update(Appointment item) async {
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
  bool failDetach = false;
  bool failAdd = false;
  bool failUpdate = false;
  bool failDelete = false;

  /// Number of times [getAll] was called.
  int getAllCalls = 0;

  /// When set, [add] waits for it to complete, to observe saving states.
  Completer<void>? addGate;

  /// Number of times [add] was called.
  int addCalls = 0;

  @override
  Future<void> add(DoctorQuestion item) async {
    addCalls++;
    await addGate?.future;
    if (failAdd) throw const SimulatedFailure();
    return super.add(item);
  }

  /// When set, [update] waits for it to complete, to observe saving states.
  Completer<void>? updateGate;

  /// Number of times [update] was called.
  int updateCalls = 0;

  @override
  Future<void> update(DoctorQuestion item) async {
    updateCalls++;
    await updateGate?.future;
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

  /// When set, [getAll] waits for it to complete, to observe loading states.
  Completer<void>? getAllGate;

  /// Number of times [detachFromAppointment] was called.
  int detachCalls = 0;

  @override
  Future<void> detachFromAppointment(String appointmentId) async {
    detachCalls++;
    if (failDetach) throw const SimulatedFailure();
    return super.detachFromAppointment(appointmentId);
  }

  @override
  Future<List<DoctorQuestion>> getAll({
    String? memberId,
    String? appointmentId,
  }) async {
    getAllCalls++;
    await getAllGate?.future;
    if (failGetAll) throw const SimulatedFailure();
    return super.getAll(memberId: memberId, appointmentId: appointmentId);
  }

  @override
  Future<void> deleteByMember(String memberId) async {
    if (failDeleteByMember) throw const SimulatedFailure();
    return super.deleteByMember(memberId);
  }
}

class FlakySymptomRepository extends InMemorySymptomRepository {
  FlakySymptomRepository([super.initialEntries]);

  bool failGetAll = false;
  bool failAdd = false;
  bool failUpdate = false;
  bool failDelete = false;
  bool failDeleteByMember = false;

  /// Number of times [getAll] was called.
  int getAllCalls = 0;

  /// When set, [getAll] waits for it to complete, to observe loading states.
  Completer<void>? getAllGate;

  @override
  Future<List<SymptomEntry>> getAll({String? memberId}) async {
    getAllCalls++;
    await getAllGate?.future;
    if (failGetAll) throw const SimulatedFailure();
    return super.getAll(memberId: memberId);
  }

  @override
  Future<void> add(SymptomEntry item) async {
    if (failAdd) throw const SimulatedFailure();
    return super.add(item);
  }

  @override
  Future<void> update(SymptomEntry item) async {
    if (failUpdate) throw const SimulatedFailure();
    return super.update(item);
  }

  @override
  Future<void> delete(String id) async {
    if (failDelete) throw const SimulatedFailure();
    return super.delete(id);
  }

  @override
  Future<void> deleteByMember(String memberId) async {
    if (failDeleteByMember) throw const SimulatedFailure();
    return super.deleteByMember(memberId);
  }
}
