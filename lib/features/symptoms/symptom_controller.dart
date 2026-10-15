import 'package:flutter/foundation.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/models/symptom_entry.dart';
import 'package:mydr/data/repositories/family_repository.dart';
import 'package:mydr/data/repositories/symptom_repository.dart';
import 'package:mydr/features/family/family_controller.dart';

/// Outcome of adding or updating a symptom record.
enum SymptomSaveResult {
  success,

  /// The symptom name is empty.
  nameRequired,

  /// The family member does not exist (any more).
  memberNotFound,

  /// The record's date and time is later than now.
  dateInFuture,

  /// The record's date is more than [SymptomController.maxHistoryYears]
  /// years ago.
  dateTooOld,

  /// The record being updated does not exist (any more).
  entryNotFound,

  /// Nothing was changed.
  failed,
}

/// All records of one symptom of one family member, for following how it
/// changed over time. Records with the same name (ignoring case and extra
/// spaces) belong to the same group.
class SymptomGroup {
  SymptomGroup({required this.memberId, required List<SymptomEntry> entries})
    : assert(entries.isNotEmpty),
      entries = List.unmodifiable(entries);

  final String memberId;

  /// Oldest first.
  final List<SymptomEntry> entries;

  SymptomEntry get latest => entries.last;

  /// The name as written in the latest record, with tidy spacing.
  String get name => SymptomController.tidyName(latest.name);
}

/// State and actions for the symptom journal.
///
/// A journal only: it stores what the user reports and never interprets it.
///
/// Like the other controllers, the list is always re-read from the
/// repository after a change, and raw errors are never exposed. Deleting a
/// family member deletes their records, so the list is reloaded whenever
/// [FamilyController.relatedDataRevision] changes, and only then.
class SymptomController extends ChangeNotifier {
  SymptomController({
    required AppDependencies dependencies,
    required FamilyController familyController,
    DateTime Function() clock = DateTime.now,
  }) : _symptomRepository = dependencies.symptomRepository,
       _familyRepository = dependencies.familyRepository,
       _familyController = familyController,
       _clock = clock,
       _seenFamilyRevision = familyController.relatedDataRevision {
    _familyController.addListener(_onFamilyChanged);
  }

  /// Records can go back at most this many years.
  static const int maxHistoryYears = 5;

  final SymptomRepository _symptomRepository;
  final FamilyRepository _familyRepository;
  final FamilyController _familyController;
  final DateTime Function() _clock;
  int _seenFamilyRevision;

  List<SymptomEntry> _entries = const [];
  bool _isLoading = false;
  bool _hasLoadError = false;
  bool _isDisposed = false;

  /// Increases with every load, so only the latest one applies its result.
  int _loadGeneration = 0;

  /// All records, newest first.
  List<SymptomEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;

  /// The oldest date a record may have, relative to now.
  DateTime get earliestAllowedDate {
    final now = _clock();
    return DateTime(now.year - maxHistoryYears, now.month, now.day);
  }

  SymptomEntry? entryById(String id) {
    for (final entry in _entries) {
      if (entry.id == id) return entry;
    }
    return null;
  }

  /// Records newest first, optionally only for [memberId].
  List<SymptomEntry> history({String? memberId}) => List.unmodifiable(
    _entries.where((e) => memberId == null || e.memberId == memberId),
  );

  /// Records grouped by family member and symptom name, each group oldest
  /// first, groups ordered by their latest record (most recent first).
  List<SymptomGroup> groups({String? memberId}) {
    final byKey = <String, List<SymptomEntry>>{};
    for (final entry in history(memberId: memberId).reversed) {
      final key = '${entry.memberId}\u0000${normalizeName(entry.name)}';
      (byKey[key] ??= []).add(entry);
    }
    final groups = [
      for (final entries in byKey.values)
        SymptomGroup(memberId: entries.first.memberId, entries: entries),
    ]..sort((a, b) => _newestFirst(a.latest, b.latest));
    return List.unmodifiable(groups);
  }

  /// The group of [memberId]'s records named like [name], or null if there
  /// are none.
  SymptomGroup? groupFor(String memberId, String name) {
    final key = normalizeName(name);
    for (final group in groups(memberId: memberId)) {
      if (normalizeName(group.name) == key) return group;
    }
    return null;
  }

  /// Symptom names to suggest when recording: [memberId]'s own names first,
  /// most recently used first, then names used for the rest of the family.
  /// Each name appears once, as most recently written.
  List<String> nameSuggestions({String? memberId}) {
    final seen = <String>{};
    final names = <String>[];
    void addFrom(Iterable<SymptomEntry> entries) {
      for (final entry in entries) {
        if (seen.add(normalizeName(entry.name))) {
          names.add(tidyName(entry.name));
        }
      }
    }

    if (memberId != null) addFrom(history(memberId: memberId));
    addFrom(_entries);
    return List.unmodifiable(names);
  }

  /// [name] trimmed and with single spaces, as it is stored and shown.
  static String tidyName(String name) =>
      name.trim().replaceAll(RegExp(r'\s+'), ' ');

  /// The form in which names are compared: [tidyName], in lower case (for
  /// names written in Latin letters).
  static String normalizeName(String name) => SymptomEntry.nameKey(name);

  String createId() => _symptomRepository.createId();

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _notify();

    await _fetchEntries(generation);
    if (generation != _loadGeneration) return;

    _isLoading = false;
    _notify();
  }

  /// Adds a record. The name and notes are stored trimmed.
  Future<SymptomSaveResult> add(SymptomEntry entry) async {
    try {
      final toSave = _cleaned(entry);
      final invalid = await _validate(toSave, previousDate: null);
      if (invalid != null) return invalid;
      await _symptomRepository.add(toSave);
    } catch (_) {
      return SymptomSaveResult.failed;
    }
    await _refresh();
    return SymptomSaveResult.success;
  }

  /// Saves the details the user can edit. Everything else stored with the
  /// record (its status and duration) is kept as it is, so editing never
  /// loses data the form does not show.
  ///
  /// A date older than [maxHistoryYears] is still accepted if it is the
  /// record's existing date.
  Future<SymptomSaveResult> update(
    String id, {
    required String memberId,
    required String name,
    required DateTime startedAt,
    required int severity,
    required String? notes,
  }) async {
    try {
      final stored = await _symptomRepository.getById(id);
      if (stored == null) return SymptomSaveResult.entryNotFound;

      final toSave = _cleaned(
        stored.copyWith(
          memberId: memberId,
          name: name,
          startedAt: startedAt,
          severity: severity,
          notes: () => notes,
        ),
      );
      final invalid = await _validate(toSave, previousDate: stored.startedAt);
      if (invalid != null) return invalid;
      await _symptomRepository.update(toSave);
    } catch (_) {
      return SymptomSaveResult.failed;
    }
    await _refresh();
    return SymptomSaveResult.success;
  }

  /// Deletes a record. Returns whether it is gone.
  ///
  /// Must only be called after the user explicitly confirmed the deletion in
  /// the UI; passing false for [userConfirmed] throws an [ArgumentError].
  /// Deleting is a single operation and safe to repeat.
  Future<bool> delete(String id, {required bool userConfirmed}) async {
    if (!userConfirmed) {
      throw ArgumentError.value(
        userConfirmed,
        'userConfirmed',
        'Deleting a symptom record requires explicit user confirmation',
      );
    }
    try {
      await _symptomRepository.delete(id);
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
    super.dispose();
  }

  void _onFamilyChanged() {
    final revision = _familyController.relatedDataRevision;
    if (revision == _seenFamilyRevision) return;
    _seenFamilyRevision = revision;
    load();
  }

  SymptomEntry _cleaned(SymptomEntry entry) {
    final notes = entry.notes?.trim() ?? '';
    return entry.copyWith(
      name: tidyName(entry.name),
      notes: () => notes.isEmpty ? null : notes,
    );
  }

  /// Checks against the repository, not the cached family list, so a
  /// member deleted a moment ago cannot slip through. The severity range is
  /// already enforced by [SymptomEntry] itself.
  Future<SymptomSaveResult?> _validate(
    SymptomEntry entry, {
    required DateTime? previousDate,
  }) async {
    if (entry.name.isEmpty) return SymptomSaveResult.nameRequired;
    if (entry.startedAt.isAfter(_clock())) {
      return SymptomSaveResult.dateInFuture;
    }
    if (entry.startedAt.isBefore(earliestAllowedDate) &&
        entry.startedAt != previousDate) {
      return SymptomSaveResult.dateTooOld;
    }
    if (await _familyRepository.getById(entry.memberId) == null) {
      return SymptomSaveResult.memberNotFound;
    }
    return null;
  }

  /// Newest first; records at the same moment are ordered by id, so the
  /// order is always the same.
  static int _newestFirst(SymptomEntry a, SymptomEntry b) {
    final byDate = b.startedAt.compareTo(a.startedAt);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }

  /// Re-reads the list after a change and notifies listeners.
  Future<void> _refresh() async {
    final generation = ++_loadGeneration;
    await _fetchEntries(generation);
    if (generation != _loadGeneration) return;
    _isLoading = false;
    _notify();
  }

  Future<void> _fetchEntries(int generation) async {
    try {
      final entries = await _symptomRepository.getAll();
      if (generation != _loadGeneration) return;
      _entries = List.unmodifiable(
        <SymptomEntry>[...entries]..sort(_newestFirst),
      );
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
