import 'package:flutter/foundation.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/models/doctor_question.dart';
import 'package:mydr/data/repositories/appointment_repository.dart';
import 'package:mydr/data/repositories/doctor_question_repository.dart';
import 'package:mydr/data/repositories/family_repository.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/family/family_controller.dart';

/// Outcome of adding or updating a question.
enum QuestionSaveResult {
  success,

  /// The question text is empty.
  textRequired,

  /// The family member does not exist (any more).
  memberNotFound,

  /// The linked appointment does not exist (any more).
  appointmentNotFound,

  /// The linked appointment belongs to a different family member.
  appointmentOfAnotherMember,

  /// The question being updated does not exist (any more).
  questionNotFound,

  /// Nothing was changed.
  failed,
}

/// State and actions for questions to the doctor.
///
/// Like the other controllers, the list is always re-read from the
/// repository after a change, and raw errors are never exposed.
///
/// Questions also change as a side effect of other features: deleting a
/// family member deletes their questions, and deleting an appointment or
/// moving it to another member unlinks its questions. The list is reloaded
/// when [FamilyController.relatedDataRevision] or
/// [AppointmentController.questionLinksRevision] changes, and only then.
class DoctorQuestionController extends ChangeNotifier {
  DoctorQuestionController({
    required AppDependencies dependencies,
    required FamilyController familyController,
    required AppointmentController appointmentController,
  }) : _questionRepository = dependencies.doctorQuestionRepository,
       _familyRepository = dependencies.familyRepository,
       _appointmentRepository = dependencies.appointmentRepository,
       _familyController = familyController,
       _appointmentController = appointmentController,
       _seenFamilyRevision = familyController.relatedDataRevision,
       _seenQuestionLinksRevision =
           appointmentController.questionLinksRevision {
    _familyController.addListener(_onFamilyChanged);
    _appointmentController.addListener(_onAppointmentsChanged);
  }

  final DoctorQuestionRepository _questionRepository;
  final FamilyRepository _familyRepository;
  final AppointmentRepository _appointmentRepository;
  final FamilyController _familyController;
  final AppointmentController _appointmentController;
  int _seenFamilyRevision;
  int _seenQuestionLinksRevision;

  List<DoctorQuestion> _questions = const [];
  bool _isLoading = false;
  bool _hasLoadError = false;
  bool _isDisposed = false;

  /// Increases with every load, so only the latest one applies its result.
  int _loadGeneration = 0;

  /// All questions, oldest first.
  List<DoctorQuestion> get questions => _questions;
  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;

  DoctorQuestion? questionById(String id) {
    for (final question in _questions) {
      if (question.id == id) return question;
    }
    return null;
  }

  /// Questions of [memberId], oldest first.
  List<DoctorQuestion> forMember(String memberId) =>
      _where((q) => q.memberId == memberId);

  /// Questions linked to [appointmentId], oldest first.
  List<DoctorQuestion> forAppointment(String appointmentId) =>
      _where((q) => q.appointmentId == appointmentId);

  /// Questions not yet handled, oldest first, optionally only for
  /// [memberId].
  List<DoctorQuestion> unresolved({String? memberId}) => _where(
    (q) => !q.isResolved && (memberId == null || q.memberId == memberId),
  );

  /// Handled questions, oldest first, optionally only for [memberId].
  List<DoctorQuestion> resolved({String? memberId}) => _where(
    (q) => q.isResolved && (memberId == null || q.memberId == memberId),
  );

  String createId() => _questionRepository.createId();

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _notify();

    await _fetchQuestions(generation);
    if (generation != _loadGeneration) return;

    _isLoading = false;
    _notify();
  }

  Future<QuestionSaveResult> add(DoctorQuestion question) async {
    try {
      final invalid = await _validate(question);
      if (invalid != null) return invalid;
      await _questionRepository.add(question);
    } catch (_) {
      return QuestionSaveResult.failed;
    }
    await _refresh();
    return QuestionSaveResult.success;
  }

  /// Saves changes to an existing question.
  ///
  /// If the question moves to another family member while still carrying
  /// its previous appointment link, that link is cleared: an appointment
  /// belongs to one member, so keeping it would link the question to the
  /// wrong person. A newly chosen appointment of the new member is kept.
  Future<QuestionSaveResult> update(DoctorQuestion question) async {
    try {
      final stored = await _questionRepository.getById(question.id);
      if (stored == null) return QuestionSaveResult.questionNotFound;

      var toSave = question;
      if (stored.memberId != question.memberId &&
          question.appointmentId != null &&
          question.appointmentId == stored.appointmentId) {
        toSave = question.copyWith(appointmentId: () => null);
      }

      final invalid = await _validate(toSave);
      if (invalid != null) return invalid;
      await _questionRepository.update(toSave);
    } catch (_) {
      return QuestionSaveResult.failed;
    }
    await _refresh();
    return QuestionSaveResult.success;
  }

  /// Marks a question as handled or not, keeping everything else (including
  /// the recorded answer) as it is.
  Future<QuestionSaveResult> setResolved(
    String questionId, {
    required bool resolved,
  }) async {
    try {
      final stored = await _questionRepository.getById(questionId);
      if (stored == null) return QuestionSaveResult.questionNotFound;
      if (stored.isResolved != resolved) {
        await _questionRepository.update(stored.copyWith(isResolved: resolved));
      }
    } catch (_) {
      return QuestionSaveResult.failed;
    }
    await _refresh();
    return QuestionSaveResult.success;
  }

  /// Deletes a question. Returns whether it is gone.
  ///
  /// Must only be called after the user explicitly confirmed the deletion in
  /// the UI; passing false for [userConfirmed] throws an [ArgumentError].
  /// Deleting is a single operation and safe to repeat.
  Future<bool> delete(String questionId, {required bool userConfirmed}) async {
    if (!userConfirmed) {
      throw ArgumentError.value(
        userConfirmed,
        'userConfirmed',
        'Deleting a question requires explicit user confirmation',
      );
    }
    try {
      await _questionRepository.delete(questionId);
    } catch (_) {
      return false;
    }
    await _refresh();
    return true;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _familyController.removeListener(_onFamilyChanged);
    _appointmentController.removeListener(_onAppointmentsChanged);
    super.dispose();
  }

  void _onFamilyChanged() {
    final revision = _familyController.relatedDataRevision;
    if (revision == _seenFamilyRevision) return;
    _seenFamilyRevision = revision;
    load();
  }

  void _onAppointmentsChanged() {
    final revision = _appointmentController.questionLinksRevision;
    if (revision == _seenQuestionLinksRevision) return;
    _seenQuestionLinksRevision = revision;
    load();
  }

  /// Checks against the repositories, not cached lists, so a member or
  /// appointment deleted a moment ago cannot slip through.
  Future<QuestionSaveResult?> _validate(DoctorQuestion question) async {
    if (question.text.trim().isEmpty) return QuestionSaveResult.textRequired;
    if (await _familyRepository.getById(question.memberId) == null) {
      return QuestionSaveResult.memberNotFound;
    }
    final appointmentId = question.appointmentId;
    if (appointmentId != null) {
      final appointment = await _appointmentRepository.getById(appointmentId);
      if (appointment == null) return QuestionSaveResult.appointmentNotFound;
      if (appointment.memberId != question.memberId) {
        return QuestionSaveResult.appointmentOfAnotherMember;
      }
    }
    return null;
  }

  List<DoctorQuestion> _where(bool Function(DoctorQuestion) test) =>
      List.unmodifiable(_questions.where(test));

  /// Re-reads the list after a change and notifies listeners.
  Future<void> _refresh() async {
    final generation = ++_loadGeneration;
    await _fetchQuestions(generation);
    if (generation != _loadGeneration) return;
    _isLoading = false;
    _notify();
  }

  Future<void> _fetchQuestions(int generation) async {
    try {
      final questions = await _questionRepository.getAll();
      if (generation != _loadGeneration) return;
      _questions = questions;
      _hasLoadError = false;
    } catch (_) {
      if (generation != _loadGeneration) return;
      _hasLoadError = true;
    }
  }

  /// Async work may finish after the controller was disposed; notifying
  /// then would throw.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }
}
