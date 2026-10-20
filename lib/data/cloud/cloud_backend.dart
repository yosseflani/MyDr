import 'package:mydr/data/cloud/account_service.dart';
import 'package:mydr/data/cloud/backup_storage.dart';
import 'package:mydr/data/cloud/household_cloud.dart';

/// The connected cloud services.
class CloudServices {
  const CloudServices({
    required this.accounts,
    required this.storage,
    this.household,
  });

  final AccountService accounts;
  final BackupStorage storage;

  /// Household sharing; null where the backend does not offer it.
  final HouseholdCloud? household;
}

/// Connects to the cloud, the first time cloud backup is used (never at
/// start-up, so the app opens and works the same offline).
abstract interface class CloudBackend {
  /// May throw; calling again retries.
  Future<CloudServices> connect();
}
