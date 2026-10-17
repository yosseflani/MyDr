import 'package:flutter/foundation.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/repositories/transaction_runner.dart';
import 'package:mydr/data/models/family_member.dart';
import 'package:mydr/data/repositories/appointment_repository.dart';
import 'package:mydr/data/repositories/doctor_question_repository.dart';
import 'package:mydr/data/repositories/dose_record_repository.dart';
import 'package:mydr/data/repositories/family_repository.dart';
import 'package:mydr/data/repositories/medication_repository.dart';
import 'package:mydr/data/repositories/symptom_repository.dart';
import 'package:mydr/data/media/visit_media_file_store.dart';
import 'package:mydr/data/repositories/visit_media_repository.dart';

/// Outcome of adding or updating a family member.
enum FamilySaveResult { success, selfAlreadyExists, failed }

/// The steps of deleting a family member, in the order they run.
///
/// Related data is removed before the profile, so a failure part-way never
/// leaves data that belongs to a profile that no longer exists.
enum MemberDeletionStep {
  symptoms,
  doctorQuestions,
  visitMedia,
  doseRecords,
  medications,
  appointments,
  profile,
}

class MemberDeletionResult {
  const MemberDeletionResult.success() : failedStep = null;

  const MemberDeletionResult.failed(MemberDeletionStep this.failedStep);

  /// The step that failed, or null if everything was deleted.
  final MemberDeletionStep? failedStep;

  bool get isSuccess => failedStep == null;
}

/// How much data is linked to a family member. Shown to the user before
/// they confirm a deletion.
class RelatedDataSummary {
  const RelatedDataSummary({
    required this.appointments,
    required this.doctorQuestions,
    required this.symptoms,
    this.visitMedia = 0,
    this.medications = 0,
    this.doseRecords = 0,
  });

  final int appointments;
  final int doctorQuestions;
  final int symptoms;

  /// Photos and videos attached to the member's appointments.
  final int visitMedia;

  final int medications;

  /// Scheduled doses recorded as taken or skipped.
  final int doseRecords;

  bool get isEmpty =>
      appointments == 0 &&
      doctorQuestions == 0 &&
      symptoms == 0 &&
      visitMedia == 0 &&
      medications == 0 &&
      doseRecords == 0;
}

/// State and actions for the family members feature.
///
/// The member list is always re-read from [FamilyRepository] after a change,
/// so the repository stays the single source of truth. Raw errors are never
/// exposed, since they may contain personal medical details.
class FamilyController extends ChangeNotifier {
  FamilyController(AppDependencies dependencies)
    : _familyRepository = dependencies.familyRepository,
      _appointmentRepository = dependencies.appointmentRepository,
      _doctorQuestionRepository = dependencies.doctorQuestionRepository,
      _symptomRepository = dependencies.symptomRepository,
      _visitMediaRepository = dependencies.visitMediaRepository,
      _visitMediaFiles = dependencies.visitMediaFiles,
      _medicationRepository = dependencies.medicationRepository,
      _doseRecordRepository = dependencies.doseRecordRepository,
      _transactions = dependencies.transactions;

  final FamilyRepository _familyRepository;
  final AppointmentRepository _appointmentRepository;
  final DoctorQuestionRepository _doctorQuestionRepository;
  final SymptomRepository _symptomRepository;
  final VisitMediaRepository _visitMediaRepository;
  final VisitMediaFileStore _visitMediaFiles;
  final MedicationRepository _medicationRepository;
  final DoseRecordRepository _doseRecordRepository;
  final TransactionRunner _transactions;

  List<FamilyMember> _members = const [];
  bool _isLoading = false;
  bool _hasLoadError = false;
  final Set<String> _deletingIds = {};
  final Set<String> _incompleteDeletionIds = {};
  int _relatedDataRevision = 0;

  /// Increases after every member deletion attempt, successful or not,
  /// since either may have removed appointments, questions, symptoms,
  /// visit photos and videos, or medications and their dose records.
  /// Other controllers watch it to know when to reload their data.
  int get relatedDataRevision => _relatedDataRevision;

  /// Members ordered by relation, then by name.
  List<FamilyMember> get members => _members;
  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;

  /// Whether a deletion of [memberId] is running right now.
  bool isDeleting(String memberId) => _deletingIds.contains(memberId);

  /// Whether a previous deletion of [memberId] failed part-way. Some of the
  /// member's related data may already be gone; deleting again is safe and
  /// finishes the job.
  bool isDeletionIncomplete(String memberId) =>
      _incompleteDeletionIds.contains(memberId);

  FamilyMember? memberById(String id) {
    for (final member in _members) {
      if (member.id == id) return member;
    }
    return null;
  }

  /// Whether [FamilyRelation.self] may be chosen, ignoring
  /// [excludingMemberId] (the member being edited).
  bool isSelfRelationAvailable({String? excludingMemberId}) {
    return !_members.any(
      (m) => m.relation == FamilyRelation.self && m.id != excludingMemberId,
    );
  }

  String createId() => _familyRepository.createId();

  Future<void> load() async {
    _isLoading = true;
    notifyListeners();

    await _fetchMembers();

    _isLoading = false;
    notifyListeners();
  }

  Future<FamilySaveResult> add(FamilyMember member) =>
      _save(member, isNew: true);

  Future<FamilySaveResult> update(FamilyMember member) =>
      _save(member, isNew: false);

  /// Counts the data linked to [memberId], or returns null if it could not
  /// be read.
  Future<RelatedDataSummary?> relatedDataSummary(String memberId) async {
    try {
      final (
        appointments,
        questions,
        symptoms,
        media,
        medications,
        doses,
      ) = await (
        _appointmentRepository.getAll(memberId: memberId),
        _doctorQuestionRepository.getAll(memberId: memberId),
        _symptomRepository.getAll(memberId: memberId),
        _visitMediaRepository.getAll(memberId: memberId),
        _medicationRepository.getAll(memberId: memberId),
        _doseRecordRepository.getAll(memberId: memberId),
      ).wait;
      return RelatedDataSummary(
        appointments: appointments.length,
        doctorQuestions: questions.length,
        symptoms: symptoms.length,
        visitMedia: media.length,
        medications: medications.length,
        doseRecords: doses.length,
      );
    } catch (_) {
      return null;
    }
  }

  /// Deletes a member together with their symptoms, questions, visit photos
  /// and videos, medications with their dose records, and appointments.
  /// Media files are removed from private storage once their records are
  /// gone for good. The member's reminders go when [MedicationController]
  /// plans reminders again, on [relatedDataRevision].
  ///
  /// Must only be called after the user explicitly confirmed the deletion in
  /// the UI; [userConfirmed] makes that requirement visible at every call
  /// site, and passing false throws an [ArgumentError].
  ///
  /// The steps are separate operations, not a transaction. On failure the
  /// remaining steps are skipped, the profile is kept and the member is
  /// marked with [isDeletionIncomplete]. Every step is safe to repeat, so
  /// calling this again resumes the deletion.
  Future<MemberDeletionResult> delete(
    String memberId, {
    required bool userConfirmed,
  }) async {
    if (!userConfirmed) {
      throw ArgumentError.value(
        userConfirmed,
        'userConfirmed',
        'Deleting a family member requires explicit user confirmation',
      );
    }

    var mediaFiles = const <String>[];
    var mediaRecordsDeleted = false;
    final steps = <(MemberDeletionStep, Future<void> Function())>[
      (
        MemberDeletionStep.symptoms,
        () => _symptomRepository.deleteByMember(memberId),
      ),
      (
        MemberDeletionStep.doctorQuestions,
        () => _doctorQuestionRepository.deleteByMember(memberId),
      ),
      (
        MemberDeletionStep.visitMedia,
        () async {
          final media = await _visitMediaRepository.getAll(memberId: memberId);
          mediaFiles = [for (final item in media) item.fileName];
          await _visitMediaRepository.deleteByMember(memberId);
          mediaRecordsDeleted = true;
        },
      ),
      (
        MemberDeletionStep.doseRecords,
        () => _doseRecordRepository.deleteByMember(memberId),
      ),
      (
        MemberDeletionStep.medications,
        () => _medicationRepository.deleteByMember(memberId),
      ),
      (
        MemberDeletionStep.appointments,
        () => _appointmentRepository.deleteByMember(memberId),
      ),
      (MemberDeletionStep.profile, () => _familyRepository.delete(memberId)),
    ];

    _deletingIds.add(memberId);
    notifyListeners();

    var result = const MemberDeletionResult.success();
    var currentStep = steps.first.$1;
    try {
      // With an atomic runner (the local database), a failure undoes every
      // step, so nothing is ever half deleted.
      await _transactions.run(() async {
        for (final (step, run) in steps) {
          currentStep = step;
          await run();
        }
      });
    } catch (_) {
      result = MemberDeletionResult.failed(currentStep);
    }

    // Only once the records are gone for good: a rolled-back deletion keeps
    // its files.
    if (result.isSuccess || (mediaRecordsDeleted && !_transactions.isAtomic)) {
      await deleteVisitMediaFiles(_visitMediaFiles, mediaFiles);
    }

    if (result.isSuccess) {
      _incompleteDeletionIds.remove(memberId);
    } else if (!_transactions.isAtomic) {
      // Without rollback, any failure may have removed part of the data,
      // even within one step.
      _incompleteDeletionIds.add(memberId);
    }
    _deletingIds.remove(memberId);
    _relatedDataRevision++;

    await _fetchMembers();
    notifyListeners();
    return result;
  }

  Future<FamilySaveResult> _save(
    FamilyMember member, {
    required bool isNew,
  }) async {
    try {
      if (member.relation == FamilyRelation.self &&
          await _anotherSelfExists(member.id)) {
        return FamilySaveResult.selfAlreadyExists;
      }
      if (isNew) {
        await _familyRepository.add(member);
      } else {
        await _familyRepository.update(member);
      }
    } catch (_) {
      return FamilySaveResult.failed;
    }

    await _fetchMembers();
    notifyListeners();
    return FamilySaveResult.success;
  }

  /// Checks against the repository, not the cached list, so a stale cache
  /// cannot let a second "self" profile through.
  Future<bool> _anotherSelfExists(String memberId) async {
    final all = await _familyRepository.getAll();
    return all.any(
      (m) => m.relation == FamilyRelation.self && m.id != memberId,
    );
  }

  /// Re-reads the members. Does not notify; callers do.
  Future<void> _fetchMembers() async {
    try {
      _members = await _familyRepository.getAll();
      _hasLoadError = false;
    } catch (_) {
      _hasLoadError = true;
    }
  }
}
