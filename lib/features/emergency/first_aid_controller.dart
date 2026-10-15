import 'package:flutter/foundation.dart';
import 'package:mydr/data/first_aid/first_aid_content_parser.dart';
import 'package:mydr/data/models/first_aid_content.dart';
import 'package:mydr/data/repositories/first_aid_repository.dart';

/// State of the first-aid library.
///
/// Independent of emergency calling: the dial buttons never wait for or
/// depend on this content, so a failure here can never block a call.
class FirstAidController extends ChangeNotifier {
  FirstAidController(this._repository);

  final FirstAidRepository _repository;

  FirstAidContentPack? _pack;
  bool _isLoading = false;
  FirstAidContentError? _loadError;
  bool _isDisposed = false;

  /// Increases with every load, so only the latest one applies its result.
  int _loadGeneration = 0;

  /// The loaded content, or null if none was loaded yet.
  FirstAidContentPack? get pack => _pack;

  /// In the order of the content file; empty until loaded.
  List<FirstAidTopic> get topics => _pack?.topics ?? const [];
  bool get isLoading => _isLoading;

  /// Why the latest load failed, or null if it succeeded. A failed reload
  /// keeps the content loaded before.
  FirstAidContentError? get loadError => _loadError;
  bool get hasLoadError => _loadError != null;

  FirstAidTopic? topicById(String id) => _pack?.topicById(id);

  Future<void> load() async {
    final generation = ++_loadGeneration;
    _isLoading = true;
    _notify();

    FirstAidContentPack? pack;
    FirstAidContentError? error;
    try {
      pack = await _repository.load();
    } on FirstAidContentException catch (e) {
      error = e.error;
    } catch (_) {
      error = FirstAidContentError.unavailable;
    }
    if (generation != _loadGeneration) return;

    if (pack != null) _pack = pack;
    _loadError = error;
    _isLoading = false;
    _notify();
  }

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  /// Async work may finish after the controller was disposed; notifying
  /// then would throw.
  void _notify() {
    if (!_isDisposed) notifyListeners();
  }
}
