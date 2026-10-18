import 'package:mydr/data/cloud/account_service.dart';
import 'package:mydr/data/cloud/backup_storage.dart';

/// The connected cloud services.
class CloudServices {
  const CloudServices({required this.accounts, required this.storage});

  final AccountService accounts;
  final BackupStorage storage;
}

/// Connects to the cloud, the first time cloud backup is used (never at
/// start-up, so the app opens and works the same offline).
abstract interface class CloudBackend {
  /// May throw; calling again retries.
  Future<CloudServices> connect();
}
