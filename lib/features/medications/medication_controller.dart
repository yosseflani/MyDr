import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/models/dose_record.dart';
import 'package:mydr/data/models/medication.dart';
import 'package:mydr/data/reminders/reminder_planner.dart';
import 'package:mydr/data/reminders/reminder_scheduler.dart';
import 'package:mydr/data/repositories/dose_record_repository.dart';
import 'package:mydr/data/repositories/family_repository.dart';
import 'package:mydr/data/repositories/medication_repository.dart';
import 'package:mydr/data/repositories/transaction_runner.dart';
import 'package:mydr/features/family/family_controller.dart';

/// Outcome of adding or updating a medication.
enum MedicationSaveResult {
  success,

  /// The name is empty.
  nameRequired,

  /// The dose is empty.
  doseRequired,

  /// No reminder time was given.
  reminderTimeRequired,

  /// More than [Medication.maxReminderTimes] reminder times.
  tooManyReminderTimes,

  /// The end date is before the start date.
  endBeforeStart,

  /// The family member does not exist (any more).
  memberNotFound,

  /// The medication being updated does not exist (any more).
  medicationNotFound,

  /// Nothing was changed.
  failed,
}

/// Outcome of recording a scheduled dose as taken or skipped.
enum DoseRecordResult {
  success,

  /// No dose of the medication is scheduled at that time (outside the
  /// treatment dates, or not one of its reminder times).
  notScheduled,

  /// The dose is on a later day.
  inFuture,

  /// The medication does not exist (any more).
  medicationNotFound,

  /// Nothing was changed.
  failed,
}

/// One scheduled dose of a medication, and its record if the user made one.
class ScheduledDose {
  const ScheduledDose({
    required this.medication,
    required this.at,
    this.record,
  });

  final Medication medication;

  /// Local wall-clock date and time.
  final DateTime at;
  final DoseRecord? record;
}

/// State and actions for medications, dose records and dose reminders.
///
/// Stores and shows exactly what the user entered: it never suggests a
/// medication or a dose, never draws conclusions from the records, and
/// does not judge a dose that has no record.
///
/// Like the other controllers, the lists are re-read from the repositories
/// after every change, raw errors are never exposed, and everything is
/// reloaded when [FamilyController.relatedDataRevision] changes.
///
/// Reminders are planned from the loaded data by [ReminderPlanner] and
/// handed to the [ReminderScheduler] after every load and change, and on
/// [refreshReminders] (when the app returns to the foreground). A failure
/// there never affects the medications themselves: it only shows in
/// [reminderStatus].
class MedicationController extends ChangeNotifier {
  MedicationController({
    required AppDependencies dependencies,
    required FamilyController familyController,
    DateTime Function() clock = DateTime.now,
  }) : _medicationRepository = dependencies.medicationRepository,
       _doseRecordRepository = dependencies.doseRecordRepository,
       _familyRepository = dependencies.familyRepository,
       _transactions = dependencies.transactions,
       _scheduler = dependencies.reminderScheduler,
       _familyController = familyController,
       _clock = clock,
       _seenFamilyRevision = familyController.relatedDataRevision {
    _familyController.addListener(_onFamilyChanged);
  }

  /// How many days back the dose list of a medication reaches.
  static const int recentDays = 7;

  final MedicationRepository _medicationRepository;
  final DoseRecordRepository _doseRecordRepository;
  final FamilyRepository _familyRepository;
  final TransactionRunner _transactions;
  final ReminderScheduler _scheduler;
  final FamilyController _familyController;
  final DateTime Function() _clock;
  int _seenFamilyRevision;

  List<Medication> _medications = const [];
  List<DoseRecord> _records = const [];
  bool _isLoading = false;
  bool _hasLoadError = false;
  bool _hasLoaded = false;
  bool _isDisposed = false;

  /// Increases with every load, so only the latest one applies its result.
  int _loadGeneration = 0;

  ReminderStatus _reminderStatus = const ReminderStatus.unknown();
  bool _hasAskedForPermission = false;

  /// Reminder updates run one after another, never interleaved.
  Future<void> _reminderQueue = Future.value();

  /// All medications, ordered by name.
  List<Medication> get medications => _medications;
  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;
  ReminderStatus get reminderStatus => _reminderStatus;

  DateTime get now => _clock();

  String createId() => _medicationRepository.createId();

  Medication? medicationById(String id) {
    for (final medication in _medications) {
      if (medication.id == id) return medication;
    }
    return null;
  }

  /// [memberId]'s medications only, ordered by name.
  List<Medication> medicationsFor(String memberId) =>
      List.unmodifiable(_medications.where((m) => m.memberId == memberId));

  /// Records newest first, of one medication and/or one family member.
  List<DoseRecord> records({String? memberId, String? medicationId}) =>
      List.unmodifiable(
        _records.where(
          (r) =>
              (memberId == null || r.memberId == memberId) &&
              (medicationId == null || r.medicationId == medicationId),
        ),
      );

  DoseRecord? recordFor(String medicationId, DateTime at) {
    for (final record in _records) {
      if (record.medicationId == medicationId && record.scheduledAt == at) {
        return record;
      }
    }
    return null;
  }

  /// [memberId]'s scheduled doses on [day], earliest first.
  List<ScheduledDose> dosesOn(String memberId, DateTime day) {
    final doses = [
      for (final medication in medicationsFor(memberId))
        for (final at in medication.doseTimesOn(day))
          ScheduledDose(
            medication: medication,
            at: at,
            record: recordFor(medication.id, at),
          ),
    ]..sort(_byTime);
    return List.unmodifiable(doses);
  }

  /// [memberId]'s next scheduled doses after today, earliest first: at most
  /// [limit], within [days] days.
  List<ScheduledDose> upcomingDoses(
    String memberId, {
    int limit = 5,
    int days = 7,
  }) {
    final today = _today();
    final doses = <ScheduledDose>[];
    for (var i = 1; i <= days && doses.length < limit; i++) {
      doses.addAll(
        dosesOn(memberId, DateTime(today.year, today.month, today.day + i)),
      );
    }
    return List.unmodifiable(doses.take(limit));
  }

  /// The doses of [medicationId] from today back [recentDays] days (within
  /// its treatment dates), newest first: the ones the user can record.
  List<ScheduledDose> recentDoses(String medicationId) {
    final medication = medicationById(medicationId);
    if (medication == null) return const [];
    final today = _today();
    final doses = [
      for (var i = 0; i < recentDays; i++)
        for (final at in medication.doseTimesOn(
          DateTime(today.year, today.month, today.day - i),
        ))
          ScheduledDose(
            medication: medication,
            at: at,
            record: recordFor(medication.id, at),
          ),
    ]..sort((a, b) => _byTime(b, a));
    return List.unmodifiable(doses);
  }

  /// Whether a dose at [at] may be recorded now: today or earlier.
  bool canRecord(DateTime at) => !_dateOnly(at).isAfter(_today());

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _notify();

    await _fetch(generation);
    if (generation != _loadGeneration) return;

    _isLoading = false;
    _notify();
    await _updateReminders();
  }

  /// Adds a medication. Text is stored trimmed; empty instructions are
  /// stored as none.
  Future<MedicationSaveResult> add(Medication medication) async {
    try {
      final toSave = _cleaned(medication);
      final invalid = await _validate(toSave);
      if (invalid != null) return invalid;
      await _medicationRepository.add(toSave);
    } catch (_) {
      return MedicationSaveResult.failed;
    }
    await _refresh();
    return MedicationSaveResult.success;
  }

  /// Saves the details the user can edit. The family member never changes.
  ///
  /// Dose records already made are kept, even for doses no longer
  /// scheduled after the change, so the history stays as it happened.
  Future<MedicationSaveResult> update(
    String id, {
    required String name,
    required String dose,
    required String? instructions,
    required List<DoseTime> reminderTimes,
    required DateTime startDate,
    required DateTime? endDate,
  }) async {
    try {
      final stored = await _medicationRepository.getById(id);
      if (stored == null) return MedicationSaveResult.medicationNotFound;
      final toSave = _cleaned(
        stored.copyWith(
          name: name,
          dose: dose,
          instructions: () => instructions,
          reminderTimes: reminderTimes,
          startDate: startDate,
          endDate: () => endDate,
        ),
      );
      final invalid = await _validate(toSave);
      if (invalid != null) return invalid;
      await _medicationRepository.update(toSave);
    } catch (_) {
      return MedicationSaveResult.failed;
    }
    await _refresh();
    return MedicationSaveResult.success;
  }

  /// Deletes a medication with all its dose records, as one unit where the
  /// storage allows it. Returns whether it is gone. Its reminders are
  /// removed when reminders are planned again, right after.
  ///
  /// Must only be called after the user explicitly confirmed the deletion in
  /// the UI; passing false for [userConfirmed] throws an [ArgumentError].
  Future<bool> delete(String id, {required bool userConfirmed}) async {
    if (!userConfirmed) {
      throw ArgumentError.value(
        userConfirmed,
        'userConfirmed',
        'Deleting a medication requires explicit user confirmation',
      );
    }
    var deleted = true;
    try {
      await _transactions.run(() async {
        await _doseRecordRepository.deleteByMedication(id);
        await _medicationRepository.delete(id);
      });
    } catch (_) {
      deleted = false;
    }
    // Even a failed deletion may have removed records without rollback.
    await _refresh();
    return deleted;
  }

  /// Records the dose of [medicationId] scheduled at [at] as [status]. A
  /// dose has at most one record: recording it again changes its status.
  Future<DoseRecordResult> recordDose(
    String medicationId,
    DateTime at,
    DoseStatus status,
  ) async {
    try {
      final medication = await _medicationRepository.getById(medicationId);
      if (medication == null) return DoseRecordResult.medicationNotFound;
      if (!medication.isScheduledAt(at)) return DoseRecordResult.notScheduled;
      if (!canRecord(at)) return DoseRecordResult.inFuture;
      await _doseRecordRepository.save(
        DoseRecord(
          id: _doseRecordRepository.createId(),
          memberId: medication.memberId,
          medicationId: medication.id,
          scheduledAt: at,
          status: status,
          recordedAt: _clock(),
        ),
      );
    } catch (_) {
      return DoseRecordResult.failed;
    }
    await _refresh();
    return DoseRecordResult.success;
  }

  /// Removes the record of a dose, so it shows as not recorded again.
  /// Returns whether it is gone.
  Future<bool> clearDose(String medicationId, DateTime at) async {
    try {
      await _doseRecordRepository.deleteOccurrence(medicationId, at);
    } catch (_) {
      return false;
    }
    await _refresh();
    return true;
  }

  /// Checks the permission again and reschedules every reminder from the
  /// saved data. Called when the app returns to the foreground, which also
  /// catches a changed day, time zone or notification setting.
  Future<void> refreshReminders() async {
    _notify();
    await _updateReminders();
  }

  /// Asks the user to allow notifications, then reschedules.
  Future<ReminderAvailability> requestReminderPermission() async {
    try {
      await _scheduler.requestPermission();
    } catch (_) {
      // Reported through reminderStatus by the update below.
    }
    await _updateReminders();
    return _reminderStatus.availability ?? ReminderAvailability.unsupported;
  }

  /// Opens the system setting that lets reminders come at their exact time,
  /// then checks again and reschedules, so the reminders follow what the
  /// user chose. Returns whether they may still be late.
  Future<bool> requestExactReminders() async {
    try {
      await _scheduler.requestExactTiming();
    } catch (_) {
      // Checked again by the update below.
    }
    await _updateReminders();
    return _reminderStatus.mayBeLate;
  }

  /// Asks for notification permission after a medication is added, at most
  /// once while the app runs, and only if notifications are off. Never at
  /// start-up: the request comes when its reason is clear.
  Future<void> askForPermissionOnce() async {
    if (_hasAskedForPermission ||
        _reminderStatus.availability != ReminderAvailability.disabled) {
      return;
    }
    _hasAskedForPermission = true;
    await requestReminderPermission();
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

  Medication _cleaned(Medication medication) {
    final instructions = medication.instructions?.trim() ?? '';
    return medication.copyWith(
      name: _tidy(medication.name),
      dose: _tidy(medication.dose),
      instructions: () => instructions.isEmpty ? null : instructions,
    );
  }

  static String _tidy(String text) =>
      text.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// Checks against the repository, not the cached family list, so a
  /// member deleted a moment ago cannot slip through.
  Future<MedicationSaveResult?> _validate(Medication medication) async {
    if (medication.name.isEmpty) return MedicationSaveResult.nameRequired;
    if (medication.dose.isEmpty) return MedicationSaveResult.doseRequired;
    if (medication.reminderTimes.isEmpty) {
      return MedicationSaveResult.reminderTimeRequired;
    }
    if (medication.reminderTimes.length > Medication.maxReminderTimes) {
      return MedicationSaveResult.tooManyReminderTimes;
    }
    final end = medication.endDate;
    if (end != null && end.isBefore(medication.startDate)) {
      return MedicationSaveResult.endBeforeStart;
    }
    if (await _familyRepository.getById(medication.memberId) == null) {
      return MedicationSaveResult.memberNotFound;
    }
    return null;
  }

  /// Plans reminders from the loaded data and hands them to the scheduler.
  ///
  /// Never runs on data that failed to load: replacing the reminders then
  /// would cancel every one of them. Never throws.
  Future<void> _updateReminders() {
    final update = _reminderQueue.then((_) async {
      if (_isDisposed || !_hasLoaded || _hasLoadError) return;
      final plan = ReminderPlanner.plan(
        medications: _medications,
        records: _records,
        now: _clock(),
      );
      ReminderAvailability? availability;
      try {
        availability = await _scheduler.availability();
        await _scheduler.replaceAll(plan.reminders);
        _reminderStatus = ReminderStatus(
          availability: availability,
          plan: plan,
          mayBeLate: await _mayBeLate(availability, plan),
        );
      } catch (_) {
        _reminderStatus = ReminderStatus(
          availability: availability,
          hasFailed: true,
        );
      }
      _notify();
    });
    _reminderQueue = update.catchError((_) {});
    return _reminderQueue;
  }

  /// Only said while notifications are on and something is scheduled, so
  /// exact timing is never asked for without a reason. A failed check is
  /// not a scheduling failure: the reminders are in place either way.
  Future<bool> _mayBeLate(
    ReminderAvailability availability,
    ReminderPlan plan,
  ) async {
    if (availability != ReminderAvailability.enabled ||
        plan.reminders.isEmpty) {
      return false;
    }
    try {
      return !await _scheduler.hasExactTiming();
    } catch (_) {
      return false;
    }
  }

  /// Re-reads everything after a change, notifies, and reschedules.
  Future<void> _refresh() async {
    final generation = ++_loadGeneration;
    await _fetch(generation);
    if (generation != _loadGeneration) return;
    _isLoading = false;
    _notify();
    await _updateReminders();
  }

  Future<void> _fetch(int generation) async {
    try {
      final (medications, records) = await (
        _medicationRepository.getAll(),
        _doseRecordRepository.getAll(),
      ).wait;
      if (generation != _loadGeneration) return;
      _medications = medications;
      _records = records;
      _hasLoadError = false;
      _hasLoaded = true;
    } catch (_) {
      if (generation != _loadGeneration) return;
      _hasLoadError = true;
    }
  }

  DateTime _today() => _dateOnly(_clock());

  static DateTime _dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static int _byTime(ScheduledDose a, ScheduledDose b) {
    final byTime = a.at.compareTo(b.at);
    if (byTime != 0) return byTime;
    final byName = a.medication.name.compareTo(b.medication.name);
    return byName != 0 ? byName : a.medication.id.compareTo(b.medication.id);
  }

  /// Async work may finish after the controller was disposed; notifying
  /// then would throw.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }
}

/// Whether reminders are working, for the UI.
class ReminderStatus {
  const ReminderStatus({
    required this.availability,
    this.plan,
    this.hasFailed = false,
    this.mayBeLate = false,
  });

  /// Before the first check.
  const ReminderStatus.unknown()
    : availability = null,
      plan = null,
      hasFailed = false,
      mayBeLate = false;

  /// Null until checked, or when even checking failed.
  final ReminderAvailability? availability;

  /// What was scheduled by the last successful update.
  final ReminderPlan? plan;

  /// Whether the last update failed; the reminders scheduled before it may
  /// or may not still be in place.
  final bool hasFailed;

  /// Whether reminders are scheduled and notifications are on, but the
  /// user has not allowed exact timing, so the operating system may
  /// deliver them late.
  final bool mayBeLate;
}
