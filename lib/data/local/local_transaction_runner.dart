import 'package:mydr/data/local/local_database.dart';
import 'package:mydr/data/repositories/transaction_runner.dart';

/// Runs repository operations in one database transaction: if any of them
/// fails, none of their changes are kept.
///
/// Repositories need no extra wiring: drift runs every query made on the
/// same database inside [run] as part of the transaction.
class LocalTransactionRunner implements TransactionRunner {
  const LocalTransactionRunner(this._db);

  final LocalDatabase _db;

  @override
  bool get isAtomic => true;

  @override
  Future<T> run<T>(Future<T> Function() action) => _db.transaction(action);
}
