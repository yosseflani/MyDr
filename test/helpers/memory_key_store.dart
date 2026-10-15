import 'package:mydr/data/local/database_key_store.dart';

/// Keeps the database key in memory, with switches to make it fail.
class MemoryDatabaseKeyStore implements DatabaseKeyStore {
  MemoryDatabaseKeyStore([this.key]);

  String? key;
  bool failRead = false;
  bool failWrite = false;
  int writes = 0;

  @override
  Future<String?> read() async {
    if (failRead) throw StateError('secure storage unavailable');
    return key;
  }

  @override
  Future<void> write(String key) async {
    if (failWrite) throw StateError('secure storage unavailable');
    writes++;
    this.key = key;
  }
}
