import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:mydr/core/app_dependencies.dart';
import 'package:mydr/data/media/media_file_validator.dart';
import 'package:mydr/data/media/media_picker.dart';
import 'package:mydr/data/media/visit_media_file_store.dart';
import 'package:mydr/data/models/appointment.dart';
import 'package:mydr/data/models/visit_media.dart';
import 'package:mydr/data/repositories/appointment_repository.dart';
import 'package:mydr/data/repositories/visit_media_repository.dart';
import 'package:mydr/features/appointments/appointment_controller.dart';
import 'package:mydr/features/family/family_controller.dart';

/// What happened when adding photos or videos to an appointment.
class VisitMediaAddReport {
  const VisitMediaAddReport({
    this.addedIds = const [],
    this.pickError,
    this.appointmentMissing = false,
    this.rejected = const [],
  });

  /// The new items, in the order they were picked.
  final List<String> addedIds;

  /// Set when the camera or gallery could not be used; nothing was added.
  final MediaPickError? pickError;

  /// The appointment was deleted meanwhile; nothing was added.
  final bool appointmentMissing;

  /// One entry per picked file that was not saved, with the reason.
  final List<MediaFileError> rejected;

  /// The user closed the camera or gallery without choosing anything.
  bool get cancelled =>
      addedIds.isEmpty &&
      pickError == null &&
      !appointmentMissing &&
      rejected.isEmpty;

  int rejectedFor(MediaFileError error) =>
      rejected.where((e) => e == error).length;
}

/// Outcome of changing a description.
enum VisitMediaSaveResult { success, notFound, failed }

/// State and actions for the photos and videos prepared for doctor visits.
///
/// Like the other controllers, the list is re-read from the repository
/// after every change, and raw errors are never exposed or logged: they
/// could contain file paths or medical details.
///
/// Every item is shown only under its own appointment *and* that
/// appointment's family member ([forAppointment]); the database enforces
/// the same rule, so one member's documentation never appears under
/// another member.
///
/// Reloads when a family member is deleted
/// ([FamilyController.relatedDataRevision]) or an appointment is deleted
/// ([AppointmentController.visitMediaRevision]), since both remove media.
class VisitMediaController extends ChangeNotifier {
  VisitMediaController({
    required AppDependencies dependencies,
    required FamilyController familyController,
    required AppointmentController appointmentController,
    DateTime Function() clock = DateTime.now,
  }) : _repository = dependencies.visitMediaRepository,
       _appointmentRepository = dependencies.appointmentRepository,
       _files = dependencies.visitMediaFiles,
       _picker = dependencies.mediaPicker,
       _clock = clock,
       _familyController = familyController,
       _appointmentController = appointmentController,
       _seenFamilyRevision = familyController.relatedDataRevision,
       _seenAppointmentRevision = appointmentController.visitMediaRevision {
    _familyController.addListener(_onRelatedDataChanged);
    _appointmentController.addListener(_onRelatedDataChanged);
  }

  final VisitMediaRepository _repository;
  final AppointmentRepository _appointmentRepository;
  final VisitMediaFileStore _files;
  final MediaPicker _picker;
  final DateTime Function() _clock;
  final FamilyController _familyController;
  final AppointmentController _appointmentController;
  int _seenFamilyRevision;
  int _seenAppointmentRevision;

  List<VisitMedia> _items = const [];
  bool _isLoading = false;
  bool _hasLoadError = false;
  bool _isDisposed = false;
  final Set<String> _addingTo = {};
  int _loadGeneration = 0;

  /// The start-up clean-up of leftover files; adding waits for it, so it
  /// never removes a file that is being added.
  Future<void>? _cleanUp;

  bool get isLoading => _isLoading;
  bool get hasLoadError => _hasLoadError;

  /// Whether files are being added to [appointmentId] right now.
  bool isAdding(String appointmentId) => _addingTo.contains(appointmentId);

  /// The items of [appointment], oldest first. Only items of the
  /// appointment's own family member are returned.
  List<VisitMedia> forAppointment(Appointment appointment) => List.unmodifiable(
    _items.where(
      (m) =>
          m.appointmentId == appointment.id &&
          m.memberId == appointment.memberId,
    ),
  );

  VisitMedia? mediaById(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  /// Loads all records. With [cleanUpFiles] (once, at start-up), also
  /// deletes stored files that no record refers to any more, e.g. when
  /// deleting a file failed earlier.
  Future<void> load({bool cleanUpFiles = false}) async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _notify();

    final loaded = await _fetch(generation);
    if (cleanUpFiles && loaded != null) {
      _cleanUp = _files.deleteUnreferenced({
        for (final item in loaded) item.fileName,
      });
      await _cleanUp;
    }
    if (generation != _loadGeneration) return;
    _isLoading = false;
    _notify();
  }

  /// Opens the camera or gallery and saves what the user picked, attached
  /// to [appointment] and to its family member as currently stored.
  ///
  /// Each file is checked (type and size), copied into private storage and
  /// recorded; the picker's temporary copy is then removed. A file whose
  /// record cannot be saved is deleted again, so nothing is left half
  /// added.
  Future<VisitMediaAddReport> addFrom(
    Appointment appointment,
    MediaSource source,
  ) async {
    final List<PickedMedia> picked;
    try {
      picked = await _picker.pick(source);
    } on MediaPickException catch (e) {
      return VisitMediaAddReport(pickError: e.error);
    } catch (_) {
      return const VisitMediaAddReport(pickError: MediaPickError.failed);
    }
    if (picked.isEmpty) return const VisitMediaAddReport();

    _addingTo.add(appointment.id);
    _notify();
    try {
      await _cleanUp;
      // The stored appointment decides the member, not the screen's copy.
      final Appointment? stored;
      try {
        stored = await _appointmentRepository.getById(appointment.id);
      } catch (_) {
        return VisitMediaAddReport(
          rejected: [for (final _ in picked) MediaFileError.storageFailed],
        );
      }
      if (stored == null) {
        return const VisitMediaAddReport(appointmentMissing: true);
      }

      final added = <String>[];
      final rejected = <MediaFileError>[];
      for (final file in picked) {
        final error = await _addOne(stored, file, added);
        if (error != null) rejected.add(error);
      }
      await _refresh();
      return VisitMediaAddReport(addedIds: added, rejected: rejected);
    } finally {
      for (final file in picked) {
        await _picker.discard(file);
      }
      _addingTo.remove(appointment.id);
      _notify();
    }
  }

  /// Returns null on success, or why [file] was not saved.
  Future<MediaFileError?> _addOne(
    Appointment appointment,
    PickedMedia file,
    List<String> added,
  ) async {
    final StoredMediaFile storedFile;
    try {
      storedFile = await _files.import(file.path);
    } on MediaFileException catch (e) {
      return e.error;
    } catch (_) {
      return MediaFileError.storageFailed;
    }

    try {
      final media = VisitMedia(
        id: _repository.createId(),
        memberId: appointment.memberId,
        appointmentId: appointment.id,
        kind: storedFile.kind,
        fileName: storedFile.fileName,
        byteSize: storedFile.byteSize,
        createdAt: _clock(),
      );
      await _repository.add(media);
      added.add(media.id);
      return null;
    } catch (_) {
      await deleteVisitMediaFiles(_files, [storedFile.fileName]);
      return MediaFileError.storageFailed;
    }
  }

  /// Saves [description] (trimmed; empty clears it).
  Future<VisitMediaSaveResult> updateDescription(
    String mediaId,
    String? description,
  ) async {
    final trimmed = description?.trim() ?? '';
    try {
      final stored = await _repository.getById(mediaId);
      if (stored == null) {
        await _refresh();
        return VisitMediaSaveResult.notFound;
      }
      await _repository.update(
        stored.copyWith(description: () => trimmed.isEmpty ? null : trimmed),
      );
    } catch (_) {
      return VisitMediaSaveResult.failed;
    }
    await _refresh();
    return VisitMediaSaveResult.success;
  }

  /// Deletes an item: its record, then its file in private storage. The
  /// user's original in the gallery, if any, is never touched.
  ///
  /// Must only be called after the user explicitly confirmed; passing false
  /// for [userConfirmed] throws an [ArgumentError]. Returns whether the
  /// item is gone. A file that cannot be deleted right away is removed on
  /// a later start.
  Future<bool> delete(String mediaId, {required bool userConfirmed}) async {
    if (!userConfirmed) {
      throw ArgumentError.value(
        userConfirmed,
        'userConfirmed',
        'Deleting visit media requires explicit user confirmation',
      );
    }
    try {
      final stored = await _repository.getById(mediaId);
      if (stored != null) {
        await _repository.delete(mediaId);
        await deleteVisitMediaFiles(_files, [stored.fileName]);
      }
    } catch (_) {
      await _refresh();
      return false;
    }
    await _refresh();
    return true;
  }

  /// The photo's content, or null if its file is missing or unreadable.
  Future<Uint8List?> readPhoto(VisitMedia media) async {
    try {
      return await _files.readBytes(media.fileName);
    } catch (_) {
      return null;
    }
  }

  /// The video file for the player, or null if it is missing.
  Future<File?> videoFile(VisitMedia media) async {
    try {
      return await _files.localFile(media.fileName);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _familyController.removeListener(_onRelatedDataChanged);
    _appointmentController.removeListener(_onRelatedDataChanged);
    super.dispose();
  }

  void _onRelatedDataChanged() {
    final family = _familyController.relatedDataRevision;
    final appointments = _appointmentController.visitMediaRevision;
    if (family == _seenFamilyRevision &&
        appointments == _seenAppointmentRevision) {
      return;
    }
    _seenFamilyRevision = family;
    _seenAppointmentRevision = appointments;
    load();
  }

  Future<void> _refresh() async {
    final generation = ++_loadGeneration;
    await _fetch(generation);
    if (generation != _loadGeneration) return;
    _isLoading = false;
    _notify();
  }

  /// Returns the loaded items, or null if reading failed.
  Future<List<VisitMedia>?> _fetch(int generation) async {
    try {
      final items = await _repository.getAll();
      if (generation == _loadGeneration) {
        _items = items;
        _hasLoadError = false;
      }
      return items;
    } catch (_) {
      if (generation == _loadGeneration) _hasLoadError = true;
      return null;
    }
  }

  void _notify() {
    if (!_isDisposed) notifyListeners();
  }
}
