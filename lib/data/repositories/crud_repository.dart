/// Operations shared by every repository.
///
/// All methods are asynchronous, even in the in-memory implementations, so
/// a remote backend (e.g. Firebase) can be plugged in without changing
/// callers.
abstract interface class CrudRepository<T> {
  /// Returns a new unique id to use when creating an item.
  String createId();

  Future<T?> getById(String id);

  /// Throws [StateError] if an item with the same id already exists.
  Future<void> add(T item);

  /// Throws [StateError] if the item does not exist.
  Future<void> update(T item);

  /// Does nothing if the item does not exist.
  Future<void> delete(String id);
}
