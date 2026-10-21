# lib/data

Rules for code in this directory. They add to the root `CLAUDE.md` and `.claude/rules/`, and do not repeat them.

## Dependencies

- Drift and `sqlite3` are imported only in `local/`; Firebase only in `cloud/firebase_cloud_backend.dart`; `flutter_secure_storage` only in `local/database_key_store.dart` and `cloud/recovery_key_store.dart`.
- Nothing here imports `package:mydr/features/`, `core/l10n/`, or Flutter's material or widgets libraries.

## Local repositories

- Every database call goes through `guard`, `insertNew` or `expectUpdated` (`local/repositories/local_repository_support.dart`). No Drift or SQLite exception leaves `local/`.
- "Already exists" and "does not exist" throw `StateError`, as `CrudRepository` specifies; everything else becomes `LocalDataException`.
- A new exception type holds only an enum, and its `toString()` is `Name(error.name)`.

## Stored formats

- Database values for dates, times, instants and lists are converted only in `local/storage_codecs.dart` (`StorageCodecs`). The format checks in `local/schema.drift` must match them.
- Every new format gets a round-trip test in `test/data/local/storage_codecs_test.dart`.

## A new record type: also update, beyond the root schema checklist

- `BackupSnapshot`: encoding, decoding and `validate()`, which must reject what the schema rejects (member isolation, uniqueness). Also `BackupCounts`.
- Both orders in `RepositoryBackupDataStore.replaceAll` (`backup/backup_data_store.dart`): children deleted first, parents added first.
- `MemberDeletionStep` in `lib/features/family/family_controller.dart`.

## Tests

- A new repository gets shared contract tests in `test/data/repositories/repository_contract_test.dart` where applicable, run against both the Drift and the in-memory implementation.
- Behavior that needs more specific coverage gets dedicated tests, the way `test/data/local/medication_storage_test.dart` does: one group over both implementations, a `local database guarantees` group for database-only constraints, and an upgrade test from a real encrypted file of the previous schema version.
- Medications, dose records and visit media currently have only dedicated tests.
- Test data is fictional.

## Backup

- Uploaded objects are only `BackupCipher` output; upload metadata holds only `createdAt`, `totalBytes` and `formatVersion`. The manifest is uploaded last, and older backups are deleted only after it.
- Restore is two steps: `prepareRestore` downloads, decrypts and validates into a staging folder; `applyRestore` replaces the data in one transaction, only after the user confirms. Covered in `test/data/backup/backup_service_test.dart`.
