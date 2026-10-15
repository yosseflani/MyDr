/// Runs several repository operations as one unit.
///
/// Controllers use it for operations that span repositories, such as
/// deleting a family member with all their records.
abstract interface class TransactionRunner {
  /// Whether a failure inside [run] undoes everything [run] did. When
  /// false, a failure may leave the steps before it done.
  bool get isAtomic;

  /// Runs [action]; if it throws, the error is rethrown (after undoing its
  /// changes when [isAtomic]).
  Future<T> run<T>(Future<T> Function() action);
}

/// Runs the steps one after another, with no rollback. For storage that
/// cannot undo changes, such as the in-memory repositories.
class SequentialTransactionRunner implements TransactionRunner {
  const SequentialTransactionRunner();

  @override
  bool get isAtomic => false;

  @override
  Future<T> run<T>(Future<T> Function() action) => action();
}
