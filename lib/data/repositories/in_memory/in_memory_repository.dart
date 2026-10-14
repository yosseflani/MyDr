import 'package:mydr/data/repositories/crud_repository.dart';

/// Shared in-memory storage for the mock repositories.
///
/// Data lives only for the lifetime of the app and is lost on restart.
abstract class InMemoryRepository<T> implements CrudRepository<T> {
  InMemoryRepository({
    required String idPrefix,
    required String Function(T item) idOf,
    Iterable<T> initialItems = const [],
  }) : _idPrefix = idPrefix,
       _idOf = idOf {
    for (final item in initialItems) {
      _items[_idOf(item)] = item;
    }
  }

  final String _idPrefix;
  final String Function(T item) _idOf;
  final Map<String, T> _items = {};
  int _nextId = 1;

  /// Current items, for subclasses that query or filter them.
  Iterable<T> get storedItems => _items.values;

  /// Removes every item matching [test]. For subclasses.
  void removeWhere(bool Function(T item) test) {
    _items.removeWhere((_, item) => test(item));
  }

  /// Replaces every item matching [test] with the result of [update].
  /// For subclasses.
  void replaceWhere(bool Function(T item) test, T Function(T item) update) {
    _items.updateAll((_, item) => test(item) ? update(item) : item);
  }

  @override
  String createId() {
    String id;
    do {
      id = '$_idPrefix-${_nextId++}';
    } while (_items.containsKey(id));
    return id;
  }

  @override
  Future<T?> getById(String id) async => _items[id];

  @override
  Future<void> add(T item) async {
    final id = _idOf(item);
    if (_items.containsKey(id)) {
      throw StateError('Item with id "$id" already exists');
    }
    _items[id] = item;
  }

  @override
  Future<void> update(T item) async {
    final id = _idOf(item);
    if (!_items.containsKey(id)) {
      throw StateError('Item with id "$id" does not exist');
    }
    _items[id] = item;
  }

  @override
  Future<void> delete(String id) async {
    _items.remove(id);
  }
}
