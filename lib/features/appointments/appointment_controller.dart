import 'package:flutter/foundation.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/repositories/transaction_runner.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/repositories/appointment_repository.dart';
import 'package:mydr/data/repositories/doctor_question_repository.dart';
import 'package:mydr/data/repositories/family_repository.dart';
import 'package:mydr/features/family/family_controller.dart';

/// Outcome of adding or updating an appointment.
enum AppointmentSaveResult {
  success,

  /// The chosen family member does not exist (any more).
  memberNotFound,

  /// The appointment being updated does not exist (any more).
  appointmentNotFound,

  /// Nothing was changed.
  failed,

  /// The member was being changed: the linked questions were already
  /// unlinked (and kept as general questions of the original member), but
  /// saving the appointment itself failed. Saving again is safe.
  failedAfterDetachingQuestions,
}

/// The steps of deleting an appointment, in the order they run.
///
/// Questions are unlinked first, so a failure never leaves questions
/// pointing to an appointment that no longer exists.
enum AppointmentDeletionStep { detachQuestions, appointment }

class AppointmentDeletionResult {
  const AppointmentDeletionResult.success() : failedStep = null;

  const AppointmentDeletionResult.failed(
    AppointmentDeletionStep this.failedStep,
  );

  /// The step that failed, or null if the appointment was deleted.
  final AppointmentDeletionStep? failedStep;

  bool get isSuccess => failedStep == null;
}

/// State and actions for the appointments feature.
///
/// Like [FamilyController], the list is always re-read from the repository
/// after a change, and raw errors are never exposed.
///
/// Keeps in sync with [FamilyController]: deleting a family member also
/// deletes their appointments, so the list is reloaded whenever
/// [FamilyController.relatedDataRevision] changes, and only then.
class AppointmentController extends ChangeNotifier {
  AppointmentController({
    required AppDependencies dependencies,
    required FamilyController familyController,
  }) : _appointmentRepository = dependencies.appointmentRepository,
       _doctorQuestionRepository = dependencies.doctorQuestionRepository,
       _familyRepository = dependencies.familyRepository,
       _transactions = dependencies.transactions,
       _familyController = familyController,
       _seenFamilyRevision = familyController.relatedDataRevision {
    _familyController.addListener(_onFamilyChanged);
  }

  final AppointmentRepository _appointmentRepository;
  final DoctorQuestionRepository _doctorQuestionRepository;
  final FamilyRepository _familyRepository;
  final TransactionRunner _transactions;
  final FamilyController _familyController;
  int _seenFamilyRevision;

  List<Appointment> _appointments = const [];
  bool _isLoading = false;
  bool _hasLoadError = false;
  bool _isDisposed = false;

  int _questionLinksRevision = 0;

  /// Increases whenever an operation unlinked, or tried to unlink, questions
  /// from an appointment: every deletion attempt, and updates that change
  /// the family member. Other controllers watch it to know when to reload
  /// questions. Plain edits, additions and loads leave it unchanged.
  int get questionLinksRevision => _questionLinksRevision;

  /// Increases with every [load], so only the latest one applies its result.
  int _loadGeneration = 0;

  /// All appointments, earliest first.
  List<Appointment> get appointments => _appointments;
  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;

  Appointment? appointmentById(String id) {
    for (final appointment in _appointments) {
      if (appointment.id == id) return appointment;
    }
    return null;
  }

  /// Appointments at or after [now], nearest first, optionally only for
  /// [memberId].
  List<Appointment> upcoming(DateTime now, {String? memberId}) {
    return List.unmodifiable(
      _appointments.where(
        (a) =>
            a.isUpcoming(now) && (memberId == null || a.memberId == memberId),
      ),
    );
  }

  /// Appointments before [now], most recent first, optionally only for
  /// [memberId].
  List<Appointment> past(DateTime now, {String? memberId}) {
    return List.unmodifiable(
      _appointments
          .where(
            (a) =>
                !a.isUpcoming(now) &&
                (memberId == null || a.memberId == memberId),
          )
          .toList()
          .reversed,
    );
  }

  String createId() => _appointmentRepository.createId();

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _notify();

    await _fetchAppointments(generation);
    if (generation != _loadGeneration) return;

    _isLoading = false;
    _notify();
  }

  Future<AppointmentSaveResult> add(Appointment appointment) async {
    try {
      if (!await _memberExists(appointment.memberId)) {
        return AppointmentSaveResult.memberNotFound;
      }
      await _appointmentRepository.add(appointment);
    } catch (_) {
      return AppointmentSaveResult.failed;
    }
    await _refresh();
    return AppointmentSaveResult.success;
  }

  /// Saves changes to an existing appointment.
  ///
  /// When the family member changes, questions linked to the appointment are
  /// first unlinked from it (keeping their original member) and only then is
  /// the appointment saved. A question never ends up linked to an
  /// appointment of a different member.
  Future<AppointmentSaveResult> update(Appointment appointment) async {
    var detachAttempted = false;
    var questionsDetached = false;
    try {
      final stored = await _appointmentRepository.getById(appointment.id);
      if (stored == null) return AppointmentSaveResult.appointmentNotFound;
      if (!await _memberExists(appointment.memberId)) {
        return AppointmentSaveResult.memberNotFound;
      }

      // Unlinking and saving together: with an atomic runner, a failed
      // save also undoes the unlinking.
      await _transactions.run(() async {
        if (stored.memberId != appointment.memberId) {
          detachAttempted = true;
          await _doctorQuestionRepository.detachFromAppointment(appointment.id);
          questionsDetached = true;
        }
        await _appointmentRepository.update(appointment);
      });
    } catch (_) {
      // Question links may have changed even though saving failed, so
      // listeners must still hear about it.
      if (detachAttempted) {
        _questionLinksRevision++;
        await _refresh();
      }
      return questionsDetached && !_transactions.isAtomic
          ? AppointmentSaveResult.failedAfterDetachingQuestions
          : AppointmentSaveResult.failed;
    }
    if (detachAttempted) _questionLinksRevision++;
    await _refresh();
    return AppointmentSaveResult.success;
  }

  /// Number of questions linked to [appointmentId], or null if they could
  /// not be read.
  Future<int?> linkedQuestionCount(String appointmentId) async {
    try {
      final questions = await _doctorQuestionRepository.getAll(
        appointmentId: appointmentId,
      );
      return questions.length;
    } catch (_) {
      return null;
    }
  }

  /// Deletes an appointment. Its linked questions are kept, unlinked, as
  /// general questions of the same family member.
  ///
  /// Must only be called after the user explicitly confirmed the deletion in
  /// the UI; passing false for [userConfirmed] throws an [ArgumentError].
  ///
  /// The steps are separate operations, not a transaction. Each is safe to
  /// repeat, so after a failure calling this again finishes the deletion.
  Future<AppointmentDeletionResult> delete(
    String appointmentId, {
    required bool userConfirmed,
  }) async {
    if (!userConfirmed) {
      throw ArgumentError.value(
        userConfirmed,
        'userConfirmed',
        'Deleting an appointment requires explicit user confirmation',
      );
    }

    var result = const AppointmentDeletionResult.success();
    var step = AppointmentDeletionStep.detachQuestions;
    try {
      // The questions are kept, only unlinked. With an atomic runner, a
      // failed deletion also undoes the unlinking.
      await _transactions.run(() async {
        await _doctorQuestionRepository.detachFromAppointment(appointmentId);
        step = AppointmentDeletionStep.appointment;
        await _appointmentRepository.delete(appointmentId);
      });
    } catch (_) {
      result = AppointmentDeletionResult.failed(step);
    }

    // Unlinking was attempted, so question links may have changed even if a
    // step failed.
    _questionLinksRevision++;
    await _refresh();
    return result;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _familyController.removeListener(_onFamilyChanged);
    super.dispose();
  }

  void _onFamilyChanged() {
    final revision = _familyController.relatedDataRevision;
    if (revision == _seenFamilyRevision) return;
    _seenFamilyRevision = revision;
    load();
  }

  /// Checks the repository rather than [FamilyController]'s cached list, so
  /// a member deleted a moment ago cannot slip through.
  Future<bool> _memberExists(String memberId) async =>
      await _familyRepository.getById(memberId) != null;

  /// Re-reads the list after a change and notifies listeners.
  Future<void> _refresh() async {
    final generation = ++_loadGeneration;
    await _fetchAppointments(generation);
    if (generation != _loadGeneration) return;
    _isLoading = false;
    _notify();
  }

  Future<void> _fetchAppointments(int generation) async {
    try {
      final appointments = await _appointmentRepository.getAll();
      if (generation != _loadGeneration) return;
      _appointments = appointments;
      _hasLoadError = false;
    } catch (_) {
      if (generation != _loadGeneration) return;
      _hasLoadError = true;
    }
  }

  /// Async work may finish after the app (or a test) disposed the
  /// controller; notifying then would throw.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }
}
